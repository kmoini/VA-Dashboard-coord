# DuoSync Protocol — VA-Dashboard

This repo coordinates real-time collaboration between Kamyar, Amin, and Shahab on VA-Dashboard.

## Quick reference
- Main project: `D:/projects/VA-Dashboard` (Kamyar) / `D:/Projects/va-dashboard2` (Shahab) / wherever Amin clones it
- Coord repo: `C:/PROJECTS/VA-Dashboard-coord` (Kamyar/Amin default) / `D:/Projects/VA-Dashboard-coord` (Shahab — set via `DUOSYNC_COORD` env in his `.claude/settings.local.json`)
- Lock files: `kamyar.lock.json`, `amin.lock.json`, `shahab.lock.json`
- Inboxes: `inbox_kamyar.md`, `inbox_amin.md`, `inbox_shahab.md`

## Rules
1. Never edit a file that appears in the other person's lock file
2. Update ACTIVE_WORK.md when switching areas of work
3. Leave inbox messages before ending your session if you need to communicate
4. Locks are automatically cleared at session end — stale locks (>8h) are auto-cleared

## Sending a message to the other person
Edit `inbox_{name}.md` and push. Their Claude will read it at next session start.

## Shared Claude memory
- `claude-memory/` is a SINGLE memory pool shared by every project and teammate. The
  VoiceAccountant suite (`voiceaccountant-suite.code-workspace`) opens the Marketing site
  (`voiceaccountant/`) and the Dashboard (`va-dashboard2/`) together; both projects and the
  combined workspace sync against this one pool, so memory is identical everywhere.
- `duosync-start.sh` pulls the coord repo, then runs `duosync-memory.sh pull` to merge the
  pool into the machine's local Claude memory store.
- `duosync-end.sh` runs `duosync-memory.sh push` to merge the local store back into the pool,
  then commits and pushes `claude-memory/` along with the lock/session files.
- Running DuoSync in the **suite workspace** syncs the shared pool that serves both projects;
  running it inside a **single project** syncs that project (which still reads/writes the same
  shared pool). Merge is union + newest-wins per file; `MEMORY.md` lines are unioned.
- Deletions are not auto-propagated; remove a memory from `claude-memory/` by hand if needed.
