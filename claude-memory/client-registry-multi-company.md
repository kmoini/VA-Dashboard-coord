---
name: client-registry-multi-company
description: "Multi-company + bank-account registry per client; AI fills Corporation/Bank columns + direction. ALL DEPLOYED cp169-177 (incl. the grant layer + self-serve). READ before client registry / DocumentAI corporation_name."
metadata: 
  node_type: memory
  type: project
  originSessionId: 214b33a4-0102-4f94-a64b-81dc65df1f16
  modified: 2026-07-31T20:40:50.877Z
---

**STATUS (verified 2026-07-31 against docs/client-registry-multi-company.md): every
phase below shipped, cp169-177 — including the grant layer AND self-serve
`PersonalWorkspaceService`. The per-phase "built local / NOT deployed" notes further
down are historical.** One correction pending: that doc files Bigcapital connections
under "firm tooling", which [[books-multi-company-plan]] deliberately overrides.

Dashboard feature: a client can register the COMPANIES it owns + BANK ACCOUNTS
(one company may have many accounts; account optionally tied to a company).
Document-AI then fills the Corporation (`corporation_name` + `client_company_id`)
and Bank account (`bank_account` + `client_bank_account_id`) columns and uses a
matched own-account as expense/revenue direction evidence. Transaction still
belongs to ONE client (one ledger tagged by company/account, NOT separate books
— that stays the [[bank-reconciliation-feature]] / related_entities pattern).

New: tables `client_companies`, `client_bank_accounts` (+ nullable FKs
`client_company_id`/`client_bank_account_id` on transactions, ON DELETE SET
NULL). `last4` only for accounts (no full number stored). Migration
`2026_07_23_120000_create_client_registry_tables.php` backfills accounts from
`metadata['bank_accounts']`.

Sync: Profile & Registry form writes `metadata['companies']`/`['bank_accounts']`;
`ClientRegistryProjector::sync()` (called in `ClientsController@updateRegistry`)
upserts-by-name into the tables. AI: `ClientAiContext` adds companies+accounts;
`DocumentAiExtractor` dynamic tail (OWNER COMPANIES / REGISTERED BANK ACCOUNTS) +
schema `corporation_name`; `ClientRegistryMatcher::apply()` in `persistDrafts()`
is the GATE — drops any company name not matching a registered company/alias,
matches bank_account last-4 → FK, infers company from account. Empty registry =
AI corporation_name always dropped.

UI: `Clients/Show.jsx` Profile tab gets Owner Companies section + per-account
company dropdown; old vendor-directory tab "Companies" RENAMED to "Vendors".

**Why:** owner asked (2026-07-23) for multi-company clients so AI stops leaving
columns blank / mis-signing direction. **How to apply:** deploy = migrate + npm
build (done local) + optimize:clear, no queue/env. Follow
[[wait-for-user-test-before-deploy]] + [[checkpoint-rule]]. Doc:
docs/client-registry-multi-company.md.

**Grant access-layer (Path A — client owns data, firms get scoped/revocable access):**
Phase 1 (cp-174, DEPLOYED): `client_firm_grants` table (scope all|from_date, access full|read_only,
status) + backfill 'all' grant per client→firm; `ClientFirmGrant` model; `ClientAccessService`
(firmCanAccess/grant[one-active-accountant]/revoke/switchTo); adopt() syncs grant. Phase 2 (built
local, NOT deployed): the two read chokepoints `Client::scopeForFirm` (whereHas grants) +
`Transaction::scopeForFirm` (whereExists grants, effective_date>=from_date) are grant-based +
`Client::accessibleByFirm()` replaces firm_id gates in ClientsController/ChatController/
AttachmentPreview/ClientPolicy + ClientSwitcher + DocumentsController attachment reads. BEHAVIOR-
PRESERVING (0 mismatches; verified from_date filtering). DEFERRED to Phase 4: DocumentFolder::visibleTo,
mobile projectors, vendors/invoices/messages/rules (still firm_id-based). Phase 3 (built local, NOT
deployed): connect=GRANT not re-parent (ReferralController::accept -> switchTo with client scope
all|from_date; client stays home), disconnect=revoke/read_only (home firm -> releaseToSelfServe);
ClientAccessService gains disconnect()+currentAccountantFirmId(); UI: referral scope radio + read-only
checkboxes in both disconnect modals. ⚠️ CRITICAL FIX in Phase 3: Client::booted created-hook auto-creates
home grant — WITHOUT it a client created after the backfill is INVISIBLE (grant-based reads). cp-175 is
LIVE without this fix, so any client created on prod post-cp-175 needs a grant backfill. Phase 4 (built local, NOT
deployed, FINAL): DocumentFolder::visibleTo grant-aware (system + firm library + pinned client's folders
when granted + firm-wide = granted clients; defence-in-depth guard); remaining accountant client-DATA
reads (DashboardController/TransactionsController attachment-guard/AiAssistantService/RuleEngineService/
RelatedEntityProposalService) moved firm_id->forFirm. Vendors/rules/knowledge/invoices/messages/QB/mobile
projectors KEPT per-firm (firm tooling, correct — not the client's data). firm_id retired as access
authority (now just the "home" pointer). ALL 4 PHASES of Path A COMPLETE. Plan file:
modular-baking-stream.md. Decision: ONE active accountant at a time. READ before any
firm_id/scopeForFirm/multi-tenancy/onboarding work.

**Client Adoption (Phase 9, built local 2026-07-24, NOT deployed):** registry must
survive a client getting/changing an accountant. New `ClientAdoptionService::adopt()`
re-parents a Client to a firm keeping same `clients.id` — moves BOTH `clients.firm_id`
AND `users.accountant_account_id` (UI tenant = user's firm, not client's!), client_id-
scoped data (registry+tx+attachments) auto-follows, re-points ~13 client-scoped stale
firm_id tables each in a SAVEPOINT (Postgres poison-on-error), retires the emptied
is_personal firm, audit AFTER commit. Trigger: `ReferralController::accept` adopts an
existing self-serve identity (email match + password proof) instead of minting a new
empty Client; dropped its `unique:users,email` rule. Self-tested (rolled back). Read
before onboarding/referral/multi-tenancy/firm_id work.

**Progress (2026-07-24):** cp-169 phases 1-2 (tables + AI matcher), cp-170 phase 3
(filter/report by company: transactions-list Company filter + Client Ledger
per-company totals), cp-171 phases 4-5 (email ingestion via InboundEmailService +
self-serve portal Business Profile at /client/registry) all DEPLOYED to prod.
Phase 6 (manual Company/Bank-account picker on the transaction detail page,
TransactionsController show/update + Transactions/Show.jsx) built + self-tested
local, NOT yet committed/deployed. Prod owes `migrate --force` (cp-169 migration) +
`optimize:clear` (cp-171 new portal routes). Mobile path intentionally NOT wired
(payload has no bank/corp data; needs mobile-app change).
