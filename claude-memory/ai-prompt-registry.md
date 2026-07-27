---
name: ai-prompt-registry
description: Dashboard AI prompts are versioned DB templates edited at /admin/ai-instructions; NEVER add a prompt as a PHP heredoc
metadata: 
  node_type: memory
  type: project
  originSessionId: eafb3201-0d1c-4375-b764-d525833f5889
  modified: 2026-07-27T16:10:02.484Z
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
render via `AiPromptRegistry`. After pulling this change: `php artisan migrate` (2 new
migrations) + `npm run build`. Related: [[gemini-model-policy]],
[[activity-log-entity-type-trap]], [[global-ai-assistant-agent]].
