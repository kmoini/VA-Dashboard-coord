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
