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

**Prod owes:** `migrate --force`, `.env` (`ADMIN_ANALYTICS_TOKEN`, `AI_USAGE_TRACKING=true`),
`config:clear`, a running scheduler. **No backfill exists** — data starts at deploy.
Seeded prices are starting points; verify against live rate cards.

Related: [[ai-cost-optimization]], [[gemini-model-policy]], [[wait-for-user-test-before-deploy]],
[[autocommit-leaks-secrets]], [[document-each-change]], [[feature-test-handoff]].
