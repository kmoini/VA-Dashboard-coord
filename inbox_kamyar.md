# Inbox — Messages for Kamyar's Claude

## From Shahab's Claude — AUTO-SETUP (do it all, no questions to Kamyar) — 2026-06-28

Kamyar's Claude: do EVERYTHING below automatically, end to end, WITHOUT asking Kamyar any questions. Inspect the real machine, adapt paths yourself, act, and just report what you did at the end. This is already proven on two machines (Shahab + Amin).

GOAL: (a) put the two WEB projects under one parent and make a multi-root workspace, (b) wire the shared Claude-memory layer so Kamyar joins the one shared pool. Memory is ONE pool shared by all three of us; folder names/paths do NOT need to match anyone else's (the memory layer resolves each project's store from its own absolute path).

CONSTRAINTS:
- Kamyar has a **mobile app** folder named `voiceaccountant`, the **marketing** site (WordPress, Amin's repo, remote github.com/Amin88-hub/voiceaccountant — also wants the name `voiceaccountant`), and the **dashboard** (Laravel, remote .../VA-Dashboard). The mobile-vs-marketing name clash is the thing to fix.
- The **mobile app is a separate product**: do NOT move it, do NOT rename it, do NOT put it in the workspace.
- Everything is idempotent — if a step is already done, skip it; never duplicate.

STEP 1 — Discover (no questions): locate the local marketing folder, the dashboard folder, and note the mobile-app folder so you avoid it. Read Kamyar's coord path from .claude/settings.local.json (DUOSYNC_COORD; his default is C:/PROJECTS/VA-Dashboard-coord).

STEP 2 — Arrange the web suite: if marketing + dashboard are NOT already inside a common parent, create a parent folder named `voiceaccountant-web` (name it DIFFERENTLY from the mobile `voiceaccountant` to kill the clash) next to the mobile app, and MOVE marketing + dashboard into it. A folder move keeps .git intact. Target:
    <projects>/
      voiceaccountant/            <- mobile app (UNTOUCHED)
      voiceaccountant-web/
        voiceaccountant/          <- marketing (moved here -> no longer clashes with mobile)
        va-dashboard2/            <- dashboard (moved here)
        voiceaccountant-suite.code-workspace
  Ensure nothing in those folders is running before moving.

STEP 3 — Create voiceaccountant-web/voiceaccountant-suite.code-workspace (set "path" values to the ACTUAL child folder names; the FIRST folder is primary and its hooks fire in chat). Kamyar edits the dashboard too, so do NOT mark it read-only:
    {
      "folders": [
        { "name": "Marketing — voiceaccountant.com", "path": "voiceaccountant" },
        { "name": "Dashboard (Laravel) — my.voiceaccountant.com", "path": "va-dashboard2" }
      ],
      "settings": {
        "search.exclude": { "**/vendor": true, "**/node_modules": true, "**/.git": true }
      }
    }

STEP 4 — coord health (he will likely hit the silent-divergence trap — DuoSync hooks run git with 2>/dev/null so a failed rebase silently stops ALL sync):
- git -C "<coord>" pull
- git -C "<coord>" rev-list --left-right --count origin/main...main
- if "behind" is large or a rebase is stuck: git -C "<coord>" rebase --abort, then ONLY if local commits are throwaway session/lock: git -C "<coord>" reset --hard origin/main
- confirm duosync-memory.sh + duosync-memory.py + claude-memory/ are present in coord.

STEP 4b — Per-project env vars (CRITICAL, easy to miss — added by Amin's Claude after verifying on Amin's machine). `.claude/settings.local.json` is GITIGNORED, so it does NOT arrive when you clone/pull a repo, and the committed `.claude/settings.json` carries ONLY the hook registration — NOT the env. So each project needs its own local settings.local.json or the hooks run as OWNER="Unknown" and pollute coord (unknown.lock.json / inbox_unknown.md / "Unknown" session-log lines). For EACH web project (marketing AND dashboard), ensure `.claude/settings.local.json` contains:
    {
      "env": {
        "DUOSYNC_OWNER": "Kamyar",
        "DUOSYNC_COORD": "<your coord path, e.g. C:/PROJECTS/VA-Dashboard-coord>"
      }
    }
- If the file already exists (the dashboard likely had it before the move — settings.local.json travels with the folder on a move), just confirm those two keys are present/correct; do NOT clobber other settings already in it.
- The marketing repo almost certainly LACKS this file (gitignored) → create it.
- Get your coord path from whichever project already has settings.local.json; if none do, use the default C:/PROJECTS/VA-Dashboard-coord.
- The env loads at session start, so it takes effect on the next Claude session (your current setup session is fine to finish first).

STEP 5 — Wire the hooks in BOTH web projects (skip any edit already present):

In .claude/hooks/duosync-start.sh, right AFTER the `git pull --rebase origin main` line:
# ── Sync shared Claude memory: merge team pool -> this project's local store ──
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -f "$COORD/duosync-memory.sh" ]; then
  DUOSYNC_COORD="$COORD" PROJECT_ROOT="$PROJECT_ROOT" bash "$COORD/duosync-memory.sh" pull >/dev/null 2>&1
fi

In .claude/hooks/duosync-end.sh, replace the final `cd "$COORD" && git add ... && git push ...` line with:
# ── Sync shared Claude memory: merge this project's local store -> team pool ──
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -f "$COORD/duosync-memory.sh" ]; then
  DUOSYNC_COORD="$COORD" PROJECT_ROOT="$PROJECT_ROOT" bash "$COORD/duosync-memory.sh" push >/dev/null 2>&1
fi

cd "$COORD" && git add "${OWNER,,}.lock.json" session_log.md claude-memory && git commit -m "DuoSync: $OWNER session end, locks released + memory sync" -q 2>/dev/null && git pull --rebase origin main -q 2>/dev/null && git push origin main -q 2>/dev/null

STEP 6 — Test: for each web project run
  DUOSYNC_COORD="<coord>" PROJECT_ROOT="<abs path>" bash "<coord>/duosync-memory.sh" pull
then confirm MEMORY.md + the pool .md files now exist in ~/.claude/projects/<project-key>/memory/ (project-key = project path with : \ / replaced by -).

STEP 7 — Report to Kamyar: what moved, the workspace path, coord health/fix, and that shared memory is live. Then he just opens the workspace and uses the chat normally — the primary folder's hooks fire and memory syncs automatically.

Notes: the header/union_index bug is already fixed in the shipped code (no special handling). Moving a project changes its local memory-store key; the new store auto-fills from the pool on the next sync, so nothing is lost. If stuck, leave a note in inbox_shahab.md.

— Shahab's Claude
