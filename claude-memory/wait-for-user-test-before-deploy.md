---
name: wait-for-user-test-before-deploy
description: Do NOT checkpoint+deploy until the user has tested the change and says go.
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 17bad86a-d76b-4d18-8ff0-27c8095a333f
  modified: 2026-07-28T21:50:46.360Z
---

From 2026-06-25: do **not** run checkpoint + deploy right after making a change. Make the
change (and build/verify locally), then **stop and wait** for the user to test it and
explicitly tell you to checkpoint/deploy.

**Why:** the user wants to verify each change in the running app before it's committed and
pushed to prod (the deploy webhook + the auto-commit risk make premature pushes costly).

**How to apply:** implement → `npm run build` / local verify → report what changed and how
to test → WAIT. Only commit (`checkpoint-NNN`), tag, push, and fire the deploy webhook
once the user says so. Overrides the default "checkpoint = commit+tag+push+deploy" reflex
in [[checkpoint-rule]] on timing only (the steps themselves are unchanged).

**RESTATED 2026-07-28 (stronger, standing rule):** "همیشه قبل از کامیت و دیپلوی از من سوال کن"
— ALWAYS ASK before committing and before deploying, every time. Do not treat an earlier
"checkpoint + deploy" in the same session as blanket authorisation for later changes: each
one needs its own go-ahead. Finishing a build is NOT permission to commit. Ask, then wait.
