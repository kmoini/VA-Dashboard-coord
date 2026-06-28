#!/usr/bin/env python3
"""DuoSync shared Claude-memory file-merge (pure file ops, no git/network).

Called by the DuoSync hooks via duosync-memory.sh:
  pull : merge the team pool   -> this project's local Claude memory store
  push : merge the local store -> the team pool

Env:
  DUOSYNC_COORD : coord repo path (pool lives at $DUOSYNC_COORD/claude-memory)
  PROJECT_ROOT  : the project whose local Claude memory store to sync

Model: ONE shared pool. Per-file union + newest-wins. MEMORY.md index lines are
unioned (never clobbered): a leading '# ...' header is pinned to the top if present,
but a headerless MEMORY.md still keeps every entry, including line 0.

NOTE: this logic used to live inline in a `python3 -c "..."` block inside the .sh.
That coupling made it fragile to bash quoting (backslash runs, backticks, quotes).
Keep it here as a real .py file; the .sh is now a thin wrapper.
"""
import os
import re
import sys
import shutil


def resolve_memory_dir(root):
    """Map a project root path to its local Claude memory dir.

    Claude keys each project folder under ~/.claude/projects/<key>/ where <key> is
    the project path with ':' '\\' '/' replaced by '-'. PROJECT_ROOT may arrive as
    '/d/Projects/...', 'd:/Projects/...' or 'd:\\Projects\\...'.
    """
    home = os.path.expanduser('~')
    base = os.path.join(home, '.claude', 'projects')
    m = re.match(r'^/([a-zA-Z])/(.*)$', root)
    win = (m.group(1) + ':/' + m.group(2)) if m else root
    key = win.replace(':', '-').replace('\\', '-').replace('/', '-').rstrip('-')
    try:
        if os.path.isdir(os.path.join(base, key)):
            return os.path.join(base, key, 'memory')
        # Fallbacks: case-insensitive match, or any project folder ending in the basename
        bn = os.path.basename(win.rstrip('/\\')).lower()
        for d in os.listdir(base):
            if d.lower() == key.lower() or (bn and d.lower().endswith('-' + bn)):
                return os.path.join(base, d, 'memory')
    except OSError:
        pass
    return os.path.join(base, key, 'memory')


def union_index(dst, src):
    """Union two MEMORY.md index files without ever losing an entry.

    If a file starts with a markdown header ('# ...') it is pinned to the top;
    otherwise every line (including line 0) is treated as content. Robust whether or
    not a header exists -- a headerless MEMORY.md no longer silently drops its first
    entry (the regression Amin caught: the old code skipped line 0 of both files).
    """
    def read_lines(p):
        try:
            with open(p, encoding='utf-8') as f:
                return f.read().splitlines()
        except OSError:
            return []

    a, b = read_lines(dst), read_lines(src)
    out, seen = [], set()
    # Pin a leading markdown header (prefer dst's, then src's) only if it really is one.
    for lines in (a, b):
        if lines and lines[0].lstrip().startswith('#'):
            out.append(lines[0])
            seen.add(lines[0].strip())
            break
    # Union all lines; any line already pinned as the header is skipped via seen.
    for line in a + b:
        s = line.strip()
        if s and s not in seen:
            out.append(line)
            seen.add(s)
    with open(dst, 'w', encoding='utf-8') as f:
        f.write('\n'.join(out) + '\n')


def merge(src, dst):
    """Copy src -> dst: per-file newest-wins; MEMORY.md is unioned, never clobbered."""
    if not os.path.isdir(src):
        return
    os.makedirs(dst, exist_ok=True)
    for name in os.listdir(src):
        sp = os.path.join(src, name)
        if not os.path.isfile(sp):
            continue
        dp = os.path.join(dst, name)
        if name == 'MEMORY.md' and os.path.isfile(dp):
            union_index(dp, sp)
        elif (not os.path.exists(dp)) or os.path.getmtime(sp) > os.path.getmtime(dp):
            shutil.copy2(sp, dp)


def main():
    direction = (sys.argv[1] if len(sys.argv) > 1 else 'pull').strip()
    coord = os.environ.get('DUOSYNC_COORD', '')
    root = os.environ.get('PROJECT_ROOT', '')
    if not coord or not root:
        return 0
    pool = os.path.join(coord, 'claude-memory')
    mem = resolve_memory_dir(root)
    os.makedirs(mem, exist_ok=True)
    os.makedirs(pool, exist_ok=True)
    if direction == 'pull':
        merge(pool, mem)
    elif direction == 'push':
        merge(mem, pool)
    return 0


if __name__ == '__main__':
    try:
        sys.exit(main())
    except Exception:
        # Never let a sync error break the calling hook.
        sys.exit(0)
