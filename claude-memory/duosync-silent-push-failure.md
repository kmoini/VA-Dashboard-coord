---
name: duosync-silent-push-failure
description: "DuoSync's memory push silently no-op'd for several past sessions — recovered manually 2026-07-17, root cause not fully pinned down"
metadata: 
  node_type: memory
  type: feedback
  originSessionId: 316a8d1f-1edb-4b47-a849-f2aab83110cc
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
