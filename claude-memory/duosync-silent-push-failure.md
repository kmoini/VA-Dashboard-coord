---
name: duosync-silent-push-failure
description: "DuoSync's memory sync silently no-op's in BOTH directions (push 2026-07-17, start-hook pull 2026-07-28) - recovered manually both times, root cause not pinned down"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 316a8d1f-1edb-4b47-a849-f2aab83110cc
  modified: 2026-07-28T17:54:22.322Z
---

Running `bash .claude/hooks/duosync-end.sh` (the normal session-end hook) completed with no
errors, but `duosync-memory.py push` did **not** actually copy several local memory files into
the shared pool (`C:/PROJECTS/VA-Dashboard-coord/claude-memory/`) — including files from *past*
sessions (`bank-reconciliation-feature.md`, `gemini-cost-overspend-investigation.md`,
`books-phase3-production-deploy.md`, etc.), not just the current one. Confirmed by checking the
pool directory directly after the hook ran: the files were missing.

Re-running the exact same push logic manually (`DUOSYNC_COORD=... PROJECT_ROOT=$(pwd) bash -c
'... python3 duosync-memory.py push'`) worked immediately and copied everything correctly. Tried
to isolate the `PROJECT_ROOT` computation (`$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." ... &&
pwd)` in `duosync-end.sh`) in a standalone repro — it resolved correctly every time, so the bug
didn't reproduce cleanly. Both `duosync-memory.sh` and `duosync-memory.py` swallow all
errors/exceptions silently (`2>/dev/null`, `except Exception: sys.exit(0)`) specifically so a
sync failure never breaks the calling hook — which is the right call defensively, but it also
means a real failure produces zero visible signal.

**Why:** all three DuoSync users (kamyar/amin/shahab) share the exact same hook scripts (they
live in the coord repo, not per-project) — if this silently fails for one person's session-end,
it plausibly fails for others too, meaning the shared pool can silently drift out of sync with
what any given person's Claude actually knows, with no error to notice.

**How to apply:** if a memory you know you saved doesn't show up for a teammate (or vice versa),
don't assume it's user error — check the pool directly (`ls
C:/PROJECTS/VA-Dashboard-coord/claude-memory/`) and if it's missing, re-run the push manually:
`DUOSYNC_COORD="C:/PROJECTS/VA-Dashboard-coord" PROJECT_ROOT="<project root>" bash -c 'source
<the python3-shim line from duosync-memory.sh>; python3
"C:/PROJECTS/VA-Dashboard-coord/duosync-memory.py" push'`, then `git add claude-memory && git
commit && git pull --rebase && git push` in the coord repo. Worth periodically spot-checking the
pool has recent content rather than trusting the hook silently succeeded.

**2026-07-28 — same failure, opposite direction (start-hook PULL).** The marketing session's
SessionStart hook demonstrably ran (it appended a `SESSION START` line and committed it to the
coord repo), yet the pool -> local merge at `duosync-start.sh:39` did not apply: the pool's
`tentpole-satellite-tools.md` (mtime 2026-07-27, the richer 07-19 content) never overwrote the
local 07-17 copy. `shutil.copy2` preserves mtimes, so an untouched local mtime is proof the
merge never copied, not just that it copied something old. Running the exact same wrapper by
hand worked instantly — again no clean repro. Ruled out: duplicate/misresolved project memory
dir (only one `e--Projects-voiceaccountant` exists) and a broken shim (`py -3` works; note
calling `duosync-memory.py` **directly** with `python3` fails on this box — the MS Store stub
intercepts it, so always go through `duosync-memory.sh`, which defines the `py -3` fallback).
The dashboard project's local store had likewise drifted to 42 files vs the pool's 63.

**How to apply (both directions):** treat the hooks as best-effort, not guaranteed. A quick
audit is `comm` on `ls *.md` between the pool and each project's store plus `diff -rq` for
content drift; then `bash "$DUOSYNC_COORD/duosync-memory.sh" pull|push` with `DUOSYNC_COORD` and
`PROJECT_ROOT` set, and commit/push the coord repo. Also check `git rev-list --count
origin/main..HEAD` in the coord repo — an unpushed session-start commit is the tell that a
silenced git call failed (there was one this session).
