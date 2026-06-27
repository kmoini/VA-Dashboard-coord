---
name: duosync-coord-silent-divergence
description: "DuoSync hooks swallow git errors, so the local coord clone can silently diverge from origin"
metadata: 
  node_type: memory
  type: project
  originSessionId: 26ac9d01-64da-40f0-8655-484a695816a6
---

The DuoSync hooks run their coord `git pull --rebase` / `git push` with `-q 2>/dev/null`, so when a rebase hits a conflict (commonly concurrent appends to `session_log.md` or lock files) it fails silently and leaves the rebase half-done. The local coord clone then stops syncing — locks AND shared Claude memory quietly stop reaching teammates — while everything looks fine.

On 2026-06-27 Shahab's coord clone was found 2209 commits behind origin with one junk local commit; fixed by catching the local clone up to origin (no shared-history rewrite). See [[duosync-shared-memory]].

**Why:** Silent error suppression hides a broken sync; the only visible symptom is that teammates stop seeing your updates.

**How to apply:** If sync seems off, check `git -C <coord> status` for a rebase in progress and `git rev-list --left-right --count origin/main...main`. Recover by `git rebase --abort` then, if the only local commits are disposable session/lock entries, `git reset --hard origin/main` and re-apply real work on top. A longer-term fix would be to stop swallowing rebase failures in the hooks.
