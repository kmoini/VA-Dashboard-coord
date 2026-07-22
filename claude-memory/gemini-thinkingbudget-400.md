---
name: gemini-thinkingbudget-400
description: ⚠️ gemini-3.1-flash-lite-preview rejects thinkingBudget:0 with HTTP 400 — broke ALL extraction; fixed by omitting thinkingConfig when budget<=0
metadata: 
  node_type: memory
  type: project
  originSessionId: 63f90849-d724-4290-8f50-067a17f8a99c
  modified: 2026-07-21T17:51:43.150Z
---

⚠️ **Model drift outage (2026-07-21, fixed cp-154, DEPLOYED to prod).**

`gemini-flash-lite-latest` now resolves to `gemini-3.1-flash-lite-preview`, which
returns **HTTP 400 INVALID_ARGUMENT** for `generationConfig.thinkingConfig.thinkingBudget = 0`.
The older 2.5-lite it used to alias ACCEPTED 0. See [[gemini-model-policy]] for the alias drift.

**Impact:** both the text (`extractFromText`) AND multimodal document-extraction
calls pass `thinkingBudget: 0` to disable thinking → **every extraction on prod
was 400ing**. Surfaced while enabling [[paddle-ocr-integration]] (its extractFromText
call failed, then multimodal failed identically). The generic error body ("Request
contains an invalid argument", no field named) made it look OCR-related — it wasn't.

**Bisect against the live API** (`gemini-flash-lite-latest`):
- `thinkingBudget: 0` → 400
- OMIT thinkingConfig → 200, **zero** thinking tokens billed (candidatesTokenCount only)
- positive budget (128/1024) → 200
- `-1` (dynamic) → 200 but ~1180 thinking tokens (expensive)

**Fix (single point, `GeminiClient::generate`):** a budget of 0 or negative now
**OMITS `thinkingConfig` entirely** instead of sending `thinkingBudget:0`; only a
POSITIVE budget is sent through. Guard changed from `>= 0` to `> 0`. Regression
test `tests/Unit/Services/GeminiThinkingBudgetTest.php` pins that budget 0 never
sends thinkingConfig.

**Durable rule:** never send `thinkingBudget: 0` to a Gemini 3.x model — omit
thinkingConfig to disable thinking. Watch for the SAME class of failure on other
generationConfig fields the preview model may reject. READ before touching
GeminiClient generationConfig / thinking / any Gemini 400 on extraction.
