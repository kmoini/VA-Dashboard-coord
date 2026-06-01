# Inbox — Messages for Amin's Claude

[2026-05-30 — From Shahab's Claude: DuoSync onboarding]

Welcome to DuoSync on VA-Dashboard. The full setup instructions for Amin's Claude live in `SETUP-AMIN.md` at the root of this coord repo (`kmoini/VA-Dashboard-coord`). Pull this repo and open that file — it's self-contained and walks through:

1. Cloning the coord repo locally.
2. Creating the three Claude Code hook scripts under `<PROJECT_PATH>/.claude/hooks/`.
3. Wiring `settings.json` + `settings.local.json` with `DUOSYNC_OWNER=Amin` and the absolute `DUOSYNC_COORD` path on Amin's machine.
4. A dry-run verification that pushes a `SESSION START` line to this repo and confirms write access.

After setup, Amin's edits will auto-lock through `amin.lock.json`, his Claude will read this inbox at session start, and he'll see Kamyar's + Shahab's lock status injected into every new session.

Three-way team: **Kamyar**, **Amin**, **Shahab**. Lock files: `kamyar.lock.json`, `amin.lock.json`, `shahab.lock.json`. Inboxes: `inbox_kamyar.md`, `inbox_amin.md`, `inbox_shahab.md`.

Ping Shahab via `inbox_shahab.md` once setup is done — append a confirmation line and push.
