---
name: batch-upload-ai-tester-fixes
description: "2026-07-02 tester-feedback round on Batch Upload + Document AI — chunked uploads (no 25-file UI cap), per-file ai_extract_status + retry + ledger auto-refresh, client-context direction fix (direction_uncertain chip), Kind/Counterparty columns, thinkingBudget=0 + single-call extraction. BUILT on main working tree, NOT committed — awaiting Amin's test."
metadata: 
  node_type: memory
  type: project
  originSessionId: 450de5d9-ae01-4f79-89e6-572e5d8cbbf6
---

Tester feedback round (2026-07-02) on the dashboard's Batch Upload + AI extraction,
all six items implemented in one pass in `va-dashboard2` (working tree on `main`,
mixed with the uncommitted SES work — NOT committed, per [[wait-for-user-test-before-deploy]]).

What was built (full detail in repo `docs/batch-upload-ai-improvements.md`):
- **Chunked upload** in BatchUploadModal for device/paste + Google Drive + Scanner:
  any file count, sliced into 25-file POSTs, per-file rejects, progress bar.
  Upload routes throttle raised 10→30/min to fit chunking.
- **Per-file AI status**: `attachments.ai_extract_status/error/tx_count/updated_at`
  (migration 2026_07_02_000001) written by ExtractDocumentTransactionsJob +
  Submit/PollDocumentAiBatch jobs; `GET /documents/ai-status` (ids= per-file,
  client_id= summary), `POST /documents/{id}/retry-extraction`;
  AiExtractionProgress panel polls in the modal; Record Keeping polls +
  auto-reloads `only:['transactions']` with a green "AI is reading N documents" banner.
- **Direction fix**: new `ClientAiContext` (client name + company + ledger
  corporations + Companies/vendors directory) injected into the extraction prompt
  with cheque/invoice direction rules; `direction_uncertain` flag → amber
  "± direction?" chip on pending rows (click flips type; setting type clears flag
  server-side in TransactionsController@update).
- **Kind/Counterparty**: `transactions.payment_method` + `document_type` real
  columns (migration 2026_07_02_000002 + pgsql backfill from metadata.extras);
  ledger "Kind" badge column (editable select) + computed "Counterparty" column,
  both default ON.
- **Speed**: extraction calls run with `thinkingConfig.thinkingBudget=0`
  (config `services.gemini.thinking_budget`, env GEMINI_THINKING_BUDGET, default 0);
  Instant mode now SINGLE multimodal call (file→JSON, Economy shape) with the old
  two-step as fallback; GeminiClient retries only 429/5xx with [1.5s,4s,8s] backoff.
- Fixed latent crash: ScannerPanel used undeclared `uploadResult` state.
- Clear button (tester #3): code was correct; restyled to bordered "Clear selection".
  Tester claim #2 ("takes first 25 silently") matched NO code path — likely stale
  prod build; moot after chunking.

**Why:** testers hit the 25-file wall, silent AI failures, arbitrary +/- signs on
cheques (prompt never knew whose books), and slow extraction (default thinking +
2 calls/file + serial worker).

**Follow-up round (same day, after Amin's first test):** the "Upload failed
(HTTP 200)" errors = PHP ini `max_file_uploads=20` silently discarding multipart
parts beyond 20 (25-file chunks + PDF page renders tripped it; display_errors=On
corrupted the JSON with the warning). THIS was also the testers' original
"takes the first N files" claim — they were right. Fix: requests packed to
≤15 file parts + ≤45MB (`MAX_PARTS_PER_REQUEST`), loose JSON parsing
(brace-slice), post-chunk reconciliation auto-resends silently-dropped files
once (server returns `received_count`, client sends `expected_files`). PDFs
with >14 pages skip browser rendering (server poppler/whole path). Per-file
limit raised 5MB→**25MB** via new `config/uploads.php` (`UPLOAD_MAX_FILE_MB`),
unified across Batch Upload/Scanner/Drive; `files.*` validation removed in
favour of per-file loop checks so one bad file can't 422 its chunk. Durable
gotcha: **php.ini max_file_uploads is per-REQUEST (parts), not per batch** —
prod/pr should set max_file_uploads=100, upload_max_filesize=30M,
post_max_size=100M, display_errors=Off.

**Incident (2026-07-02 late): enum-schema 400 storm.** Amin's 246-file live test
produced 0 new drafts ("no transaction found" on everything, 139 stuck queued):
my responseSchema had an empty-string `''` member in the payment_method /
document_type enums and Gemini 400s on it ("enum cannot be empty") → EVERY
extract call failed → fallback failed the same way → empty result was recorded
as no_transactions. Fixes: (1) enums without '' + prompt says OMIT the field
(+ a KIND rule so cheque/receipt/invoice actually get filled); (2) extractor
now returns an `error` field and ingest THROWS on pipeline errors so the job
marks **failed** (with reason + Retry), never a false "no transactions";
(3) new `php artisan document-ai:requeue --status=failed,no_transactions
--hours=N [--client=] [--dry-run]` for bulk re-runs. Live-verified against real
Gemini (full extraction incl. payment_method=cheque). Durable gotchas: Gemini
responseSchema enum members must be non-empty; queue workers must be RESTARTED
after code changes or they run stale job code.

**Scale round (2026-07-02, approved by Amin — "thousands of users"):**
(1) dedicated AI queue via `AI_QUEUE_NAME` env (SAFE default 'default'; setting
it requires a Supervisor pool with `--queue=ai` — see DEPLOYMENT.md §8.2b, new
section); Extract + SubmitBatch jobs onQueue it. (2) `DocumentAiThrottle` job
middleware: fleet-wide Gemini budget `GEMINI_MAX_RPM` (default 250, jobs/min =
rpm/2) + per-tenant fairness `GEMINI_CLIENT_JPM` (default 60) via cache
RateLimiter; over-budget jobs RELEASED with jitter; jobs switched to
retryUntil(+6h) + maxExceptions=2 (tries removed — releases count as attempts).
(3) UI suggests Economy (Batch API) for >30-file uploads with AI+Instant —
chooser, user can override (device/paste + Drive). (4) fixed pre-existing
duplicate `flarum`/`whisper` blocks in config/services.php (later block was
silently dropping flarum.verified_accountant_group_id).

**How to apply / status:** local `php artisan migrate` + `npm run build` DONE;
smoke test green (context/validator/prompt/schema/markAiExtract). Amin tests per
the doc's manual guide, then checkpoint. PROD owes: migrate --force, npm install
+ build, config:clear, queue:restart, ideally Supervisor numprocs 3-4 for the
default queue, and a PAID Gemini key (429s now surface per-file). READ before
touching BatchUploadModal / document-AI pipeline / TransactionsTable columns.
