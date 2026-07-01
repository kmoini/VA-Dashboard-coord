---
name: email-integration-forwarding
description: Dashboard inbound-email forwarding path — forward a receipt to a unique per-client address → AI draft source=email + accountant-gated match proposal. Receiving switched Resend→AWS SES (2026-06-30); sending stays Resend. READ before touching inbound email / SES / SNS / the match banner.
metadata: 
  node_type: memory
  type: project
  originSessionId: 8be6862e-1277-4b0a-be9e-07f85f0e80e8
---

Dashboard feature (`va-dashboard2`): a firm/client forwards a receipt/invoice to a unique address on `in.voiceaccountant.com` (`c-{token}@…` per client, `f-{token}@…` firm fallback). The AI extracts a transaction and the accountant approves. Distinct from the OAuth `EmailConnection` / `email:process-ingestion` path (Documents-only) which is the Phase-2 "connect inbox".

**Transport = AWS SES receiving** (switched FROM Resend Inbound on 2026-06-30 by user decision; **sending stays on Resend**). Flow: SES receipt rule stores raw `.eml` in S3 + publishes SNS → `POST /webhooks/ses/inbound` (`SesInboundController`, SNS signature+topic verified via `aws/aws-php-sns-message-validator`, auto-confirms subscription, CSRF-exempt, light: verify+enqueue) → `ProcessInboundEmail` job on the **`sqs`** connection (per-firm `RateLimited`, tries=5+backoff, `failed()`→row `failed`+DLQ) → `InboundEmailService::process()`: read raw from `ses_inbound` S3 disk → parse MIME (`zbateson/mail-mime-parser`) → store attachments in client S3 folder (`firms/{firm}/email/…`, guarded `store()` ghost-row-safe, `attachable_type='Transaction'`) → `DocumentAiExtractor`+`TransactionDraftValidator` → create draft `source=email` pending (NOT via DocumentAiIngestService, to avoid its silent auto-enrich) → `TransactionMatcher::propose()` stamps `metadata.email_match` (proposal, never applied) → activity log (`action_source=ai_worker`). Reliability: raw `.eml` retained in S3 + SNS retries + `email:reconcile-inbound` (every 10 min) scans the bucket → no loss. Idempotent by `provider_message_id` (=SES messageId; renamed from `resend_email_id`).

Accountant review: draft shows in Record Keeping pending with 📧 badge + Source=Email filter; `EmailMatchBanner` on the transaction detail offers Confirm-match / Keep-new / Link-to-another / Ask-AI-again (`InboundEmailReviewController`, `recordkeeping/email-match/*`). Settings → Email Integration card (`EmailForwardingCard`): firm+per-client addresses, copy/regenerate, trusted senders.

Key files: `app/Services/Email/{SesInboundClient,InboundEmailService,TransactionMatcher}.php`, `app/Http/Controllers/SesInboundController.php`, `app/Jobs/ProcessInboundEmail.php`, models `{EmailInbox,EmailAllowedSender,InboundEmail}`, `config/services.php email_inbound.*` + `config/filesystems.php ses_inbound` disk. Two new composer deps: `zbateson/mail-mime-parser` + `aws/aws-php-sns-message-validator`.

**Status:** Resend version committed @ **checkpoint-115 (56c9b49)**. The Resend→SES switch is coded, `php -l` clean, deps installed on dev, dev DB migrated (incl. `provider_message_id` rename) — **NOT yet committed** and NOT `npm run build`. Amin owes the AWS infra per `docs/email-integration-setup.md` §3: SES verify `in.voiceaccountant.com` + MX (receiving region e.g. us-east-1), S3 raw bucket + policy, SNS topic + HTTPS subscription, SES receipt rule (S3 action + SNS), SQS queue+DLQ, Railway worker. Prod owes: `composer install` (2 new deps) + `migrate --force` + `npm run build` + `config:clear` + `.env` (SES_INBOUND_*, EMAIL_INBOUND_*, SQS_*, EMAIL_INBOUND_QUEUE_CONNECTION=sqs).

`php artisan email:simulate-inbound <clientId> <path> --from=…` drives the whole pipeline locally WITHOUT AWS. `email:provision-inboxes --show` lists addresses. Related: [[wait-for-user-test-before-deploy]] [[deploy-process]] [[document-ai-pipeline]] [[transaction-source-origin-rules]] [[autocommit-leaks-secrets]].
