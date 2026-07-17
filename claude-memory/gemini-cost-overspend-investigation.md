---
name: gemini-cost-overspend-investigation
description: "Root causes found for a real $450+ Gemini bill vs a ~$0.50 bottom-up model, across mobile app and va-dashboard; two live unfixed bugs identified"
metadata: 
  node_type: memory
  type: project
  originSessionId: ddb5a215-0cd2-4984-a74a-eb2e2d766ce8
---

Investigated 2026-07-09 after the user reported the actual Gemini bill hit $450+ while a
bottom-up model (100 combined text+voice+image messages, correct call-shapes/models)
predicted only ~$0.50 total across mobile + dashboard. Found concrete, code-confirmed
root causes on both sides — not just "volume was higher than assumed."

## Mobile app (va-mobile) — HIGH SEVERITY, STILL LIVE

**`n8n/chat-with-file.json` still has `FREE_LIMIT = 3000`.** This endpoint handles every
voice/image/file attachment message (`config/features.ts` `combinedChatWithFile` routes
all attachment types through it) — the most expensive message type (~2x a text message).
Its sibling `n8n/ai-chat.json` had the same 30→3000 closed-test bump correctly reverted
back to 30 in commit `126f9431` (2026-06-10, "Android live on Play production, bump no
longer needed"), but `chat-with-file.json` was never touched — confirmed via
`git log -p -S"FREE_LIMIT =" -- n8n/chat-with-file.json` (only one hit, the original
2026-05-24 creation). No doc's revert checklist (`docs/PRE_PRODUCTION_CLEANUP.md`) even
lists this file. Client-side gating (`SubscriptionContext.tsx`, `FREE_MESSAGE_LIMIT: 30`)
should normally catch this, but any drift (stale client state, multi-device desync, direct
API calls) hits a 3000-ceiling instead of 30 on exactly the priciest call path. Live since
2026-05-24, spanning the real closed-test window (2026-06-22 → 2026-07-06) and still true
on disk today.

**Fix:** set `n8n/chat-with-file.json`'s `FREE_LIMIT` to 30 and re-import the workflow to
the live n8n instance.

**Also found:** the team's own cost dashboard (`n8n/admin-dashboard.json`,
`/admin/overview` + `/admin/ai-usage`) is structurally blind to file-analysis Gemini calls
— `Gemini2`/`Gemini4` (the `gemini-flash-lite-latest` OCR/transcribe calls made on every
voice note and image) never write to `messages.token_usage_input/output`; only the
chat-agent response does. So every attachment message's real cost has been invisible to
the team's own monitoring the whole time. `MODEL_PRICES_USD_PER_1M` also has no row for
`gemini-flash-lite-latest`. This is why nobody caught the overspend via the dashboard.

**Ruled out:** the earlier-known "attachment fan-out ~100x" bug (fixed 2026-06-15,
`LimitAttachmentToOne` node) — confirmed present in `ai-chat.json` and structurally
unneeded in `chat-with-file.json` (different graph collapses fan-out before it matters).
Model is still `gemini-2.5-flash`/`gemini-flash-lite-latest`, not bumped to Pro. A separate
`n8n/telegram.json` workflow does call Gemini but is a distinct surface (Telegram bot, not
the app) — check if it's actually live/imported on prod n8n before ruling it fully out.

## VA-Dashboard — two compounding, undocumented bugs

1. **Queue duplication via misconfigured `retry_after`.** `config/queue.php` Redis
   `retry_after` defaults to 90s; production Supervisor runs `queue:work --timeout=300`
   with `numprocs=2` (`docs/DEPLOYMENT.md`). The deploy doc itself warns `retry_after` must
   exceed the worker timeout or "a slow job is retried while still running" — never
   enforced (`REDIS_QUEUE_RETRY_AFTER` unset anywhere). A Document AI extraction job
   running past 90s (easy — Gemini call timeout alone is 120s, multi-page PDFs loop
   sequentially) has its Redis reservation expire and gets **picked up and re-run by a
   second worker while the first is still executing**, re-billing every already-made
   Gemini call. Not protected by job-level `$tries`.
   **Fix:** set `REDIS_QUEUE_RETRY_AFTER` above 300 (e.g. 310+) in prod `.env`.
2. **Uncapped multi-page PDF fan-out.** Document AI Instant mode bills 2 Gemini calls per
   *page*, not per file (team's own doc already says so,
   `docs/document-ai-extraction.md:129`). No aggregate cap across a batch: 25 files × 60
   pages × 2 calls = up to 3,000 Gemini calls from a single upload POST. AI extraction
   defaults ON, in the expensive synchronous "Instant" mode by default.
   **Fix:** add an aggregate page/call cap per batch upload, or default multi-page PDFs to
   Economy (Batch API) mode.

Side note: a separate, actively-used Anthropic/Claude integration exists
(`AiAccountClassifier`, `AiTransactionCategorizer`, `VendorExtractionService`,
`VoiceIntelligenceService`, model `claude-sonnet-4-20250514`) — worth confirming whether
the reported "$450" figure is a pure Gemini invoice or a blended AI bill across both
vendors before attributing it entirely to the causes above.

**Ruled out:** conversation-history growth (properly capped at 20 messages everywhere,
including client-portal path), wrong/expensive Gemini model, and no prior incident doc
exists for this — it was genuinely undiagnosed before this investigation.

## How to apply
Read this before touching n8n `chat-with-file.json`, Document AI batch upload code, or
dashboard queue config. Don't re-derive the root cause from scratch — these are confirmed
via git log + code reads, not speculation. See also [[document-ai-pipeline]] and
[[books-phase3-production-deploy]] for related Document AI context.
