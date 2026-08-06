---
name: duosync-coord-silent-divergence
description: "DuoSync hooks swallow git errors, so the local coord clone can silently diverge from origin"
metadata: 
  node_type: memory
  type: project
  originSessionId: 26ac9d01-64da-40f0-8655-484a695816a6
  modified: 2026-08-06T14:58:19.356Z
---

The DuoSync hooks run their coord `git pull --rebase` / `git push` with `-q 2>/dev/null`, so when a rebase hits a conflict (commonly concurrent appends to `session_log.md` or lock files) it fails silently and leaves the rebase half-done. The local coord clone then stops syncing — locks AND shared Claude memory quietly stop reaching teammates — while everything looks fine.

On 2026-06-27 Shahab's coord clone was found 2209 commits behind origin with one junk local commit; fixed by catching the local clone up to origin (no shared-history rewrite). See [[duosync-shared-memory]].

**Why:** Silent error suppression hides a broken sync; the only visible symptom is that teammates stop seeing your updates.

**How to apply:** If sync seems off, check `git -C <coord> status` for a rebase in progress and `git rev-list --left-right --count origin/main...main`. Recover by `git rebase --abort` then, if the only local commits are disposable session/lock entries, `git reset --hard origin/main` and re-apply real work on top.

**RECURRED 2026-07-27 with a DIFFERENT root cause: a stale `.git/index.lock`.** A zero-byte `E:/Projects/VA-Dashboard-coord/.git/index.lock` dated 2026-07-24 22:59 (crashed/killed git, no process holding it) made EVERY hook `git add`/`commit` fail for 3 days. Symptoms: coord clone 87 commits behind origin, `amin.lock.json` stuck staged-and-modified, 25 `session_log.md` entries never committed, 3 memory files (io-lock, client-registry-multi-company, platform-operator-tier) never reaching the pool, and an unread inbox message from Shahab. The `duosync_pull()` guard from 2026-07-01 correctly surfaced "coord pull failed" but could not fix it, because the blocker was the index lock, not the rebase. Repaired in coord `1b20590`.

**RECURRED 2026-08-06 with a lock the guard does NOT cover: REF locks.** Two zero-progress files left by a git crash at 2026-08-05 13:26 wedged the clone for 21h: `.git/HEAD.lock` (0 bytes) and `.git/refs/heads/main.lock` (41 bytes, holding `5b0f9bf`). Every pull died with `fatal: update_ref failed for ref 'HEAD': cannot lock ref 'HEAD'`, clone fell 11 commits behind, and 27 `session_log.md` entries existed only locally. **`duosync_unwedge()` only deletes `index.lock`, so it cleaned nothing here** — and the two locks surface one at a time, so removing `HEAD.lock` just moves the error to `refs/heads/main.lock`. Repaired in coord `77760d4`; local `amin.lock.json` was correctly discarded (origin's copy was the same idle state with a newer timestamp).

**How to apply:** when the pull fails, do not stop at `index.lock` — run `find <coord>/.git -maxdepth 3 -name '*.lock' -exec ls -la {} \;` and check `tasklist | grep git`. Any `.lock` with no live git process and an old mtime is stale. Widening `duosync_unwedge()` to all three (`index.lock`, `HEAD.lock`, `refs/heads/main.lock`) is AGREED-WORTHWHILE but NOT DONE.

**Guard added 2026-07-27:** `duosync_unwedge()` in all four `duosync-{start,end}.sh` (both repos) deletes a coord `.git/index.lock` untouched for 15+ minutes before pulling (15 min = no live git op can still own it), and both hooks now end with a cause-agnostic health check: `git rev-list --count origin/main..HEAD` > 0 means a push silently failed, surfaced in the session-start context / stderr. Checking the END STATE beats trusting the silenced git calls.

**FIXED 2026-07-01 (recurred that day — coord was mid-rebase, 153 behind):** the hooks were hardened so this shouldn't wedge silently again. (1) All three `duosync-*.sh` (both repos) now route the coord pull through a `duosync_pull()` helper that `git rebase --abort`s on failure (clone left CLEAN, never stuck mid-rebase) and prints a `DuoSync WARNING:` to stderr; `duosync-start.sh` also surfaces the warning inside its session-start `{"context":...}` so it's visible. (2) coord `.gitattributes` sets `session_log.md` + `claude-memory/MEMORY.md` to `merge=union`, so concurrent appends auto-combine instead of conflicting (kills the #1 conflict source). Commits: dashboard hooks `7036a2c` on `dev`, coord `.gitattributes` `d075312` on main. Marketing hooks auto-commit to va-website. A failed pull now leaves the clone behind-but-clean (self-heals on next clean pull) instead of permanently wedged.
