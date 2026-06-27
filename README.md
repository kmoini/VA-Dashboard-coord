# VA-Dashboard-coord

DuoSync coordination repository for the VA-Dashboard project.

## Collaborators
- **Kamyar** (kmoini) — `kamyar.lock.json`
- **Amin** — `amin.lock.json`
- **Shahab** (shahabarvin) — `shahab.lock.json`

## Files
| File | Purpose |
|------|---------|
| `kamyar.lock.json` | Kamyar's active file locks |
| `amin.lock.json` | Amin's active file locks |
| `shahab.lock.json` | Shahab's active file locks |
| `checkpoints.json` | Shared milestones log |
| `ACTIVE_WORK.md` | High-level work tracking |
| `session_log.md` | Session start/end audit trail |
| `inbox_kamyar.md` | Messages queued for Kamyar's Claude |
| `inbox_amin.md` | Messages queued for Amin's Claude |
| `inbox_shahab.md` | Messages queued for Shahab's Claude |
| `duosync-memory.sh` | Shared Claude-memory merge helper (pull/push), called by the hooks |
| `claude-memory/` | The single shared Claude memory pool for the whole suite |

## How it works
Each developer's Claude Code hooks automatically:
1. Lock files before editing them
2. Block edits if the other person has the file locked
3. Release locks when the session ends
4. Sync the shared Claude memory pool (`claude-memory/`) in at session start and out at session end

See `CLAUDE.md` for the full protocol.

## Shared Claude memory
`claude-memory/` is ONE pool shared by every project and every teammate. The VoiceAccountant
suite (`voiceaccountant-suite.code-workspace`) bundles the Marketing site and the Dashboard;
both — plus the combined workspace — read and write this same pool, so there is no memory gap
between them. `duosync-memory.sh` does pure file merges (union + newest-wins per fact file;
`MEMORY.md` index lines are unioned, never clobbered). The hooks own all git. Deletions are not
auto-propagated — remove a memory from `claude-memory/` by hand if it is wrong.
