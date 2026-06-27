---
name: record-keeping-ai-voice-edit
description: Record Keeping AI Voice-to-Edit redesign — locked decisions + 4-phase plan; Phase 1 building. Read before touching the Record Keeping detail panel or voice features.
metadata: 
  node_type: memory
  type: project
  originSessionId: 17bad86a-d76b-4d18-8ff0-27c8095a333f
---

Redesign of **Record Keeping** (`Transactions/Index.jsx` = the transaction
ledger, NOT a doc feed). Centerpiece: **AI Voice-to-Edit** — accountant
records/speaks on a transaction; the existing Gemini pipeline transcribes + proposes
a structured field diff; human reviews & approves. AI never auto-applies. Apply
reuses the version-guarded `PUT /recordkeeping/{tx}` (`TransactionsController::update`).
Full spec + test guide: `docs/record-keeping-ai-voice-edit.md`.

**7 locked decisions** (settled with Amin after comparing Gemini/ChatGPT/Grok):
1. Transcript = raw-immutable (`voice_transcription_raw`) + editable searchable copy
   (`voice_transcription`); "Human edited" badge via `voice_transcription_edited_at`.
2. Both compute paths — sync (hero, paid key) + queued/async later. Phase 1 = sync only.
3. Documents Lens = Phase-1 link to existing Document Hub only; in-page lens deferred.
4. Auto-transcribe + Voice→Diff ship together.
5. AI auto-decides note vs command; on edit intent it asks "Do you want to edit…?" gate.
6. Any `can.edit` user; client-portal excluded; locked/tax_submitted rejected.
7. Strict 80% confidence bar to auto-check a proposed change (UI pills still use 75/50 colours).

**Phases:** 1 = AI Voice & Edit core (in progress). 2 = intake drawer + oversize cards.
3 = smart attachment chip/hover + Re-read-with-AI (Mode C) + Has-Voice/Has-Attachment/File-Type
filters + Browse-all-documents link. 4 = voice search + i18n/RTL pass + a11y. Order 1→(2/3)→4.

**Phase-1 files:** `app/Services/Gemini/VoiceCommandInterpreter.php`,
`app/Http/Controllers/VoiceEditController.php` (routes `POST .../voice-edit`,
`PATCH .../transcription`), migration `2026_06_19_000001_add_voice_edit_fields_to_transactions`,
`resources/js/Components/VoiceAiEdit.jsx` wired into `TransactionDetailPanel`.
Proposable fields exclude `status` (finalize) + `gifi_code` (CRA gate) in Phase 1.
Prod owes: `migrate --force` + `npm run build` + **paid** `GEMINI_API_KEY` (free tier ~20 req/min).
Reuses `DocumentAiExtractor`/`GeminiClient` (see [[document-ai-pipeline]]).
