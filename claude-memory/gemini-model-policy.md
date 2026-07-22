---
name: gemini-model-policy
description: "Dashboard Gemini model policy — PINNED to gemini-3.1-flash-lite (stable), NOT the -latest alias; never hard-code, read config"
metadata:
  node_type: memory
  type: feedback
  originSessionId: 5d408cdf-e88c-4be4-92ad-d32cb71a0734
---

Amin's decision (updated 2026-07-21, cp-155): the dashboard (va-dashboard2) uses
**`gemini-3.1-flash-lite` for ALL Gemini calls** — both `model_extract` and
`model_file`. This is a PINNED STABLE version, deliberately NOT the
`gemini-flash-lite-latest` alias.

**Why the change from -latest:** the alias silently drifts onto new preview
models. In 2026-07 it moved onto a 3.x-lite that (a) cost ~4x the assumed rate
and (b) REJECTED `thinkingBudget:0` with HTTP 400, taking down ALL extraction
(text + multimodal + batch) — see [[gemini-thinkingbudget-400]]. Pinning kills
that whole class of surprise. Original intent (2026-07-06) was cheap/fast lite;
gemini-2.5-flash-lite / 2.0-flash-lite are now RETIRED on our key (HTTP 404,
verified — they appear in ListModels but 404 on call), so 3.1-flash-lite is the
cheapest working lite. gemini-3.5-flash-lite works but rejects thinkingBudget:0.

**How to apply:**
- Default in `config/services.php` (`services.gemini.model_extract` / `model_file`
  = `gemini-3.1-flash-lite`), plus `.env`, `.env.example`. All Gemini tuning
  knobs are now env-overridable (GEMINI_MODEL_EXTRACT/FILE, GEMINI_THINKING_BUDGET,
  GEMINI_MAX_OUTPUT_TOKENS_EXTRACT, GEMINI_TEMPERATURE_EXTRACT, GEMINI_TIMEOUT, ...).
- ⚠️ Prod `.env` OVERRIDES the default: set `GEMINI_MODEL_EXTRACT=gemini-3.1-flash-lite`
  + `GEMINI_MODEL_FILE=...` then `php artisan config:clear` + `queue:restart`
  (workers cache old config/code — [[deploy-process]]).
- New code must read `config('services.gemini.model_extract'|'model_file')`, never
  hard-code (guarded by NoHardCodedAiModelTest).
- Drift detector `services.ai.model_policy` default now allows both the pinned
  model and the old alias (historical events). AiPricesSync MODEL const also moved
  to gemini-3.1-flash-lite — run `ai:prices-sync` on prod so cost lookups resolve.
  ✅ RATE values CORRECTED to the official rate card (cp-156, 2026-07-21): in $0.25 /
  cached $0.025 / out $1.50 / batch 50%. Run ai:prices-sync on prod. Historical re-pricing still deferred.

Related: [[gemini-thinkingbudget-400]], [[document-ai-pipeline]], [[ai-usage-monitoring]]
