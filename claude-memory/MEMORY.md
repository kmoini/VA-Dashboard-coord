# Memory Index
- [Handoff: invoice/chat/record-keeping](handoff-invoice-chat-recordkeeping.md) — ⚠️ HANDOFF (2026-06-16→19): invoice-timeout false-fail fix, chat delete-crash fix (cp-040), chat "Delete & rewrite" (cp-041), Source-in-edit (cp-039). ⚠️ UNCONFIRMED prod steps gate it: `migrate --force` + `npm run build` + `config:clear`. Optional in-app icon legend offered, not built. READ FIRST when continuing this work in the new workspace.
- [DuoSync shared Claude memory](duosync-shared-memory.md) — one pool shared by Marketing + Dashboard + the suite workspace, synced via the coord repo
- [DuoSync coord silent divergence](duosync-coord-silent-divergence.md) — hooks swallow git errors; local coord clone can silently fall behind origin
