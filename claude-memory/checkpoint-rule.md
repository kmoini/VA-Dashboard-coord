---
name: checkpoint-rule
description: "How to handle the user's \"add a checkpoint\" request — commit + tag + push every time."
metadata:
  node_type: memory
  type: feedback
  originSessionId: 8f1fb65a-2016-4baf-8cf0-2fd6e4578a77
  modified: 2026-09-21T20:45:07.987Z
---

When the user asks to "add a checkpoint" (or "checkpoint"), perform ALL THREE steps, every time:

1. **Commit** with subject `checkpoint-NNN: <short title>`.
2. **Annotated tag** `checkpoint-NNN` with the same message.
3. **Push** the branch AND the tag to origin.

**Why:** Amin uses these tags as restore points and to trigger/track deploys.

**How to apply:**
- WARNING: Never assume NNN from memory, it goes stale. This is a shared repo
  (DuoSync teammates add checkpoints too). ALWAYS derive the next number from the
  live repo: `git -C ../va-dashboard2 tag -l "checkpoint-*" | sort -V | tail -3`,
  then use `latest + 1`. Reusing an existing number silently collides with a
  teammate's tag.
- Stage ONLY your own files, never sweep a teammate's uncommitted work into the
  commit (see [[autocommit-leaks-secrets]]). `git add <explicit paths>`, then
  confirm nothing else is staged.
- The full per-checkpoint history lives in git tags, not in this file. Read
  `git tag -l --format='%(contents:subject)' checkpoint-NNN` for any one.
- Deploy is a SEPARATE step (the deploy skill / n8n webhook), only when asked.
  The webhook git-pulls + npm-builds; migrations + Laravel cache clears stay
  manual (see [[deploy-process]]).

- Expect the push to be REJECTED as non-fast-forward: teammates push to `main`
  constantly. Fix is `git fetch` then rebase your commit onto `origin/main` —
  and `git tag -d` your tag FIRST, because the rebase rewrites the commit it
  points at, then re-tag after. Stash unrelated WIP before rebasing.
- Read the teammate commits you just pulled in. On 2026-07-30 Shahab had fixed
  the same bug from another angle an hour earlier; the right move was adopting
  his location and amending my message, not shipping a duplicate.

- Also watch for `main` moving UNDER you mid-session (DuoSync hooks / teammate
  sync fast-forward the local branch while your working tree is dirty). On
  2026-07-30 HEAD went from `ab73ad0` to `63edbfc` between the first `git status`
  and the commit. Before committing, re-check `git log -1` and re-run your tests
  against the new base — do not trust a test run from earlier in the session.

- A CONCURRENT session on this machine may commit your work before you do. On
  2026-07-31 a parallel session committed my finished-but-uncommitted
  log-triage work as checkpoint-203 under Amin's git identity, while I still
  thought it was pending. Before making a checkpoint, check whether HEAD
  already contains your files (`git log --stat -1`) instead of re-committing.

**Latest observed:** checkpoint-250 (2026-09-21, registry redesign phases 0+1: tables of record, People; see [[registry-people-redesign-plan]]). ⚠️ NOT deployed when tagged: two data migrations wait for the end-of-day deploy ([[local-test-before-push]]). 249 = Economy fallback + Read now + receipt date with time kept ([[document-ai-pipeline]]). 248 = Record Keeping frozen columns opaque; failed_jobs flushed on prod. 247 = one add-client form ([[add-client-single-form]]). 246 = QuickBooks deletion watcher, deleted entries offer Resend ([[quickbooks-push-idempotency]]). 245 = subtype sightings used per country + apostrophe vendor names push ([[international-quickbooks]]). 244 = a mixed-rate receipt posts its own total ([[sales-tax-hst-gst]]). 243 = the United States verified, 242 = Britain and Australia. 241 = sales tax posts the right number, 240 = Canadian QuickBooks verified, 239 = the GIFI to QBO mapping build. Verify against `git tag` (fetch --tags first) before your next number, several people push here.
