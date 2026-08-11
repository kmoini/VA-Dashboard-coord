---
name: ai-prompt-registry
description: Dashboard AI prompts are versioned DB templates edited at /admin/ai-instructions; NEVER add a prompt as a PHP heredoc
metadata: 
  node_type: memory
  type: project
  originSessionId: eafb3201-0d1c-4375-b764-d525833f5889
  modified: 2026-08-10T22:19:50.479Z
---

Every LLM prompt in the dashboard is a versioned, admin-editable template rather than a
string in PHP. Landed when `dev` merged into `main` (2026-07-24/25, reported by Shahab's
Claude); verified present in `va-dashboard2`:

- `app/Services/AiPrompts/AiPromptCatalog.php` — the catalog of prompt keys.
- `app/Services/AiPrompts/AiPromptRegistry.php` — renders a key into the final prompt text.
- `resources/ai-prompts/{key}.txt` — the prompt bodies (e.g. `assistant.turn.txt`,
  `account-classifier.classify.txt`, `assistant.system-accountant.txt`).
- `app/Models/AiPrompt.php` + `AiPromptVersion.php`, migrations
  `2026_07_24_000001_create_ai_prompts_tables` and `2026_07_24_000002_add_ai_prompt_to_activity_logs`.
- Docs: `docs/ai-instructions-admin.md`. UI: `/admin/ai-instructions`, **platform_admin only**,
  gated by the cp-163 tiering (see [[platform-operator-tier]]).

The five reworked AI services kept their existing prompt TEXT, they just render it through
the registry now. The extraction client context (owner / companies / bank-accounts /
counterparties) became four editable fragments, and DocumentClassifier's prompt was
externalized too.

**Why:** prompts are product copy that non-engineers need to tune and roll back, and a
heredoc buried in a service is invisible, unversioned, and undeployable without a release.

**How to apply:** NEVER add an AI prompt as a PHP heredoc, there is a test enforcing this.
Add a catalog entry in `AiPromptCatalog` + a `resources/ai-prompts/{key}.txt` file, and
render via `AiPromptRegistry`.

⚠️ **THE TRAP (cost a whole prod debugging session, 2026-08-10): editing the .txt file
does NOT change production.** `AiPromptRegistry::activeContent()` resolves DB override
FIRST and the shipped file is only a fallback. Every key someone has ever saved at
`/admin/ai-instructions` has an active DB version, so a shipped prompt improvement is
silently ignored on prod, forever, with no error. It bit checkpoint-221: the new
`document_role` guidance shipped in the file, the JSON schema (PHP, so it DID deploy)
forced the model to answer a field the prompt never explained, and the model guessed from
the enum names. Result looked like "the AI is just wrong" — cheque copies and leases still
booked, pay stubs correct by luck.

**Check before assuming a prompt change is live:**
`$r->overrideContent($key) !== null ? 'DATABASE' : 'file'` plus
`str_contains($r->activeContent($key), '<your new text>')`.

**To actually roll a file change out**, first prove the file is a superset of the DB
version (compare line by line: no DB line missing from the file), then publish the file
content as a NEW version with a real note:
`$r->publish($key, $r->shippedContent($key), null, 'Refinement: ...')`.
Do NOT use `resetToShipped()` casually: `document-extraction.extract` / `.batch` carry 11+
deliberate refinements (v1-v11, each tied to a reported bug), and its note is a fixed
"Reset to shipped default" that destroys the refinement trail this project relies on.

Related: [[document-role-triage]], [[gemini-model-policy]],
[[activity-log-entity-type-trap]], [[global-ai-assistant-agent]].
