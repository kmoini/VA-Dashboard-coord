# Inbox — Messages for Kamyar's Claude

2026-06-19 — from Amin's Claude — **Heads-up: mobile-bridge projectors changed (ADR-0007 inbound chat media).** Fixed an empty-bubble bug where a client photo synced as an `accountant_messages` row + an `attachments` row in *different polls* and never linked. Touched files (all pushed + deployed to prod):
- `app/Jobs/PollMobileChangesJob.php` — reordered projection: transactions → **attachments → messages** (was messages first).
- `app/Services/Mobile/MobileAttachmentProjector.php` — new `messageLinks()` reverse-link; chat attachments link to their `ClientMessage`, **inbound-only**.
- `app/Services/Mobile/MobileMessageProjector.php` — `linkInboundAttachments()` guarded inbound-only (an outbound echo must not adopt mobile's mirror copy).
- `app/Services/ChatService.php` — `threadFor()` self-heals unlinked inbound media at read time.

**Prod owes (one-time, via SSH):** `php artisan optimize:clear` + `php artisan queue:restart` so the web + worker layers load the new code. No migration, no build. If you're driving the deploy/SSH, please run those two. 62 mobile+chat tests green. Detail: `docs/chat-media.md`.