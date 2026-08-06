---
name: growth-books-session-pact
description: File-territory + protocol agreement between the Growth&Marketing session and the Books-overhaul session on va-dashboard2 (2026-08-05). READ before touching va-dashboard2 shared files.
metadata: 
  node_type: memory
  type: project
  originSessionId: f15acdf7-3df5-4965-883a-7b62cd86273c
  modified: 2026-08-05T15:41:24.790Z
---

Two Claude sessions work concurrently on va-dashboard2 (repo auto-commits/pushes). Agreed 2026-08-05, disputes go through Amin.

**Global rules (both):** NEVER deploy (Books overhaul is half-done on main); never `git add -A`/`git add .` (stage explicit paths, verify with `git status`); checkpoint number from live tags (`git fetch --tags` then `git tag -l "checkpoint-*" | sort -V | tail -3`); commit prefixes: `growth:` (marketing session) vs `books:`/`phase-N:` (accounting session); declare any shared-file change in the commit message.

**Books session owns (do NOT touch):** app/Accounting/**; CsvAccountImporter, BankCsvImporter, SmartImportService, AiTransactionCategorizer, VendorMatchingService, RuleEngineService; BooksController, BankReconciliationController; BankReconciliation, BigcapitalConnection models; Pages/Books/Index.jsx; docs/books-accounting-overhaul-plan.md; PLUS all 7 transaction-creation paths: TransactionService, DocumentAiIngestService, DocumentAiExtractor, InboundEmailService (+ ResendInboundWebhookController), TransactionObserver, MobileVoiceIntakeController, MobileTransactionProjector, ClientPortalController (transaction-creation part only).

**Growth session owns:** app/Services/Marketing/**, app/Http/Controllers/Marketing/**, resources/js/Pages/Growth/**, ContactImport*/Campaign* components, new marketing_*/campaigns/content_templates models+migrations; plus existing invite/referral domain: BulkInviteController, ReferralController, AccountantReferralController, ReferralToken, AccountantReferralCode, ReferralSignUp, TelnyxSmsService, ConnectedEmailService (distinct from InboundEmailService!), ReferralCodeService, BulkEmail/BulkSmsInviteModal, Pages/Referral/**, Pages/Clients/Index.jsx.

**Shared-file protocols:** AiPromptCatalog.php + AiFeature enum: append-only at END, no resorting (both sessions must add entries; prompts never heredoc). routes/web.php: books group ~L456-510, growth group at end of file, webhook routes L44-47 untouched, no reformatting. Sidebar.jsx: append at end of accountantNavigation, no resorting. composer.json/package.json/lockfiles: no dependency added without telling Amin first, never simultaneously (first commits+pushes, second pulls then starts). ParsesCsv.php trait: Books may change it, Growth won't use or modify it (Growth builds its own parser).

**Resend webhooks:** existing `services.resend.webhook_secret` (config/services.php:126) belongs to inbound-email (Books). Growth's future bounce/complaint endpoint MUST use a NEW key `RESEND_EVENTS_WEBHOOK_SECRET` (`services.resend.events_webhook_secret`) + a new controller (not ResendInboundWebhookController) — Svix issues one secret per endpoint; sharing the key silently breaks one signature verification.

**ocrToText:** Books may change DocumentAiExtractor internals but keeps `ocrToText()` signature stable; will flag behavior changes in commit messages so Growth retests PDF contact extraction.

Related: [[books-accounting-overhaul-plan]], [[checkpoint-rule]], [[wait-for-user-test-before-deploy]], [[growth-marketing-center-plan]]
