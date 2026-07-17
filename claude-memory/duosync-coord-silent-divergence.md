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

**How to apply:** If sync seems off, check `git -C <coord> status` for a rebase in progress and `git rev-list --left-right --count origin/main...main`. Recover by `git rebase --abort` then, if the only local commits are disposable session/lock entries, `git reset --hard origin/main` and re-apply real work on top.

**FIXED 2026-07-01 (recurred that day — coord was mid-rebase, 153 behind):** the hooks were hardened so this shouldn't wedge silently again. (1) All three `duosync-*.sh` (both repos) now route the coord pull through a `duosync_pull()` helper that `git rebase --abort`s on failure (clone left CLEAN, never stuck mid-rebase) and prints a `DuoSync WARNING:` to stderr; `duosync-start.sh` also surfaces the warning inside its session-start `{"context":...}` so it's visible. (2) coord `.gitattributes` sets `session_log.md` + `claude-memory/MEMORY.md` to `merge=union`, so concurrent appends auto-combine instead of conflicting (kills the #1 conflict source). Commits: dashboard hooks `7036a2c` on `dev`, coord `.gitattributes` `d075312` on main. Marketing hooks auto-commit to va-website. A failed pull now leaves the clone behind-but-clean (self-heals on next clean pull) instead of permanently wedged.
