---
name: email-integration-forwarding
description: "Dashboard Email Integration (Resend Inbound forwarding) — Phase 1 built end-to-end on dev, awaiting infra + test"
metadata: 
  node_type: memory
  type: project
  originSessionId: 8be6862e-1277-4b0a-be9e-07f85f0e80e8
---

Built **Email Integration / forwarding path** in `va-dashboard2` (2026-06-29). Clients/accountants forward a receipt email to a unique address on `in.voiceaccountant.com`; Resend `email.received` webhook → light controller verifies Svix sig + enqueues → `ProcessInboundEmail` (SQS in prod, per-firm rate-limited) → `InboundEmailService::process()` stores attachment in the client's S3 folder, runs the existing Gemini extractor, creates a **draft `source=email` (pending)** transaction, and **proposes** a match (accountant-gated, never auto-applied). Distinct from the pre-existing OAuth `EmailIngestionService`/`EmailConnection` (Documents-only) = Phase-2 "connect inbox".

**Locked decisions:** subdomain `in.voiceaccountant.com`; new `source=email` enum value (migration alters `check_transactions_source`); email items fold into the Record Keeping pending list with a 📧 badge + Source=Email filter (not a separate page); SQS + DLQ as the queue backbone; reconciliation task for downtime safety; per-firm rate limit from day one.

**Status:** committed + pushed @ **checkpoint-115 (56c9b49)** on `main`. Dev DB **migrated** (all 4 ran on local Postgres). Still owes on dev: `npm run build` (React: badge, Settings card, match banner). NOT deployed to prod. Amin does the infra (Resend receiving domain + MX + webhook secret, AWS SQS queue+DLQ, Railway worker) ≈2026-06-30 per the setup-doc checklist. (Hit a 500 first because the Settings card queried `email_inboxes` before migrate — fixed by running migrate + wrapping `SettingsController::buildEmailInbound` in try/catch so the optional card can never 500 the page again.) Prod owes: `migrate --force` + `npm run build` + `config:clear` + the `.env`/SQS/worker bits in the docs.

**Test without Resend:** `php artisan email:provision-inboxes --show` then `php artisan email:simulate-inbound {clientId} {localFile} --from= --subject=` runs the whole extract→draft→propose pipeline locally.

**Authoritative docs (travel via git):** `va-dashboard2/docs/email-integration.md` (how-it-works + file map + test guide) and `docs/email-integration-setup.md` (infra checklist + coordination). READ those before continuing.

Key files: `app/Services/Email/{InboundEmailService,TransactionMatcher,ResendInboundClient}.php`, `app/Jobs/ProcessInboundEmail.php`, `app/Http/Controllers/{ResendInboundWebhookController,InboundEmailReviewController,Settings/EmailInboxController}.php`, models `EmailInbox/EmailAllowedSender/InboundEmail`, React `EmailForwardingCard.jsx` + `EmailMatchBanner.jsx`. Reuses `DocumentAiExtractor` + `TransactionDraftValidator` (see [[document-ai-pipeline]]); honored gotchas: queue-must-be-drained, guarded `storeUpload`, morph-alias `attachable_type`, ActivityLog console-skip needs `action_source=ai_worker`. Relates to [[transaction-source-origin-rules]], [[wait-for-user-test-before-deploy]], [[marketing-site-suite]].
