---
name: chat-media-adr0007
description: ADR-0007 accountant↔client chat media (photos/voice/files) — both dashboard halves built+deployed; the inbound empty-bubble cross-poll fix; only the joint smoke test remains.
metadata: 
  node_type: memory
  type: project
  originSessionId: 8f1fb65a-2016-4baf-8cf0-2fd6e4578a77
---

ADR-0007 = accountant↔client chat media (send + view photos / voice memos / files) across the dashboard↔mobile bridge. **State as of 2026-06-27: both dashboard halves built, tested, deployed; mobile side LIVE (Shahab re-imported the n8n workflow); only the joint smoke test remains.**

**Outbound (accountant → client) — done earlier:** `ChatService::send` mints a signed `chat.media` route (`URL::temporarySignedRoute`, +30 min, streams bytes, signature-gated, no session, scoped to `ClientMessage` attachments) and passes `attachment {url,name,mime,sizeBytes}` + a stable `clientId="chat-{messageId}"` to `MobileApiClient::sendMessageToUser`. Mobile n8n GETs the URL → re-stores in their S3 → sets `attachment_id`. Same `send-message` scope. `ChatMediaController` serves the bytes.

**Inbound (client → accountant) — the empty-bubble bug fixed THIS chat (dashboard commits `96a8c56`→`ac6b2f2`→`dc7faf3`→`21f91bb`):** A client photo arrives as an `accountant_messages` row (carrying `attachment_id`) + an `attachments` row that often sync in **different polls**. The message projector only links a file already present, and an unchanged message row is NOT re-processed on later incremental polls (`last_synced_at >= $since`) → the file never linked → empty bubble, needing a manual `mobile:project-messages` each time. Fixed three ways:
1. `PollMobileChangesJob` reordered: transactions → **attachments → messages** (was messages first), so the file is present when the message links it in the same poll.
2. **Bidirectional link** — `MobileAttachmentProjector::messageLinks()` reverse-links a freshly-synced chat attachment to its inbound `ClientMessage` (covers the message-first / cross-poll case the message projector can't re-link).
3. **Read-time self-heal** — `ChatService::threadFor()` → `relinkPendingInboundMedia()` links any synced-but-unlinked inbound media when the accountant opens or polls the chat. Runs in the WEB layer (not the queue worker), so it works right after `git pull` regardless of worker state — this is what removes the manual command for good.
- **Inbound-only guards** on all link paths (`linkInboundAttachments`, `messageLinks`, `relinkPendingInboundMedia`) so an OUTBOUND echo (which carries mobile's re-stored mirror `attachment_id`) never adopts that mirror — else the accountant-sent photo would render twice. 62 mobile+chat tests green. Docs: `docs/chat-media.md`.

**Prod owes (one-time, via SSH — the deploy webhook only does `git pull`):** `php artisan optimize:clear` (web layer picks up the read-time self-heal) + `php artisan queue:restart` (worker picks up the projector + guard changes). After that, no per-photo commands ever.

**Remaining = the joint smoke test only:** test both directions on prod — (a) accountant sends a photo from Messages Studio → renders in the app's *My Accountant* within ~10s; (b) client sends a photo from the app → renders in the dashboard thread (self-heals on open). Contract + live status live in `union-plan-coord/decisions/0007-chat-media.md` (Status: approved) + `union-plan-coord/STATUS.md`. Related: [[union-plan-coordination]], [[mobile-poll-queue-fix]], [[mobile-attachment-binaries-missing]].
