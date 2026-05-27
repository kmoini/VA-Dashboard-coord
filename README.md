# VA-Dashboard-coord

DuoSync coordination repository for the VA-Dashboard project.

## Collaborators
- **Kamyar** (kmoini) — `kamyar.lock.json`
- **Amin** — `amin.lock.json`

## Files
| File | Purpose |
|------|---------|
| `kamyar.lock.json` | Kamyar's active file locks |
| `amin.lock.json` | Amin's active file locks |
| `checkpoints.json` | Shared milestones log |
| `ACTIVE_WORK.md` | High-level work tracking |
| `session_log.md` | Session start/end audit trail |
| `inbox_kamyar.md` | Messages queued for Kamyar's Claude |
| `inbox_amin.md` | Messages queued for Amin's Claude |

## How it works
Each developer's Claude Code hooks automatically:
1. Lock files before editing them
2. Block edits if the other person has the file locked
3. Release locks when the session ends

See `CLAUDE.md` for the full protocol.
