---
name: gemini-repetition-loop-cost
description: "⚠️ Gemini extraction can fall into a repetition loop → 85K output tokens/call × retry storm = a real $ bleed. Guard: maxOutputTokens on the request + dedupeRows; Gemini REJECTS schema maxItems (HTTP 400). READ before touching DocumentAiExtractor / GeminiClient generationConfig / extraction cost."
metadata:
  type: project
  node_type: memory
  originSessionId: 63f90849-d724-4290-8f50-067a17f8a99c
---

**Discovered 2026-07-11 (fixed same day, NOT deployed — awaiting Amin's test).** A single
RONA receipt ($9.97) billed **85,500 output tokens** in one extraction call, and the file
re-processed ~14× over 5 hours (37 calls). ~$12 CAD on Google's bill in 3 days for ~20 files.

**Root cause (confirmed via the captured call-log payload):** `gemini-flash-lite-latest`,
given the schema-constrained `transactions` array, fell into a **repetition loop** — emitted
the SAME transaction object thousands of times until it hit the model's max output. Nothing
stopped it: the request set **no `maxOutputTokens`** and the schema array had **no bound**.
The looped/truncated JSON then failed to parse → extraction "failed" → two-step fallback (2
more calls) → job retried for hours = the 37 calls. The MODEL was correct (flash-lite, cheap);
the loop alone produced the bill. The gemini-2.5-flash rows in the by-model breakdown were
HISTORICAL (before the 2026-07-09 .env model fix), not current.

**The fix (all config-gated, in DocumentAiExtractor + GeminiClient):**
1. `GEMINI_MAX_OUTPUT_TOKENS_EXTRACT` (default 16384) → `generationConfig.maxOutputTokens` on
   every extraction generate call. THE guaranteed cost cap. Verified live: a "repeat 1000×"
   prompt stopped at 497 tokens, `finishReason: MAX_TOKENS`.
2. `DocumentAiExtractor::dedupeRows()` — a signature repeated > `DOC_DEDUP_LOOP_THRESHOLD`
   (default 3) collapses to one; genuine small dups kept; final `DOC_MAX_TRANSACTIONS_PER_FILE`
   (default 100) hard-caps kept count. Applied on BOTH extract paths (primary multimodal + extractFromText).
3. ⚠️ **Gemini `responseSchema` REJECTS `maxItems` → HTTP 400.** Do NOT add maxItems to the
   extraction schema (it breaks ALL extraction). Guards 1+2 cover the bound instead.

**Why the retry storm also stops:** loop collapses → extraction SUCCEEDS (valid small result)
→ nothing to retry. The job already refused to retry non-transport errors (`isTransportError`);
the storm came from extraction failing every time.

**Also true:** `GeminiClient::generate` has no output cap unless the caller passes
`maxOutputTokens` in options — voice/other callers are still uncapped (fine, they don't loop on
schema JSON). Docs: `docs/AI-COST-OPTIMIZATION.md` (Runaway output guard section). The whole
diagnosis was possible ONLY because of the [[ai-usage-monitoring]] call-log payload viewer.
Related: [[gemini-model-policy]], [[ai-cost-optimization]], [[wait-for-user-test-before-deploy]].
