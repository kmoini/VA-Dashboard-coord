---
name: local-test-before-push
description: "⚠️⚠️ SINCE 2026-09-21 (Amin): the accounting team is testing on production, so NOTHING is pushed until Amin says so. Build + commit locally, wait; he tests locally first. Supersedes the old build-then-push habit."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-21T17:20:38.367Z
---

Amin, 2026-09-21: "الان تیم حسابداری داره تست میکنه برای همین قبل از اینکه هر
تغییری رو پوش کنیم و آنلاین بشه در لوکال تست میکنیم بعد بهت میگم پوش کنی".

**Why:** the accounting team is running a full test on production. A push reaches
the server through the deploy flow, so an unfinished change would land in the
middle of their testing.

**How to apply:**
- Build and commit locally as usual, then STOP. Do NOT `git push` until Amin
  explicitly asks for it, even when tests and the build are green.
- Say clearly in the reply that the work is committed locally and waiting for
  his word to push.
- He tests locally first; give him local test steps, not server deploy steps,
  unless he asks to deploy.
- When he does say push, push the commits and only then give the server commands.
- Extends [[wait-for-user-test-before-deploy]]; checkpoints ([[checkpoint-rule]])
  are still created only after his test, and their tag push waits for the same
  permission.

**Refined 2026-09-21, after Amin agreed push ≠ deploy:**
- PUSH is free once it is tested locally and green; pushing changes nothing on
  the server by itself.
- DEPLOY happens at the END OF THE DAY, when the accounting team is not working
  (a deploy runs npm build + optimize:clear and sometimes a data migration).
- ⚠️ The pr.voiceaccountant.com staging box is NOT used ([[pr-staging-box]]):
  Amin tests locally, then goes straight to production. Do not propose staging
  again.
- Take a database backup before any deploy carrying a data migration.

Reaffirmed by Amin 2026-10-01 at the start of Accounting V2 implementation: "do not send changes to live; when it is done we test locally first, then push if OK." Applies to every V2 phase: commit locally, hand over a local test guide, no push, no checkpoint tag until his test passes.

**CHANGED 2026-10-07 (Amin): the V2 engine is LIVE for every firm and Amin now tests on PRODUCTION, not localhost. Do not ask for localhost test steps or screenshots any more. Flow per fix: build + tests green → commit (named paths) → give Amin tag/push commands → he runs `git pull --ff-only` + optimize:clear + queue:restart on the server → he tests on production and sends screenshots. Still never push from here; still never tag on the server.**
