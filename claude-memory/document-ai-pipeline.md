---
name: document-ai-pipeline
description: "Dashboard's own Gemini document-AI pipeline (bulk upload → draft pending transactions), Laravel-native, separate from mobile"
metadata: 
  node_type: memory
  type: project
  originSessionId: eaa51cfc-6d53-487f-b1cb-02b3d152a689
---

Built 2026-06-16 (Phase 1), shipped as **checkpoint-042** (`213d754`, DEPLOYED via
git pull). The Document Hub **Batch Upload** modal has an
"Extract transactions with AI" toggle (**default ON**) + Instant/Economy picker.
With it on, each uploaded file → Gemini → a **draft `pending`, `source=ai`
transaction** for review in Record Keeping. Fully documented in
[docs/document-ai-extraction.md].

- **Dashboard-only & Laravel-native** — reuses the mobile app's Gemini *models*
  (`gemini-flash-lite-latest` for file OCR/voice, `gemini-2.5-flash` for the
  extraction) but is a SEPARATE pipeline writing to the dashboard Postgres; it
  does NOT touch the mobile n8n workflow or MySQL.
- **Pieces:** `app/Services/Gemini/{GeminiClient,DocumentAiExtractor,
  TransactionDraftValidator,DocumentAiIngestService}.php` +
  `app/Jobs/ExtractDocumentTransactionsJob.php`; `DocumentsController@upload`
  reads `ai_extract`/`mode` and dispatches per file; UI in
  `resources/js/Pages/Documents/Index.jsx` BatchUploadModal.
- **Config:** `config/services.php` → `gemini`; key in `.env` `GEMINI_API_KEY`
  ONLY (gitignored — see [[autocommit-leaks-secrets]]). The working key is an
  unusual `AQ.Ab8…` format (NOT `AIza…`) but works with the standard
  `x-goog-api-key` header (`auth_scheme=key`). Switchable to bearer via
  `GEMINI_AUTH_SCHEME`.
- **Verified e2e** locally: Walmart/Tim-Hortons text receipts → correct pending
  AI transactions (amount/type/category/GIFI/date/vendor/confidence), attachment
  auto-linked. Async via `QUEUE_CONNECTION=database` worker.
- **Review** = existing ledger: drafts are pending + carry the 🤖 Source badge
  ([[checkpoint-rule]] checkpoint-039); filter Status=Pending + Source=AI.

**PHASE-2 FOLLOW-UPS (not done):** (1) Economy mode currently just DEFERS ~1 min
on the default queue — real 50%-cheaper Gemini *batch-API* pricing is unbuilt.
(2) Scanner (`/documents/scan-upload`) + Google Drive (`/google-drive/import`)
sources aren't AI-wired (separate endpoints, both not-yet-operational); only
device/paste/drag-drop carry the flag.

**Prod owes:** add `GEMINI_API_KEY` to prod `.env` + `config:clear`, `npm run
build`, and a running queue worker (already runs for PollMobileChangesJob).
Related: [[feature-test-handoff]], [[upload-ghost-row-bug]].
