---
name: ai-cost-optimization
description: "Gemini document-AI cost cuts (2026-07-07) — local image downscale + digital-PDF text layer + prompt caching reorder + usage logging, all config-gated & fail-safe; OCR hybrid built but OFF by default with a strict confidence gate. READ before touching DocumentAiExtractor / Gemini cost."
metadata: 
  node_type: memory
  type: project
  originSessionId: 270b0c6e-d741-4c9b-b9a4-10811cb7e70e
---

Shipped 2026-07-07 to cut Gemini spend (even in testing) with **zero quality loss** — all changes fail-safe (missing binary/unsuitable input → falls back to the current multimodal path). Model policy unchanged (see [[gemini-model-policy]]). Full doc: `va-dashboard2/docs/AI-COST-OPTIMIZATION.md`.

**All funneled through `DocumentAiExtractor::extract()`** (the shared path for every intake — instant, split, batch, retry):
- `ImageOptimizer` (GD) downscales photos to ~1600px JPEG before upload — verified 87% fewer bytes on a 3000×4000 test. `uploadBytesFor()`.
- `PdfTextExtractor` (pdftotext) reads a DIGITAL pdf's text layer → text path, skips page-image tokens; scanned PDF → 0 chars → null → multimodal. Verified both ways.
- Prompt reordered so the big static rules are a byte-identical PREFIX and per-call owner/counterparty/date go LAST → enables Gemini implicit caching. Verified order.
- `GeminiClient::logUsage()` logs usageMetadata (`grep 'gemini usage'`) — the measurement to prove the rest.
- New config: `services.gemini.{log_usage,two_step_fallback}` + whole `services.documents.*` block (image_*, pdf_*, ocr.*). Prod needs `config:clear`.

**Key-pool tiers + rotation + failover + alerts (`GeminiKeyPool` + `GeminiAdminNotifier`, wired into `GeminiClient::generate()`):** flip whole app free⇄paid via `GEMINI_TIER=free|paid`+`config:clear` OR the runtime command **`php artisan gemini:tier`** (toggle / `free` / `paid` / `--status` / `--reset`; override persisted in cache CACHE_STORE=database → survives requests+redeploys, only cache:clear reverts; works local+prod; VERIFIED cross-process). `GEMINI_FREE_KEYS`=2-3 comma keys (each a SEPARATE AI Studio project or they share quota), `GEMINI_API_KEYS`=paid pool (→ falls back to single GEMINI_API_KEY). candidates() = free keys then paid as escalation, healthy-first. On 429 the key is penalised `GEMINI_KEY_COOLDOWN`s (60) + retries next; **when ALL free keys 429 → auto-escalates to paid AND emails admin** (`FREE_EXHAUSTED`); **paid key rejected for billing/permission (403 / PERMISSION_DENIED / billing body) → emails admin + stops** (`PAID_BILLING`). Alerts → `GEMINI_ADMIN_EMAIL` (fallback MAIL_FROM_ADDRESS), Log::critical always, email throttled `GEMINI_NOTIFY_COOLDOWN`s (1800). `max_rpm` auto-drops to `GEMINI_FREE_MAX_RPM` (10) on free (env-based, not the runtime toggle). Single-key/explicit-key = unchanged. Verified w/ stubs + live command.

**Digital-PDF rasterization FIX (#9):** browser (`pdfHasTextLayer()` in lib/pdfPageRender.js + BatchUploadModal) AND server (`DocumentAiIngestService::ingest()` gate) now skip page-image rendering when a PDF has a real text layer → raw PDF goes down the cheap pdftotext text path instead of paying image tokens. Scans still rasterize. Extends the PDF-text win to the PRIMARY batch-upload path (was raw-upload only). Frontend built.

⚠️ **Implicit caching (#4) CONFIRMED won't fire on flash-lite yet** (web-checked 2026-07-07): Google min is 2048 tokens for 2.5 flash/pro, flash-lite undocumented + community says ~3000+ and often cached=0. Our static prefix ~800-1100 tokens = below threshold. The reorder is a correct free precondition but expect `cached=0` until we grow the prefix or use explicit `cachedContents`. Watch the `gemini usage` log.

⚠️ **OCR hybrid (`TesseractOcr`) is OFF by default (`DOC_OCR_ENABLED=false`).** It's the one that can DEGRADE extraction if misused. It only fires when tesseract mean-confidence ≥ 80 AND text ≥ 24 chars AND has a digit AND the extract call succeeds — else multimodal. **Never enable in prod until A/B-tested field-by-field against multimodal on real receipts.** tesseract is NOT installed on the dev box.

**Economy/Batch API (50% off) already exists** and is wired: `mode=economy` → `DocumentAiDispatcher::submitBatch` → `SubmitDocumentBatchJob` → `PollDocumentAiBatchesJob` (schedule every 5 min) → `ingestBatchResult`; UI toggle in `BatchUploadModal`. Just USE it for big/test batches.

**Added 2026-07-07 (my round, in the SAME checkpoint-123 bundle):**
- VOICE thinking cap: `services.gemini.thinking_budget_voice` (default 1024) passed to VoiceCommandInterpreter::interpretTranscript + AiAssistantService voice-tx. Extraction stays 0 (already was). Rationale: voice reasons over an ambiguous spoken instruction; cap = benefit-on-hard-cases without unbounded dynamic-thinking bill. It's a CEILING not a floor.
- CHECKSUM DEDUP: `attachments.ai_extract_raw` (json) caches the raw extraction; a re-uploaded identical file (same sha256 + same client) replays it and SKIPS Gemini entirely. `DocumentAiIngestService::tryReuseByChecksum()` at the top of ingest()+ingestPages(); whole-file path only. Gated by `services.gemini.dedup_by_checksum` (default true). Verified e2e (deadend base_url proved zero network on reuse).
- Economy default threshold 30 → 5 (ECONOMY_SUGGEST_AT in BatchUploadModal, `>=`).

**Status: DEPLOYED — checkpoint-123 (6fab983) pushed + prod webhook (pull+build OK) 2026-07-07.** Bundled with the teammate cost work above + upload-batch traceability + docx fix (see [[batch-upload-ai-tester-fixes]], docs/upload-batch-traceability-and-docx.md). The Resend→SES email migration was surgically kept OUT (config/services.php stripped of SES hunks; ~19 SES files remain uncommitted in the working tree). **PROD OWES: `php artisan migrate --force`** (upload_batch_id on attachments+transactions, ai_extract_raw on attachments) **+ `queue:restart`** (job/extractor code changed) **+ `config:clear`** (new services.documents.* + gemini keys). Key pool defaults to paid → prod behaviour unchanged until GEMINI_TIER=free is set.

NEXT (not done): confirm flash-lite implicit-cache eligibility (prefix may be under the min → may need explicit cachedContents); free-tier GEMINI_API_KEY for dev (never commit — repo auto-pushes, see [[autocommit-leaks-secrets]]). Related: [[batch-upload-ai-tester-fixes]], [[document-ai-pipeline]].
