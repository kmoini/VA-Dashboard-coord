---
name: duosync-shared-memory
description: How Claude memory is shared across the Marketing site, the Dashboard, and the suite workspace
metadata:
  type: project
---

Claude memory for the VoiceAccountant suite is a SINGLE shared pool, not per-project silos.

The canonical pool lives at `<DUOSYNC_COORD>/claude-memory/` in the coord repo (`github.com/kmoini/VA-Dashboard-coord`). The DuoSync hooks sync it into each machine's local Claude memory store:
- **Session start** (`duosync-start.sh`) pulls the coord repo, then runs `duosync-memory.sh pull` to merge the pool into this project's local store.
- **Session end** (`duosync-end.sh`) runs `duosync-memory.sh push` to merge the local store back into the pool, then the normal coord `git add/commit/push` ships it.

Consequences:
- Opening Claude as the **suite workspace**, **standalone Marketing**, or **standalone Dashboard** — on any teammate's machine — all see and update the same memory. There is no information gap between the workspace Claude and each project's Claude.
- Write new memories the normal way (a file per fact in the local store, plus an index line in `MEMORY.md`); they propagate to everyone on the next sync.

**Why:** The two projects (`voiceaccountant/` marketing site, `va-dashboard2/` Laravel dashboard) are developed together in the `voiceaccountant-suite.code-workspace` multi-root workspace; the team wanted one memory regardless of how Claude is launched.

**How to apply:** Treat memory as one pool. Don't try to keep Marketing-only or Dashboard-only memory silos. Merge is union + newest-wins per file; `MEMORY.md` lines are unioned, never clobbered. Deletions are NOT auto-propagated — remove a memory from the pool by hand if it's wrong.
