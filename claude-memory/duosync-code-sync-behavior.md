---
name: duosync-code-sync-behavior
description: "DuoSync hooks now also sync the code repo: merge main into dev on start, push dev to origin on end"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: ba92d8e4-b6b6-4b1f-84fc-fd40acae8be3
---

DuoSync hooks in `va-website` (and should be mirrored to VA-Dashboard) now do code sync in addition to memory sync.

**Rule:** When on the `dev` branch, DuoSync must (1) merge latest `main` into `dev` and (2) push `dev` to `origin/dev`.

**Why:** Kamyar works on `dev`. Before building new features, `dev` must have the latest `main` so that work is based on the most recent code and remote conflicts are minimized. Running DuoSync is the workflow trigger for this sync.

**How to apply:**
- `duosync-start.sh` — after memory pull, fetch `origin/main` and merge into local `dev` (skip if dirty working tree).
- `duosync-end.sh` — after memory push, fetch `origin/main`, merge into `dev` (skip if dirty), then `git push origin dev`.
- Both steps are guarded: only run when `git rev-parse --abbrev-ref HEAD` = `dev`. Silently skip on any other branch.
- If working tree has uncommitted changes, skip the merge (git can't merge dirty) but still push committed changes.
- Applied to va-website hooks on 2026-06-30. **VA-Dashboard hooks need the same update** — apply before the next session on that project.
