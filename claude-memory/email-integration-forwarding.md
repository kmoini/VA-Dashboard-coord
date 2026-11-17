---
name: email-integration-forwarding
description: Inbound email forwarding (Resend) → Inbox → Email page → draft/merge/file; the 2026-09-25..28 build (cp-252..261), its live-test lessons, Google/Microsoft connection state and what is still owed. READ before inbound email, the Inbox → Email page, trusted senders, Gmail/Microsoft connection, or OAuth verification.
metadata:
  node_type: memory
  type: project
  originSessionId: 8be6862e-1277-4b0a-be9e-07f85f0e80e8
  modified: 2026-11-14T00:00:00.000Z
---

**State as of checkpoint-261 (2026-09-28); later sessions changed intake again
(Accounting V2 `IntakeDraftService` routes every intake, `320bb19c`; audit-row and
prompt-provenance fixes). Full record: `docs/email-integration-review-queue.md`.**

## How it works
A client/firm forwards a receipt to `c-{token}@voiceaccountant.com` (per client) or
`f-{token}@` (firm). Resend receives on the APEX domain (⚠️ MX `inbound-smtp.us-east-1.amazonaws.com`
IS Resend's record, Resend inbound runs on SES; do not "fix" it) → `email.received`
webhook `/webhooks/resend/inbound` (Svix, `RESEND_WEBHOOK_SECRET`) → `ProcessInboundEmail`
(default queue) → `InboundEmailService::process()`. `email:reconcile-inbound` every 10 min
backfills via the Resend API; Resend keeps copies ~30 days (404 after → terminal
"Too old to fetch again"). Prod is a cPanel host (`hlrihub@node5126`,
`~/websites/my.voiceaccountant.com`, plain `php artisan`), NOT Railway.

Trust: the client's `email` + `metadata.additional_emails` are trusted automatically;
`email_allowed_senders` rows live on the FIRM inbox and carry `client_id` (cp-252), so
one list serves both addresses and attributes mail on the firm address. Unknown sender →
`quarantined` → Inbox "Unknown sender" → **Approve and process** (trusts + requeues).

Intake (`IntakeOutcome` + `conclude()`, cp-257..261): per attachment → Gemini extract →
`DocumentRoleDetector`; `non_financial` (signature PNG) = `markTriaged(FILED)`, other
non-postable roles filed under the client / `autoLinkHeld`; postable drafts go through
`sameTransaction()` (attachment checksum already on an entry, or matcher ≥ 0.85 with
amount exact; prefers approved/override, then oldest) → `foldInto()` fills BLANK fields
only, attaches the file unless same checksum or same name+size already on it → email
`matched` with no created id ("Already in your books"). Otherwise a pending draft with
the usual "duplicate?" proposal. If the files yielded nothing, the BODY (≥ 40 chars) is
extracted (`extractFromCombinedText(..., 'email_body')`). Held/failed emails notify every
firm accountant (`inbound_email_held`, url `/inbox/emails`).

## Surfaces
- **Inbox → Email** `/inbox/emails` (`Inbox/InboundEmailsController`, `Pages/Inbox/Emails.jsx`,
  routes `inbox.emails.*`): list + filters, body in `<iframe sandbox>` + CSP, attachments,
  plain-words status via `InboundEmail::explain()`/`present()` (`open_transaction_id`),
  Approve / Try again / Open entry. Pinned "Email" item in Messages Studio; sidebar Inbox
  badge = shared prop `emailAttention`.
- **Client card** (Clients): "Receipts by email" address, Copy, and **Send** which really
  sends `App\Mail\ForwardingAddressMail` from the dashboard (connected account else system
  mailer), records `metadata.forwarding_address_sent_at/_to` + activity log; an email-less
  client gets the typed address saved as `email`. `regenerate()` RETIRES the old inbox
  (`is_active=false`) so mail to it shows "Sent to an old address". No Regenerate in UI.
- **Settings → Email Integration**: firm address + "Who may send" only (list and per-client
  addresses moved out).

## Traps learned (all bit prod)
- `transactions.ai_source` Postgres CHECK (`ocr_receipt, ocr_invoice, bank_feed,
  email_parser, mobile_quickentry`): `email_body` failed every body invoice 5×; sqlite
  cannot see it → `aiSourceFor()` whitelist + pinned test.
- `TransactionMatcher`: `GREATEST()` is Postgres-only (matcher was untestable) and Carbon 3
  `diffInDays()` returns a float so "same date" never scored. Both fixed cp-257.
- Retries re-stored attachments (10× image.png) → `storeAttachments()` idempotent per
  (inbound_email_id, checksum).
- A "still duplicated" report at 18:50:16Z predated the commit by 3 s: check deploy time
  before debugging.

## Google / Microsoft connection (Settings → Email Account Connection)
- Callback is `/settings/email/callback` (NOT `/auth/google/callback`); registered on the
  Google client 2026-09-26. Gmail API enabled. Scopes = `gmail.send` + userinfo only;
  **gmail.readonly removed** (restricted → paid CASA); `EmailIngestionService::canReadInbox()`
  skips Google. Drive import = `drive.file` (cp-256). Consent screen In production /
  External / UNVERIFIED → "Google hasn't verified this app" (Advanced → continue), 100-user
  cap until verification (colleague doing Search Console + demo video + submit; privacy
  page 6.1 already has the Limited Use pledge).
- Microsoft: `MICROSOFT_CLIENT_ID/SECRET` empty on prod when last checked; needs an Entra
  App Registration (multitenant + personal, redirect `/settings/email/callback`, delegated
  Mail.Send, Mail.Read, User.Read, offline_access).

## Owed when this was written (verify before acting)
Google verification; Microsoft registration; one live Drive-import test; prod clean-up
(`InboundEmail` rows 6,7,9; duplicate files per email; pre-change duplicate Home Depot
drafts). `email:simulate-inbound <clientId> <file>` drives the pipeline locally.
Related: [[google-oauth-setup]] [[activity-log-entity-type-trap]] [[checkpoint-rule]]
[[deploy-queue-restart]] [[document-role-triage]].
