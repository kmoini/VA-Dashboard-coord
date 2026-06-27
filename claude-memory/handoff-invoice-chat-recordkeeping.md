---
name: handoff-invoice-chat-recordkeeping
description: "Session handoff (2026-06-16→19): invoice-timeout false-fail fix, chat delete-crash fix, chat Delete & rewrite, Record Keeping icon legend — plus the UNRUN prod steps that gate it all."
metadata: 
  node_type: memory
  type: project
  originSessionId: a43733dc-6ca6-4387-a69f-b41cee359bb7
---

Handoff from a dashboard chat session (work spans 2026-06-16 → 06-19). Continued in a new suite workspace — this memory syncs there via DuoSync ([[duosync-shared-memory]]). All code is committed + pushed to `origin/main`; the items below are the *why* + the open follow-ups.

## ⚠️ MOST IMPORTANT — prod manual steps that were NEVER confirmed run
The deploy webhook only does `git pull`. These three were told to Amin but not confirmed done on `my.voiceaccountant.com` — until they run, the shipped code is half-live:
- `php artisan migrate --force` — applies the chat-delete-crash constraint fix (cp-040). **Without it, deleting a chat message still crashes in prod.**
- `npm run build` — renders the frontend changes: chat **Delete & rewrite** (cp-041), **Source in the edit panel** (cp-039, sibling), ClientSwitcher density (cp-037).
- `php artisan config:clear` — activates the invoice `write_timeout` (10s→25s) from `config/mobile.php`.
First thing in the new workspace: verify these ran (check the constraint includes `ClientMessage`, and that prod assets are rebuilt).

## What shipped this session
1. **Invoice "app message didn't go through" false alarm — FIXED.** `send-message-to-user` n8n does real work; a 10s `write_timeout` made slow-but-successful calls look failed (client got the msg, dashboard showed failure). Fix in `ChatService::send()`: a `MobileApiException` with `status === null` (no HTTP response = timeout/dropped conn) is now marked optimistically `sent` (Idempotency-Key makes a later Resend safe); a real HTTP error (4xx/5xx/429) still marks `failed`. `write_timeout` 10→25s (`MOBILE_WRITE_TIMEOUT`). `MobileMessageProjector` adopts the id-less local outbound when mobile echoes it back (no duplicate bubble). Landed in origin/main via the repo's auto-commit.
2. **Chat message delete crash — FIXED (cp-040).** `activity_logs` CHECK constraint `chk_activity_logs_entity_type` never whitelisted `'ClientMessage'`, so retract/edit threw SQLSTATE 23514. Migration `2026_06_16_000001_expand_activity_log_entity_type_for_chat.php` adds `'ClientMessage'` + `'ReferralAccepted'` (the latter had the same latent crash in ReferralController). Pattern reminder: querying the LIVE constraint is the only reliable source (see CLAUDE.md activity-log note).
3. **Chat "Delete & rewrite" — BUILT (cp-041).** A delivered (`sent`) message can't be edited in place (push already on the client's phone; one-way mobile sync would revert a dashboard edit). So in `MessagesChatStudio.tsx` the pencil on a sent text message now retracts the original (logged) and loads its text into the composer (focused, caret at end) to correct + resend. Inline edit unchanged for pending/failed.
4. **ClientSwitcher density (cp-037)** + **Source shown in the Record Keeping edit panel (cp-039, built by a DuoSync sibling)**.

## Open / offered, NOT built
- **In-app Record Keeping icon legend** — I gave Amin a full icon reference (Source 🤖/📱/👤; Activity ✨New/✏️Edited/⚡Overridden; Status dots; Risk flags; toolbar/viewer/voice icons — all in `Transactions/Index.jsx`, `Components/TransactionsTable.jsx`, `constants/transactionSource.js`). Offered to add a "?" popover legend on the Record Keeping header. Awaiting Amin's go.

## Operational gotchas learned
- **Checkpoint numbers collide with DuoSync siblings.** Always `git fetch --tags` and pick the next FREE `checkpoint-NNN` before tagging — siblings (Amin/Kamyar/Shahab) increment concurrently. Mine landed as 040/041 because 037/038/039 were taken mid-session. See [[checkpoint-rule]].
- **Local Postgres (Laragon) doesn't auto-start after reboot** — app 500s with `connection refused :5432`. Start fix is in [[local-dev-run-windows]].
- Related: [[union-plan-coordination]] (ADR-0006/0007 chat-media context), [[dashboard-build-status]].
