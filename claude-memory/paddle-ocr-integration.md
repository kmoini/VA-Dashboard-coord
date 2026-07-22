---
name: paddle-ocr-integration
description: PaddleOCR text-first extraction (cost saver) built & gated OFF; OCR images/scanned PDFs to text FIRST then cheap Gemini text path
metadata: 
  node_type: memory
  type: project
  originSessionId: 63f90849-d724-4290-8f50-067a17f8a99c
  modified: 2026-07-21T02:59:44.202Z
---

PaddleOCR integration on the dashboard (`va-dashboard2`) to cut Gemini cost:
OCR an image / scanned PDF to text FIRST, then feed the CHEAP `document.extract.text`
Gemini path instead of the expensive multimodal image call. The image never reaches
Gemini. Stacks with the repetition-loop cap ([[gemini-repetition-loop-cost]]) and
[[ai-cost-optimization]].

**Built, gated OFF (`OCR_ENABLED=false`). ✅ cp-153 DEPLOYED to prod 2026-07-21 (inert until OCR_TOKEN+OCR_ENABLED set).**

- Service contract: `ocr.voiceaccountant.com` `/openapi.yaml` — async submit `POST /api/ocr`
  (multipart file + `key`,`model`,`enhance`) → poll `GET /api/ocr/{process_id}`. 200=cached,
  202=process_id, 429 no_seat+Retry-After (≤3 seats), done→result, failed/404/timeout.
  Idempotency `key = sha256(bytes)` → job retries don't pay twice. Text = `result.markdown`
  else `result.layout_text` (cleaner for receipts).
- `App\Services\Documents\PaddleOcrClient::read()` is FAIL-SAFE: never throws, returns null on
  anything not a clean success → caller falls back to multimodal. OCR can only save money, never break a file.
- Wired as FAST PATH C in `DocumentAiExtractor` (image+pdf) before the multimodal PRIMARY;
  null result falls through. `extractFromText()` returns `['rows','doc_category','doc_category_confidence']`.
- Config `services.ocr` (all env-overridable); `.env.example` block added. **OCR_TOKEN is a SECRET, .env only**
  (repo auto-pushes — [[autocommit-leaks-secrets]]).
- Tests: `tests/Unit/Services/PaddleOcrClientTest.php` — 11 passing (fakes full contract; one $sc-driven
  fake closure because `Http::fake()` accumulates callbacks, first match wins).
- Docs: `docs/PADDLE-OCR-INTEGRATION.md`.

**Owed:** live smoke test (scratchpad `ocr_smoke.php` reads OCR_TOKEN from shell env, never committed) →
then prod `.env`: OCR_TOKEN + OCR_URL + `OCR_ENABLED=true` + `config:clear`. READ before touching
OCR / DocumentAiExtractor fast paths / extraction cost.
