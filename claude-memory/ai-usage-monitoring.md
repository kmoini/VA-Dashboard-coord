---
name: ai-usage-monitoring
description: "Per-user/per-feature/per-step AI token+cost ledger for the dashboard — built 2026-07-09, verified, NOT deployed; read before touching AI cost, GeminiClient recording, ai_prices, or the admin analytics API."
metadata: 
  node_type: memory
  type: project
  originSessionId: 63f90849-d724-4290-8f50-067a17f8a99c
---

Built 2026-07-09 (Amin asked: "which part of the dashboard AI costs us the most, per user").
**Verified locally (39 backend + 32 UI assertions, 0 failures). NOT deployed. Awaiting Amin's manual test.**
Full design: `va-dashboard2/docs/ai-usage-monitoring.md`; test guide: `docs/ai-usage-monitoring-test-guide.md`.

Three tables: `ai_usage_events` (raw, 1 row/call, 90d retention), `ai_usage_daily`
(permanent rollup, hourly `ai:usage-rollup`), `ai_prices` (versioned, editable from
the admin UI; `price_id` pins each event so a rate change never rewrites history).

Attribution: `AiUsage::begin(feature, userId…)` at the entry point (controller/job),
`AiUsage::step(step, fn)` at the call site. `AiUsageContext` is bound **`scoped()`**,
not singleton — Laravel forgets scoped instances between queue jobs, otherwise one
accountant's Batch Upload gets billed to the next job in the worker.

**Non-obvious traps this encodes:**
- Gemini `promptTokenCount` INCLUDES `cachedContentTokenCount` → store `prompt − cached`.
  Anthropic `input_tokens` EXCLUDES both cache fields → store as-is. Getting this
  backwards double-counts cheap tokens and hides expensive ones.
- Gemini `thoughtsTokenCount` bills at the **output** rate, not input (~4x error if wrong).
- Postgres has no `DELETE … LIMIT` → `ai:usage-prune` deletes by id in chunks.
- Rollup upserts and never deletes buckets; a backfill needs `--days` ≥ span+2 or
  backdated rows are missing from every range longer than the raw retention window.
- `AiUsageRecorder` swallows every exception by design: a bookkeeping failure must
  never break an accountant's extraction. Kill switch `AI_USAGE_TRACKING=false`.

Admin API: `/api/admin/dash/*`, POST + `X-Admin-Token`, stateless (own `AdminApiCors`,
NOT config/cors.php which is Flarum-scoped). Blank `ADMIN_ANALYTICS_TOKEN` → 503, never
open. UI lives in the untracked `va-dashboard2/index 3.html` (so it never auto-pushes);
additions are purely additive behind an optional second API base — mobile sections untouched.

**Gemini call logs (added 2026-07-10, verified real-Gemini+browser, NOT deployed):** full
request+raw response of every Gemini call, per user, for debug/audit. SEPARATE table
`gemini_call_logs` (NOT columns on `ai_usage_events` — keeps the hot table lean; a separate
table gives the isolation without SQLite's write-lock/ephemeral-FS problems, which is why we
rejected "one SQLite per user"). Written best-effort in `AiUsageRecorder::logGeminiCall()`
right after the event; `write()` now returns the event. Payloads = gzip→base64 via
`App\Casts\GzipText` (base64 not bytea, so sqlite-dev == pg-prod). Config under `services.ai_usage`:
`call_log` (GEMINI_CALL_LOG, default true), `call_log_max_bytes` (262144, floored 1024, clips+flags
`truncated`), `call_log_retention_days` (30). Prune `gemini:calllog-prune` daily 03:45. API:
`/user/calls` now returns `has_payload`; `/user/calls/payload {userId,eventId}` returns decompressed
pretty payloads (re-checks userId → 404, no cross-user read). UI: expandable ▶ rows in the per-user
"Raw calls" list → two panes (request / raw response) + Copy. **`gemini_call_logs.tenant_id` MUST be
a string** — it mirrors `ai_usage_events.tenant_id` = the firm's `accountant_account_id` UUID; a
bigint column throws `invalid input syntax for type uuid` on prod (the probe caught this pre-ship).
Docs: `docs/gemini-call-logs.md`.

**Call-log 2nd pass (2026-07-10, verified real-Gemini+browser, NOT deployed):** readability for a
non-technical operator. (a) **Grouped by upload** — calls sharing `meta.attachment_id` collapse into
one file row (date + "1 file · 38 pages · 38 AI calls · $x USD"), click→per-page detail→Back; solo
calls (chat/voice) open payload directly. The visual answer to "why 38 calls?" (1 PDF = 1 Gemini
call/page). (b) **file_name + page_count** in the extraction job's context meta, **page_index** per
page in `ingestEachPage`, file_name in email intake → flow to `ai_usage_events.meta`, NO backfill.
(c) **Call KIND** in `AiFeature` (`STEP_KIND`: extraction/transcription/assistant/classify/analytics)
→ badge + filter. (d) **System vs user** origin (`AiFeature::FEATURE_ORIGIN`/`isSystem()`; system =
email_intake, categorization, vendor_extract, account_classify, voice_intelligence) → 3 cards on AI
Cost (System/User/Total) from `origin_totals`, reconcile to grand total. (e) slow-call amber>20s/
red>60s. (f) "?" tooltips (existing METRIC_INFO) + explicit **USD** (Gemini+Anthropic bill USD, never
CAD). Helpers: `AiFeature::stepKind/featureOrigin/isSystem/systemFeatures`,
`AdminAiUsageController::originTotals/withKind`; UI `groupCalls/renderCalls/renderCallGroupDetail/
originTotalsCards` in `index 3.html`.

**Prod owes:** `migrate --force`, `.env` (`ADMIN_ANALYTICS_TOKEN`, `AI_USAGE_TRACKING=true`;
optionally `GEMINI_CALL_LOG`), `config:clear`, a running scheduler. **No backfill exists** — data
starts at deploy. Seeded prices are starting points; verify against live rate cards.

Related: [[ai-cost-optimization]], [[gemini-model-policy]], [[wait-for-user-test-before-deploy]],
[[autocommit-leaks-secrets]], [[document-each-change]], [[feature-test-handoff]].
