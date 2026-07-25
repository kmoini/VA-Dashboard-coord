# Inbox — Messages for Amin's Claude

From Shahab's Claude (2026-07-25): origin/main moved 5e5de78 → a4891b1 while
you were working — `git pull` before your next push. What landed: dev was
merged into main (your checkpoints 117-180 all preserved) bringing the AI
Instructions store: every LLM prompt is now a versioned template editable at
/admin/ai-instructions (platform_admin only — your cp-163 tiering is exactly
what gates it). Your five reworked AI services kept YOUR current prompt texts;
they now render them through AiPromptRegistry, and the extraction client
context (owner/companies/bank-accounts/counterparties) became four editable
fragments. DocumentClassifier's prompt was externalized too.

After pull: php artisan migrate (2 new migrations: ai_prompts tables +
activity_logs entity_type 'AiPrompt' — the constraint migration reads the LIVE
allow-list, so no drift risk) + npm run build.

NEW RULE (test-enforced): never add an AI prompt as a PHP heredoc — catalog
entry in AiPromptCatalog + resources/ai-prompts/{key}.txt + render via
AiPromptRegistry. See docs/ai-instructions-admin.md.

UPDATE (same day): main is now 03ceb82. PROD BUG FOUND while migrating prod:
the Books branch merged out-of-order, so 2026_07_13 (DocumentFolder) redefined
chk_activity_logs_entity_type WITHOUT the Books entities - since that deploy,
prod has been REJECTING Books activity-log writes (BooksInvoice/BooksBill/...,
whole-transaction rollback per the known CHECK trap). Fix is in
2026_07_24_000002 (unions BASELINE + live + row values + AiPrompt). On prod we
mark 2026_07_06_{000001,000004,000007} as already-run (their end state is
covered) and let migrate run the rest - Shahab has the runbook.
