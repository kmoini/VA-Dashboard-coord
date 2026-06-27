#!/usr/bin/env bash
# DuoSync shared Claude-memory file-merge. Lives in the coord repo so it is the
# single source of truth for every machine (it arrives via the normal coord git pull).
#
# PURE FILE OPERATIONS — no git, no network. The calling hook owns git:
#   duosync-start.sh : runs `git pull` on coord, then calls this with `pull`
#   duosync-end.sh   : calls this with `push`, then `git add claude-memory` + commit + push
#
# Usage: duosync-memory.sh <pull|push>
#   pull : merge the team pool  ->  this project's local Claude memory store
#   push : merge the local store ->  the team pool
#
# Env:
#   DUOSYNC_COORD : coord repo path (the shared pool lives at $DUOSYNC_COORD/claude-memory)
#   PROJECT_ROOT  : the project whose local Claude memory store should be synced
#
# Model: ONE shared pool. Merge is union + newest-wins per fact file; MEMORY.md
# index lines are unioned (never clobbered). Deletions are intentionally NOT
# propagated automatically — remove a memory in the pool by hand if needed.

# Windows fallback: 'python3' may be a non-functional MS Store stub. Use 'py -3'
# only when python3 doesn't actually work. No-op on Linux/Mac (real python3 present).
if ! python3 -c "print(1)" 2>/dev/null | grep -q 1; then python3() { py -3 "$@"; }; fi

set -u
DIR="${1:-pull}"
COORD="${DUOSYNC_COORD:-}"
[ -z "$COORD" ] && exit 0
[ -z "${PROJECT_ROOT:-}" ] && exit 0
POOL="${COORD}/claude-memory"
mkdir -p "$POOL"

DIR="$DIR" POOL="$POOL" PROJECT_ROOT="$PROJECT_ROOT" python3 -c "
import os, re, shutil

direction = os.environ['DIR']
pool = os.environ['POOL']
root = os.environ.get('PROJECT_ROOT', '')
home = os.path.expanduser('~')
base = os.path.join(home, '.claude', 'projects')

# ── Resolve the local Claude memory dir from PROJECT_ROOT ──
# Claude keys each project folder by its path with ':' '\\' '/' replaced by '-'.
# PROJECT_ROOT may arrive as '/d/Projects/...', 'd:/Projects/...' or 'd:\\Projects\\...'.
m = re.match(r'^/([a-zA-Z])/(.*)$', root)
win = (m.group(1) + ':/' + m.group(2)) if m else root
key = win.replace(':', '-').replace('\\\\', '-').replace('/', '-').rstrip('-')

mem = None
try:
    if os.path.isdir(os.path.join(base, key)):
        mem = os.path.join(base, key, 'memory')
    else:
        # Fallbacks: case-insensitive match, or any project folder ending in the basename
        bn = os.path.basename(win.rstrip('/\\\\')).lower()
        for d in os.listdir(base):
            if d.lower() == key.lower() or (bn and d.lower().endswith('-' + bn)):
                mem = os.path.join(base, d, 'memory')
                break
except Exception:
    pass
if not mem:
    mem = os.path.join(base, key, 'memory')

os.makedirs(mem, exist_ok=True)
os.makedirs(pool, exist_ok=True)


def union_index(dst, src):
    # Union MEMORY.md bullet lines: keep dst's header line, then append every
    # unique (stripped) line from dst and src in order. Never loses a teammate's entry.
    def read_lines(p):
        try:
            with open(p, encoding='utf-8') as f:
                return f.read().splitlines()
        except Exception:
            return []
    a, b = read_lines(dst), read_lines(src)
    header = (a or b or [''])[0]
    out, seen = [header], {header.strip()}
    for line in a[1:] + b[1:]:
        s = line.strip()
        if s and s not in seen:
            out.append(line)
            seen.add(s)
    with open(dst, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out) + '\n')


def merge(src, dst):
    if not os.path.isdir(src):
        return
    os.makedirs(dst, exist_ok=True)
    for f in os.listdir(src):
        sp = os.path.join(src, f)
        if not os.path.isfile(sp):
            continue
        dp = os.path.join(dst, f)
        if f == 'MEMORY.md' and os.path.isfile(dp):
            union_index(dp, sp)
        elif (not os.path.exists(dp)) or os.path.getmtime(sp) > os.path.getmtime(dp):
            shutil.copy2(sp, dp)


if direction == 'pull':
    merge(pool, mem)
elif direction == 'push':
    merge(mem, pool)
" 2>/dev/null

exit 0
