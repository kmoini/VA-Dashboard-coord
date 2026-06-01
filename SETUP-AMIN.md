# DuoSync setup — instructions for Amin's Claude

> این فایل برای Claude امین نوشته شده. امین این رو به Claude خودش می‌ده و Claude مرحله به مرحله انجام می‌ده. هیچ مرحله‌ای رو نباید skip بشه.

---

## What this sets up

DuoSync is the three-way coordination system used on `VA-Dashboard`. It runs as three Claude Code hooks (SessionStart, PreToolUse, Stop) that auto-pull a small coordination repo (`kmoini/VA-Dashboard-coord`), record file locks, deliver inbox messages between teammates, and push the state back at the end of every turn.

After this setup Amin's Claude will:

- Read `inbox_amin.md` at session start (messages from Kamyar or Shahab) and clear it.
- Lock every file Amin edits in `amin.lock.json` so the other two see it.
- Refuse to edit a file Kamyar or Shahab already has locked.
- Release locks + log `SESSION END` when the turn ends.

Active teammates: **Kamyar**, **Amin**, **Shahab**.

---

## Prerequisites — verify before starting

Amin's Claude must confirm each of these. If any fail, STOP and tell Amin.

1. **Bash 4+** — `bash --version` shows `4.x` or higher. On Windows this is Git Bash.
2. **Python 3** — `python3 --version` works. (On Windows the launcher `py -3` is acceptable; if so, alias it inside the hook scripts.)
3. **Git** + GitHub write access to **both** repos:
   - `github.com/Amin88-hub/VA-Dashboard` (Amin's upstream)
   - `github.com/kmoini/VA-Dashboard-coord` (the coord repo — Amin must have write access; otherwise every hook push fails silently)
   - Test: `git ls-remote https://github.com/kmoini/VA-Dashboard-coord.git HEAD` returns a SHA.
4. **`Amin88-hub/VA-Dashboard` already cloned locally.** Note its absolute path — call it `PROJECT_PATH`. Example: `C:/PROJECTS/VA-Dashboard` or `/home/amin/VA-Dashboard`.

---

## Step 1 — Clone the coord repo

Decide on a `COORD_PATH`. Recommended: a sibling of `PROJECT_PATH`. Example: if `PROJECT_PATH=C:/PROJECTS/VA-Dashboard` then `COORD_PATH=C:/PROJECTS/VA-Dashboard-coord`.

```bash
git clone https://github.com/kmoini/VA-Dashboard-coord.git "<COORD_PATH>"
```

Verify: `ls "<COORD_PATH>"` shows `amin.lock.json`, `kamyar.lock.json`, `shahab.lock.json`, `inbox_amin.md`, `session_log.md`, `CLAUDE.md`, etc.

---

## Step 2 — Create the three hook scripts

All three files go into `<PROJECT_PATH>/.claude/hooks/`. Create the directory if needed.

> **Important:** the line `OWNER="${DUOSYNC_OWNER:-Unknown}"` and `COORD="${DUOSYNC_COORD:-C:/PROJECTS/VA-Dashboard-coord}"` mean the hooks read these from environment. Step 4 sets them per-machine via `settings.local.json`. The hardcoded defaults are only fallbacks.

### `<PROJECT_PATH>/.claude/hooks/duosync-start.sh`

```bash
#!/usr/bin/env bash
OWNER="${DUOSYNC_OWNER:-Unknown}"
COORD="${DUOSYNC_COORD:-C:/PROJECTS/VA-Dashboard-coord}"
ALL_OWNERS=(kamyar amin shahab)
MY_INBOX="${COORD}/inbox_${OWNER,,}.md"

cd "$COORD" && git pull --rebase origin main -q 2>/dev/null

INBOX_MSG=""
if [ -f "$MY_INBOX" ] && [ -s "$MY_INBOX" ]; then
  CONTENT=$(tail -n +2 "$MY_INBOX" | tr -d '[:space:]')
  if [ -n "$CONTENT" ]; then
    INBOX_MSG=$(cat "$MY_INBOX")
    echo "# Inbox — Messages for ${OWNER}'s Claude" > "$MY_INBOX"
    cd "$COORD" && git add "inbox_${OWNER,,}.md" && git commit -m "DuoSync: $OWNER read inbox, clearing" -q 2>/dev/null && git push origin main -q 2>/dev/null
  fi
fi

OTHER_STATUS=""
for OTHER in "${ALL_OWNERS[@]}"; do
  [ "$OTHER" = "${OWNER,,}" ] && continue
  LINE=$(python3 -c "
import json
try:
    with open('$COORD/${OTHER}.lock.json') as f:
        d = json.load(f)
    files = d.get('locked_files', [])
    status = d.get('status', 'idle')
    owner = '${OTHER}'.capitalize()
    msg = f'{owner} is {status}'
    if files:
        msg += ' - locked: ' + ', '.join(files)
    else:
        msg += ' - no files locked'
    print(msg)
except FileNotFoundError:
    print('${OTHER}'.capitalize() + ' has no lock file yet')
except Exception as e:
    print('Could not read ${OTHER} lock file: ' + str(e))
" 2>/dev/null)
  OTHER_STATUS="${OTHER_STATUS}${LINE}\n"
done

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "${TIMESTAMP} | ${OWNER} | SESSION START" >> "$COORD/session_log.md"
cd "$COORD" && git add session_log.md && git commit -m "DuoSync: $OWNER session start" -q 2>/dev/null && git push origin main -q 2>/dev/null

if [ -n "$INBOX_MSG" ]; then
  printf '{"context": "INBOX MESSAGE:\n%s\n\nDuoSync status -\n%b"}\n' "$INBOX_MSG" "$OTHER_STATUS"
else
  printf '{"context": "DuoSync status -\n%b"}\n' "$OTHER_STATUS"
fi
```

### `<PROJECT_PATH>/.claude/hooks/duosync-prelock.sh`

```bash
#!/usr/bin/env bash
OWNER="${DUOSYNC_OWNER:-Unknown}"
COORD="${DUOSYNC_COORD:-C:/PROJECTS/VA-Dashboard-coord}"
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." 2>/dev/null && pwd)"
ALL_OWNERS=(kamyar amin shahab)
MY_LOCK="${COORD}/${OWNER,,}.lock.json"
STALE_HOURS=8

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | python3 -c "
import json, sys
try:
    d = json.load(sys.stdin)
    fp = d.get('tool_input', {}).get('file_path', '')
    print(fp)
except:
    print('')
" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0
[[ "$FILE_PATH" == *"VA-Dashboard-coord"* ]] && exit 0

cd "$COORD" && git pull --rebase origin main -q 2>/dev/null

MY_INBOX="${COORD}/inbox_${OWNER,,}.md"
if [ -f "$MY_INBOX" ]; then
  INBOX_CONTENT=$(tail -n +2 "$MY_INBOX" | tr -d '[:space:]')
  if [ -n "$INBOX_CONTENT" ]; then
    INBOX_MSG=$(cat "$MY_INBOX")
    echo "# Inbox — Messages for ${OWNER}'s Claude" > "$MY_INBOX"
    cd "$COORD" && git add "inbox_${OWNER,,}.md" && git commit -m "DuoSync: $OWNER read inbox mid-session" -q 2>/dev/null && git push origin main -q 2>/dev/null
    printf '{"context": "INBOX MESSAGE (delivered mid-session):\n%s"}\n' "$INBOX_MSG" >&2
  fi
fi

REL=$(FILE_PATH="$FILE_PATH" PROJECT_ROOT="$PROJECT_ROOT" python3 -c "
import os
fp = os.environ.get('FILE_PATH', '').replace('\\\\', '/')
root = os.environ.get('PROJECT_ROOT', '').replace('\\\\', '/')
try:
    rel = os.path.relpath(fp, root) if root else fp
    rel = rel.replace('\\\\', '/')
    if rel.startswith('..') or os.path.isabs(rel):
        raise ValueError
except Exception:
    base = os.path.basename(root.rstrip('/')) if root else ''
    if base:
        needle = ('/' + base + '/').lower()
        i = fp.lower().rfind(needle)
        rel = fp[i + len(needle):] if i >= 0 else fp
    else:
        rel = fp
print(rel)
" 2>/dev/null || echo "$FILE_PATH")

BLOCKER=""
for OTHER in "${ALL_OWNERS[@]}"; do
  [ "$OTHER" = "${OWNER,,}" ] && continue
  OTHER_LOCK="${COORD}/${OTHER}.lock.json"
  [ ! -f "$OTHER_LOCK" ] && continue

  OTHER_LOCK_PATH="$OTHER_LOCK" OTHER_NAME="$OTHER" STALE_HOURS="$STALE_HOURS" python3 -c "
import json, datetime, os, sys
stale_hours = int(os.environ['STALE_HOURS'])
path = os.environ['OTHER_LOCK_PATH']
other = os.environ['OTHER_NAME']
try:
    with open(path) as f:
        d = json.load(f)
    files = d.get('locked_files', [])
    updated_at = d.get('updated_at', '')
    if not files or not updated_at:
        sys.exit(0)
    last = datetime.datetime.strptime(updated_at, '%Y-%m-%dT%H:%M:%SZ')
    age_hours = (datetime.datetime.utcnow() - last).total_seconds() / 3600
    if age_hours >= stale_hours:
        print(f'STALE: {other} lock is {age_hours:.1f}h old - clearing as orphaned session')
        d['locked_files'] = []
        d['status'] = 'idle'
        d['updated_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
        with open(path, 'w') as f:
            json.dump(d, f, indent=2)
except Exception:
    pass
" 2>/dev/null | while read -r line; do
    if [[ "$line" == STALE:* ]]; then
      cd "$COORD" && git add "${OTHER}.lock.json" && git commit -m "DuoSync: auto-clear stale ${OTHER} lock (>${STALE_HOURS}h old)" -q 2>/dev/null && git push origin main -q 2>/dev/null
    fi
  done

  LOCKED=$(OTHER_LOCK_PATH="$OTHER_LOCK" REL="$REL" python3 -c "
import json, os
try:
    with open(os.environ['OTHER_LOCK_PATH']) as f:
        d = json.load(f)
    files = d.get('locked_files', [])
    rel = os.environ['REL']
    for f in files:
        f_norm = f.replace('\\\\', '/')
        if rel.endswith(f_norm) or f_norm.endswith(rel):
            print('yes')
            break
    else:
        print('no')
except:
    print('no')
" 2>/dev/null || echo "no")

  if [ "$LOCKED" = "yes" ]; then
    BLOCKER=$(echo "$OTHER" | python3 -c "import sys; print(sys.stdin.read().strip().capitalize())")
    break
  fi
done

if [ -n "$BLOCKER" ]; then
  printf '{"decision":"block","reason":"DUOSYNC CONFLICT: %s has %s locked. Pull coord repo to see their status, then coordinate before editing."}\n' "$BLOCKER" "$REL"
  exit 2
fi

if [ ! -f "$MY_LOCK" ]; then
  echo '{"owner": "'"$OWNER"'", "locked_files": [], "status": "idle", "task": "", "updated_at": ""}' > "$MY_LOCK"
fi
MY_LOCK_PATH="$MY_LOCK" REL="$REL" python3 -c "
import json, datetime, os
try:
    path = os.environ['MY_LOCK_PATH']
    rel = os.environ['REL']
    with open(path) as f:
        d = json.load(f)
    files = d.get('locked_files', [])
    if rel not in files:
        files.append(rel)
    d['locked_files'] = files
    d['status'] = 'active'
    d['updated_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    with open(path, 'w') as f:
        json.dump(d, f, indent=2)
except Exception as e:
    import sys; print('Lock write failed: ' + str(e), file=sys.stderr)
" 2>/dev/null

cd "$COORD" && git add "${OWNER,,}.lock.json" && git commit -m "DuoSync: $OWNER locked $REL" -q 2>/dev/null && git push origin main -q 2>/dev/null

exit 0
```

### `<PROJECT_PATH>/.claude/hooks/duosync-end.sh`

```bash
#!/usr/bin/env bash
OWNER="${DUOSYNC_OWNER:-Unknown}"
COORD="${DUOSYNC_COORD:-C:/PROJECTS/VA-Dashboard-coord}"
MY_LOCK="${COORD}/${OWNER,,}.lock.json"

cd "$COORD" && git pull --rebase origin main -q 2>/dev/null

if [ ! -f "$MY_LOCK" ]; then
  echo '{"owner": "'"$OWNER"'", "locked_files": [], "status": "idle", "task": "", "updated_at": ""}' > "$MY_LOCK"
fi

MY_LOCK_PATH="$MY_LOCK" python3 -c "
import json, datetime, os
try:
    path = os.environ['MY_LOCK_PATH']
    with open(path) as f:
        d = json.load(f)
    d['locked_files'] = []
    d['status'] = 'idle'
    d['updated_at'] = datetime.datetime.utcnow().strftime('%Y-%m-%dT%H:%M:%SZ')
    with open(path, 'w') as f:
        json.dump(d, f, indent=2)
except Exception as e:
    import sys; print('Lock clear failed: ' + str(e), file=sys.stderr)
"

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
echo "${TIMESTAMP} | ${OWNER} | SESSION END" >> "$COORD/session_log.md"

cd "$COORD" && git add "${OWNER,,}.lock.json" session_log.md && git commit -m "DuoSync: $OWNER session end, locks released" -q 2>/dev/null && git push origin main -q 2>/dev/null
```

Make all three executable (Linux/Mac/Git Bash on Windows):

```bash
chmod +x "<PROJECT_PATH>/.claude/hooks/"duosync-*.sh
```

---

## Step 3 — Wire up `settings.json`

Create `<PROJECT_PATH>/.claude/settings.json` with the hook bindings:

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/duosync-start.sh", "timeout": 15 }
        ]
      }
    ],
    "PreToolUse": [
      {
        "matcher": "Edit",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/duosync-prelock.sh", "timeout": 15 }
        ]
      },
      {
        "matcher": "Write",
        "hooks": [
          { "type": "command", "command": ".claude/hooks/duosync-prelock.sh", "timeout": 15 }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          { "type": "command", "command": ".claude/hooks/duosync-end.sh", "timeout": 15 }
        ]
      }
    ]
  }
}
```

---

## Step 4 — Per-machine config in `settings.local.json`

Create `<PROJECT_PATH>/.claude/settings.local.json`. This file is per-developer and tells Amin's hooks his owner name + where coord lives on his disk.

```json
{
  "env": {
    "DUOSYNC_OWNER": "Amin",
    "DUOSYNC_COORD": "<COORD_PATH>"
  }
}
```

Replace `<COORD_PATH>` with the absolute path Amin chose in Step 1. Use forward slashes even on Windows (e.g. `C:/PROJECTS/VA-Dashboard-coord`).

> The owner string MUST be exactly `Amin` (capital A, no quotes around it inside the value beyond the JSON quoting). The hooks lower-case it to find `amin.lock.json` and `inbox_amin.md`, which already exist in coord.

---

## Step 5 — Verify

Two checks, in order:

### 5a. Dry-run the start hook

```bash
DUOSYNC_OWNER="Amin" DUOSYNC_COORD="<COORD_PATH>" \
  bash "<PROJECT_PATH>/.claude/hooks/duosync-start.sh"
```

Expected output is a single line of JSON of the form:

```
{"context": "DuoSync status -\nKamyar is idle - no files locked\nShahab is idle - no files locked\n"}
```

(If there are pending messages in `inbox_amin.md`, they'll appear prefixed with `INBOX MESSAGE:` instead.)

Also: a new commit `DuoSync: Amin session start` should land on `kmoini/VA-Dashboard-coord:main`. Confirm with:

```bash
cd "<COORD_PATH>" && git log -1 --oneline
```

If the push silently fails (no new commit on GitHub), Amin's git credentials don't have write access to the coord repo. Stop and fix that before continuing.

### 5b. Restart Claude

Hooks are loaded at session start. Exit the current Claude session (`/exit`) and start a new one inside `<PROJECT_PATH>`. The SessionStart hook will now fire automatically — Amin's Claude should receive context like `DuoSync status — Kamyar is idle, Shahab is idle` as part of the new session's first message.

---

## How DuoSync works in practice (for Amin to know)

- **Before any Edit/Write**, the prelock hook runs. It refuses to edit a file Kamyar or Shahab has locked, otherwise records the file in `amin.lock.json` and pushes.
- **Stale locks** (older than 8 hours) get auto-cleared the next time someone else tries to edit. This recovers from sessions that crashed without running the end hook.
- **End of every turn**, the end hook clears `amin.lock.json` and logs `SESSION END`. So locks are short-lived — they only exist for the duration of one Claude turn (one user message → response cycle).
- **Inbox messages**: to send Shahab a note, append to `inbox_shahab.md` in the coord repo and push. Same for Kamyar. Their Claude will read + clear it at their next session start (or mid-session if their prelock hook fires).

---

## Troubleshooting

| Symptom | Diagnosis |
|---|---|
| Hook output has `OWNER=Unknown` | `DUOSYNC_OWNER` env var isn't reaching the hook — settings.local.json missing or malformed. |
| Hook prints `Could not read X lock file` | Wrong `DUOSYNC_COORD` path. Verify the directory exists and has `*.lock.json` files. |
| No new commit on GitHub after a turn | Git can't push — bad credentials or no write access on `kmoini/VA-Dashboard-coord`. |
| `bash: ${OWNER,,}` syntax error | Bash version is older than 4. Upgrade Git Bash. |
| `python3: command not found` | On Windows, install Python and ensure `python3` is on PATH (not just `py`). |
| Locks not respected — Amin can edit a file Shahab has locked | The other lock file `shahab.lock.json` doesn't exist or has stale schema. Pull coord, inspect contents. |

---

## What NOT to do

- Don't edit `.lock.json` files by hand. The hooks own them.
- Don't push to the coord repo's `main` branch with merge commits — the hooks always push tiny atomic commits, and rebasing them onto a merge will spam the log.
- Don't change `DUOSYNC_OWNER` between sessions. Keep it `Amin` permanently — otherwise inboxes and locks split across two identities.
- Don't commit `settings.local.json` to the project repo. It's per-machine; the project repo's `.gitignore` already excludes the whole `.claude/` directory.
