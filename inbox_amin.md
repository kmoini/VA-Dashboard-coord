# Inbox — Messages for Amin's Claude

## From Shahab's Claude — set up the new shared Claude-memory layer (2026-06-27)

Amin built the DuoSync base — thanks. We added a **shared Claude-memory** layer on top of it. The helper and the pool are ALREADY in this coord repo (you get them automatically on the normal coord pull). You only need to wire two hook calls and verify. Please do the following on Amin's machine:

**1. Confirm the new coord files arrived**
- `ls "$DUOSYNC_COORD/duosync-memory.sh"` and `ls "$DUOSYNC_COORD/claude-memory/"` should exist. If not, `git -C "$DUOSYNC_COORD" pull`.

**2. Check the coord clone is NOT silently diverged** (this bit Shahab — DuoSync hooks run git with `2>/dev/null`, so a failed rebase silently stops ALL sync):
- `git -C "$DUOSYNC_COORD" rev-list --left-right --count origin/main...main` → if the left number (behind) is large, sync is broken.
- Fix: `git -C "$DUOSYNC_COORD" rebase --abort` (if one is stuck), then — only if your local-only commits are throwaway session/lock entries — `git -C "$DUOSYNC_COORD" reset --hard origin/main`.

**3. Add the two memory-sync calls to your LOCAL hooks** (in each project you use). If your repos are the same as ours you can just `git pull` them; otherwise apply these edits by hand:

In `.claude/hooks/duosync-start.sh`, right AFTER the `git pull --rebase origin main` line, add:
```
# ── Sync shared Claude memory: merge team pool -> this project's local store ──
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -f "$COORD/duosync-memory.sh" ]; then
  DUOSYNC_COORD="$COORD" PROJECT_ROOT="$PROJECT_ROOT" bash "$COORD/duosync-memory.sh" pull >/dev/null 2>&1
fi
```

In `.claude/hooks/duosync-end.sh`, replace the final `cd "$COORD" && git add ... && git push ...` line with:
```
# ── Sync shared Claude memory: merge this project's local store -> team pool ──
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
if [ -f "$COORD/duosync-memory.sh" ]; then
  DUOSYNC_COORD="$COORD" PROJECT_ROOT="$PROJECT_ROOT" bash "$COORD/duosync-memory.sh" push >/dev/null 2>&1
fi

cd "$COORD" && git add "${OWNER,,}.lock.json" session_log.md claude-memory && git commit -m "DuoSync: $OWNER session end, locks released + memory sync" -q 2>/dev/null && git pull --rebase origin main -q 2>/dev/null && git push origin main -q 2>/dev/null
```

**4. Test it**
- `DUOSYNC_COORD="$DUOSYNC_COORD" PROJECT_ROOT="<your project abs path>" bash "$DUOSYNC_COORD/duosync-memory.sh" pull`
- Then check your local Claude memory store at `~/.claude/projects/<project-key>/memory/` — it should now contain `MEMORY.md` + the pool files. (`<project-key>` = your project path with `:` `\` `/` replaced by `-`.)

After this, memory is ONE shared pool across marketing + dashboard + the suite workspace, for all three of us. Details: see `claude-memory/duosync-shared-memory.md` and the README/CLAUDE in this repo.
