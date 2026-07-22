---
name: batch-upload-ai-tester-fixes
description: "2026-07-02 tester-feedback round on Batch Upload + Document AI — chunked uploads (no 25-file UI cap), per-file ai_extract_status + retry + ledger auto-refresh, client-context direction fix (direction_uncertain chip), Kind/Counterparty columns, thinkingBudget=0 + single-call extraction. BUILT on main working tree, NOT committed — awaiting Amin's test."
metadata: 
  node_type: memory
  type: project
  originSessionId: 450de5d9-ae01-4f79-89e6-572e5d8cbbf6
  modified: 2026-07-21T20:22:01.515Z
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

**Resilience round (2026-07-03, after Amin's 50-file test "nothing appears"):**
diagnosis from log+DB: (a) drafts WERE being created but for yesterday's client-2
backlog — today's 50 files (client 1, XYZ Limited) sat behind ~350 old jobs in a
406-deep database queue; (b) this Windows box gets intermittent cURL 28 timeouts
to Gemini (the known local stall gotcha) and the old budgets (120s × 4 attempts
× single-call + 2-step fallback) let ONE bad file grind a worker for 16.5 min;
(c) 352 zombie queued/processing rows made the "AI is reading N documents"
banner lie; (d) "The system cannot find the path specified" console noise =
PdfPageSplitter running `where pdftoppm 2>/dev/null` on cmd.exe (fixed: 2>NUL +
memo). Fixes: GEMINI_TIMEOUT default 120→75s, retries 4→3 attempts, extractor
SKIPS the two-step fallback on connection-class errors (fails fast → failed +
reason + Retry; helper isConnectionError), zombie sweeper piggybacked on
document-ai:poll-batches (processing>2h, queued>24h → failed w/ message),
document-ai:requeue now also accepts queued/processing (recovery after
queue:clear), and the modal success view shows "Booked to client: X" (files
"disappear" when the ClientSwitcher pin ≠ the client picked in the modal —
user confusion, not a bug). Durable gotchas: database queue is FIFO so an old
backlog starves new uploads (multiple workers and/or queue:clear+requeue);
Record Keeping/Documents are client-scoped — check the client filter before
declaring uploads lost.

**Speed round 2 (2026-07-03 later):** 50-file batch took ~50 min on ONE worker
because of the cURL-28 stalls. Root-cause fix shipped: **GEMINI_FORCE_IPV4
(default on)** — the "cURL error 28 … 0 bytes received" stall to
googleapis.com is curl trying a blackholed IPv6 route first; all Gemini HTTP
now goes through GeminiClient::http() with CURLOPT_IPRESOLVE_V4. Also:
upload timeout now SCALES with file size (min 60s, 20s/MB, cap
GEMINI_UPLOAD_TIMEOUT) so a 300KB receipt can't burn 300s on a stall, and
GEMINI_TIMEOUT default → 60s. Durable gotchas: IPv6 blackhole = first suspect
for Gemini stalls on Windows dev boxes; "AI is reading N" count can tick UP
briefly when a failed file re-enters processing via retry (not a bug). Also:
`php artisan queue:clear` + document-ai:requeue recovery was exercised for
real (user wiped a 406-job backlog; requeue --status=queued --client=N
restored the 50 stranded files). Ledger got an "AI drafts" quick chip
(pending+source=ai) — testers had no manual way to reach the AI filter.

**Speed round 3 (2026-07-03 evening):** IPv4 forcing did NOT kill the cURL-28
stalls (still ~20% of calls, 4 workers, 50 files/35 min → 40 done, 7 failed
visible w/ Retry). Added two more transport hardenings in GeminiClient::http():
**HTTP/1.1 forced by default** (GEMINI_HTTP_1_1 — 0-byte stalls through
VPN/DPI middleboxes are often silent HTTP/2 stream resets) and **GEMINI_PROXY**
(route only Gemini traffic through a dedicated stable tunnel, e.g.
socks5h://127.0.0.1:1080). Verdict recorded for Amin: the residual stalls are
the dev box's network route to googleapis.com, not code — real speed test
belongs on the pr/prod Linux box; locally use GEMINI_PROXY if a stable tunnel
exists. Local test artifacts were wiped on request (125 doc-hub drafts + 698
uploaded docs soft-deleted; mobile/chat/email attachments untouched;
cleanup criteria: source=ai + metadata.ai_pipeline=document-hub, and
attachments mobile_id NULL + uploaded_by_source in web_dashboard/scanner/
google_drive + created_at >= 2026-07-02).

**Persistent failures panel (2026-07-03, Amin's request — modal list dies on
OK):** `/documents/ai-status` client-summary now returns `failed_files` (last
24h, ≤50, name+reason); Record Keeping renders a rose panel under the live
banner with per-file Retry + Retry all + hide-until-reload, fed by the same
poller. HTTP/1.1 forcing verified effective in practice: 50-file run went
46 extracted / 1 cURL-28 fail (from ~20% fail rate before).

**Ledger pagination was INVISIBLE (fixed 2026-07-03):** TransactionsTable read
`transactions.meta` but the controller passes a raw Laravel paginator, which
serialises FLAT (last_page/from/to/total at top level, no meta wrapper) → the
footer's `meta.last_page > 1` was never true → no page buttons ever rendered
and rows past page 1 (20/page) were unreachable. Fixed by normalising in the
component (`meta = transactions.meta ?? transactions`), covering every page
that renders the table. Related UX answered: ClientSwitcher badge = client's
PENDING count; bulk-select intentionally selects current page only. Also fixed
same day: Document Hub PDF preview embedded the RAW serve URL in an iframe →
download managers (IDM) intercepted it (auto-download + blank frame); now uses
the same base64→blob path as other viewers, and the preview fetch uses
serve_url (appending preview=1 to a signed S3 URL invalidated the signature).
Counterparty column: computed direction-aware summary (expense→"to vendor",
revenue→"from customer") — do NOT show alongside raw Vendor/Customer columns
(removed from the Parties preset).

**Self-healing retry for transport stalls (2026-07-03 last round):** Amin kept
seeing cURL-28s. ExtractDocumentTransactionsJob now distinguishes error class
in its catch via new `GeminiClient::isTransportError()` (shared with the
extractor's fallback-skip): TRANSPORT errors rethrow and retry on
`$backoff=[180,900]` (3 tries: now, +3 min, +15 min — flaky routes recover in
minutes) with maxExceptions=3; NON-transport errors (API 4xx, bad file) mark
failed IMMEDIATELY and return without burning retries. Files only reach the
red failed panel after ~18 min of self-healing attempts. Verdict stands: the
stalls are this dev box's route to googleapis.com; prod won't have them.

**checkpoint-120 (2026-07-04 night, prod incident):** file stuck "processing
forever with EMPTY error" on prod = the worker's pcntl alarm KILLED the job
mid-Gemini-call because the job $timeout (300s) was smaller than the HTTP
budget inside it (upload cap 300s + 3 attempts × GEMINI_TIMEOUT); a pcntl
kill runs NO catch/failed(), and Laravel double-inserts failed_jobs (uuid
unique violation). Fix: generate() = ONE retry (budget ≤ 2×timeout+2s), job
$timeout 300→540, requeue command falls back to first user id for
uploader-less rows. DURABLE RULE: any queue job wrapping HTTP calls must keep
total HTTP budget < job $timeout. Prod runs GEMINI_TIMEOUT=150 in .env (slow
tail >60s observed); prod ALSO gets intermittent cURL-28/slow Gemini windows
(not just the dev box). Prod worker daemon = `queue:work database
--queue=mobile-sync,default`.

**Portal bulk delete (2026-07-06, BUILT NOT COMMITTED):** client-portal users
can now soft-delete their own transactions like accountants —
TransactionPolicy::delete switched to the clientOwns() self-manage pattern
(own client + lock rules; forceDelete stays false) and can.delete in
TransactionsController@index returns true for portal users. Backend-only (the
shared TransactionsTable Delete button lights up via can.delete). Portal
ledger = the REAL /recordkeeping page (pinned session); legacy /client/records
stays read-only.

**No-auto-retry round (2026-07-21, Amin's request, BUILT NOT COMMITTED):**
extraction failures no longer self-heal in the background — ExtractDocumentTransactionsJob
marks failed IMMEDIATELY on any error (maxExceptions 3→1, backoff removed; retryUntil
stays for throttle releases). UI Retry button now CONDITIONAL: only AI-side errors
(Gemini API / network patterns via new Attachment::aiExtractRetryable(), `retryable`
flag in /documents/ai-status) — local-file errors get no Retry. New Cancel button +
`POST /documents/{id}/cancel-extraction` + status AI_EXTRACT_CANCELLED (no migration;
markAiExtract now a conditional UPDATE so a cancelled file can't be resurrected by a
late job verdict; queued job bails on cancelled). Round 2 same day
("no loops ever", after prod call-log showed per-page 400/paid/400 clusters repeating):
(a) prod 400 storm = STALE WORKER running pre-cp-154 code (thinkingBudget:0 bug) —
schema verified fine on pinned gemini-3.1-flash-lite via live local probe;
(b) extractor now SKIPS two-step fallback on deterministic `Gemini API error (HTTP 4xx)`
(fallback's JSON step 400s identically — only the transcribe call billed);
(c) job re-entry with status still `processing` (= prior attempt pcntl-killed, the only
auto-re-entry left via retryUntil) marks failed("interrupted", retryable) instead of
re-calling Gemini → extraction exactly-once per queue attempt. Doc:
docs/ai-extraction-manual-retry-cancel.md. Prod owes deploy + optimize:clear (new route) +
queue:restart (else stale workers keep 400ing/auto-retrying).

**How to apply / status:** local `php artisan migrate` + `npm run build` DONE;
smoke test green (context/validator/prompt/schema/markAiExtract). Amin tests per
the doc's manual guide, then checkpoint. PROD owes: migrate --force, npm install
+ build, config:clear, queue:restart, ideally Supervisor numprocs 3-4 for the
default queue, and a PAID Gemini key (429s now surface per-file). READ before
touching BatchUploadModal / document-AI pipeline / TransactionsTable columns.
