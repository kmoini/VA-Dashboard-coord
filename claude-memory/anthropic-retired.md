---
name: anthropic-retired
description: "Anthropic/Claude is RETIRED from va-dashboard2 (2026-09-09, Amin) — code path, config block, env vars and rollback switch all removed; Gemini is the only provider"
metadata: 
  node_type: memory
  type: project
  originSessionId: 631f1e15-da4d-4f20-b873-5e6861ffb5d2
  modified: 2026-09-09T16:47:52.927Z
---

Amin, 2026-09-09: "دیگه از اون استفاده نمیکنیم (Anthropic), هر جایی که هست غیر
فعالش کن." Taken as full REMOVAL, not a config switch, and built that way.

**What is gone from va-dashboard2:** `askAnthropicForJson()` + the provider branch
in `CallsAiForJson` (its `aiProvider()` now returns `'gemini'` or `null`),
`AiUsageRecorder::anthropic()`, `app/Console/Commands/AiCompareProviders.php`
(deleted), the `services.anthropic` config block, `services.ai.provider`, the
admin "running on the Claude rollback" banner, and `ANTHROPIC_API_KEY` /
`ANTHROPIC_MODEL` / `AI_LEGACY_PROVIDER` from `.env.example` and the dev `.env`.
Full record: `docs/ANTHROPIC-RETIREMENT-2026-09-09.md`.

**Why:** it was only ever the no-deploy rollback, but the trait ALSO fell back to
Anthropic automatically when Gemini had no key. That silently moved live
accountant traffic onto a provider at ~10x the per-token price. With one
provider, an unset `GEMINI_API_KEY` now means "no AI suggestions", which is the
honest failure.

**How to apply:**
- ⚠️ Do NOT reintroduce a second provider in `CallsAiForJson` without also
  restoring `AiUsageRecorder::anthropic()`, the fallback logging and the ai_prices
  rows. Gemini-only is the decision, not an accident.
- `AiUsageRecorder::PROVIDER_ANTHROPIC`, the `anthropic` rows in the ai_prices
  seed, `anthropic_usage` on the admin endpoint and `in:gemini,anthropic` on
  `setPrice` are KEPT ON PURPOSE: pre-2026-09-09 `ai_usage_events` rows carry
  `provider='anthropic'` and must still price and chart. Deleting them rewrites
  history.
- ⚠️⚠️ Tests decide AI-on/AI-off from CONFIGURED KEYS, not from `Http::fake`. There
  is no `.env.testing`, so a developer's real `GEMINI_API_KEY` DOES load in local
  test runs. Tests meaning "AI is off" must null BOTH `services.gemini.api_key`
  and `services.gemini.paid_keys`; tests meaning "AI is on" fake
  `*generativelanguage*` with a `candidates.0.content.parts.0.text` body. An
  unmatched URL under Laravel's HTTP fake leaves the machine for real.
- ⏭️ OWED BY AMIN, not done: remove the three vars from prod/staging `.env`,
  **revoke the key at console.anthropic.com**, then `config:clear` +
  `queue:restart` ([[deploy-process]]).
- NOT deployed, NOT checkpointed. Waiting on Amin's test ([[wait-for-user-test-before-deploy]]).

Verified: 180/180 on the affected suites; the 17 failures in the wider run
(SmartImportTest x8, ServiceTokenMinterTest x8, NoHardCodedAiModelTest x1) were
confirmed identical on a clean `git stash` baseline.

Related: [[gemini-model-policy]], [[ai-usage-monitoring]], [[gemini-cost-overspend-investigation]], [[privacy-security-audit]]
