---
name: gemini-model-policy
description: "Dashboard Gemini model policy — ALWAYS gemini-flash-lite-latest for everything, never gemini-2.5-flash"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 5d408cdf-e88c-4be4-92ad-d32cb71a0734
---

Amin's standing decision (2026-07-06): the dashboard (va-dashboard2) must use
**`gemini-flash-lite-latest` for ALL Gemini calls** — both `model_extract`
(reasoning / extraction / AI assistant / voice interpret) and `model_file`
(OCR / transcription). `gemini-2.5-flash` is retired.

**Why:** single-model policy chosen by Amin; flash-lite is cheaper/faster and
sufficient for the dashboard's schema-locked extraction and assistant work.

**How to apply:**
- Defaults changed in `config/services.php` (`services.gemini.model_extract`
  now defaults to `gemini-flash-lite-latest`), plus `.env`, `.env.example`, and
  the `GeminiClient.php` doc-block (all edited 2026-07-06, local dev only at
  time of writing — not yet committed/deployed).
- New code must read `config('services.gemini.model_extract'|'model_file')`,
  never hard-code a model name.
- ⚠️ Prod `.env` overrides the config default: if prod still has
  `GEMINI_MODEL_EXTRACT=gemini-2.5-flash`, change it to
  `gemini-flash-lite-latest` + `php artisan config:clear`.
- Rule also recorded in `va-dashboard2/CLAUDE.md` ("AI / Gemini Model Policy").
- Consumers all read from config (verified 2026-07-06): DocumentAiExtractor,
  DocumentAiIngestService, SubmitDocumentBatchJob, AiAssistantService,
  VoiceCommandInterpreter, TransactionAssistant, InboundEmailService.

Related: [[document-ai-pipeline]], [[global-ai-assistant-agent]],
[[record-keeping-ai-voice-edit]], [[batch-upload-ai-tester-fixes]]
