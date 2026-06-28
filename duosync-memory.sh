#!/usr/bin/env bash
# DuoSync shared Claude-memory file-merge — thin wrapper around duosync-memory.py.
# Lives in the coord repo (single source of truth; arrives via the normal coord pull).
#
# PURE FILE OPERATIONS — no git, no network. The calling hook owns git:
#   duosync-start.sh : runs `git pull` on coord, then calls this with `pull`
#   duosync-end.sh   : calls this with `push`, then `git add claude-memory` + commit + push
#
# Usage: duosync-memory.sh <pull|push>
#   pull : merge the team pool   -> this project's local Claude memory store
#   push : merge the local store -> the team pool
#
# Env:
#   DUOSYNC_COORD : coord repo path (the shared pool lives at $DUOSYNC_COORD/claude-memory)
#   PROJECT_ROOT  : the project whose local Claude memory store should be synced
#
# The merge logic lives in duosync-memory.py (a real file, not an inline `-c` string)
# so it is immune to bash quoting pitfalls.

# Windows fallback: 'python3' may be a non-functional MS Store stub. Use 'py -3'
# only when python3 doesn't actually work. No-op on Linux/Mac (real python3 present).
if ! python3 -c "print(1)" 2>/dev/null | grep -q 1; then python3() { py -3 "$@"; }; fi

set -u
DIR="${1:-pull}"
PYFILE="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)/duosync-memory.py"
[ -f "$PYFILE" ] || exit 0

python3 "$PYFILE" "$DIR" 2>/dev/null
exit 0
