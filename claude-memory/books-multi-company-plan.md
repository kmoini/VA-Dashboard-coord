---
name: books-multi-company-plan
description: "/books = one ledger per ClientCompany, client-owned, auto-generated Bigcapital creds. ALL PHASES BUILT LOCALLY 2026-07-31, NOT committed/deployed, awaiting Amin's manual test. Doc: docs/books-multi-company.md."
metadata: 
  node_type: memory
  type: project
  originSessionId: 8841ce90-8290-47d8-a6d5-69475b5dca29
  modified: 2026-08-03T16:50:08.670Z
---

**ALL PHASES BUILT + MANUALLY TESTED BY AMIN 2026-08-03 — still NOT committed, NOT
deployed. Full write-up + manual test guide: `docs/books-multi-company.md`.**
Isolation verified against the LIVE server, not assumed: 6 books for one client → 6
distinct organization ids, and an account created in one appears in no other.

Two bugs found during that test, both pre-existing and unrelated to multi-company:
(1) the New Account form carried a hidden `currency: 'USD'` default while the book was
CAD, and Bigcapital REJECTS a currency on non-multi-currency account types
(ACCOUNT_TYPE_NOT_SUPPORTS_MULTI_CURRENCY) — so creating an expense account was
impossible on any book. Currency now defaults to null everywhere (accounts, customers,
vendors) = inherit the org's base currency. Journals still default to USD (JournalDTO
requires a string); whether that should follow the book's currency is OPEN.
(2) Provisioning is non-atomic with no recovery: a network blip between `register()` and
the follow-up login leaves an organization on the server that we have no row for and no
password to — unusable AND undeletable (no delete API). Happened twice. The fix (persist
a `pending` connection with its credentials BEFORE calling register, then move the whole
thing to a queued job with retry) is agreed but NOT built. Books tests 117 → 127 passing; the 9 reds in
tests/Feature/Bigcapital are pre-existing (8 SmartImportTest hitting a nonexistent
route). Full suite 78 failing vs a 75 baseline: the 3 deltas are intentional behaviour
changes whose tests were rewritten (no-client-pinned now shows NO book instead of an
arbitrary firm "default" org; the books list is the pinned client's, not the firm's).

Makes `/books` support a client
who owns several companies, and fixes who owns the ledger. READ before touching
BooksController / BigcapitalConnection / ClientCompanyScope.

**Three locked decisions:**

1. **Books are CLIENT-owned, not firm-owned.** This overrides
   `docs/client-registry-multi-company.md`, which lists "QB/Bigcapital connections"
   under firm tooling. Reason: the whole grant layer exists so a client can switch
   accountants and take their data; leaving the ledger with the old firm strands the
   client's balance sheet and breaks the Data Exit guarantee. A book may be created
   from either the accountant dashboard or the client workspace, but it belongs to the
   client. Key becomes `(client_id, client_company_id)`; `firm_id` demotes to
   created-by/audit; firm access comes from `client_firm_grants` like transactions.
   Consequence: handover on accountant switch needs ZERO data migration.
2. **Bigcapital credentials are auto-generated infrastructure creds**, never typed by
   the user: `books+{uuid}@books.voiceaccountant.com` + 32-char random password
   (`password` is already an `encrypted` cast, so it stays retrievable). The connect
   form loses its email/password fields and becomes one-click. A gated "reveal
   credentials" action (password re-auth + permission + activity log) satisfies both
   Amin's "retrievable" requirement and DATA-EXIT-GUARANTEE-POLICY.
3. **`client_companies.entity_type`** (`corporation` / `sole_proprietorship` /
   `partnership` / `personal`) is added NOW, not deferred to the tax phase. Drives
   T2 vs T2125 and the CoA template later.

**Book unit:** `ClientCompany`. `client_company_id = null` means "the client's own
book" (personal / single-company), matching the existing `client_bank_accounts`
convention. Existing connections backfill to null, so nothing breaks.

**Phase 0 DONE (2026-07-31), both steps:**

- *Hijack bug FIXED (uncommitted, local).* `register()` on a duplicate email returns
  EMAIL.EXISTS, falls through to login, and hands back the EXISTING org;
  `updateOrCreate(['firm_id','organization_id'])` then re-pointed that row at the new
  client, silently transferring client A's whole ledger to client B **and reporting
  success**. Guard added in `BooksController::connect()` after `register()`, checked
  across ALL firms (a second firm reaching the same org is a cross-tenant leak, not a
  mix-up). Regression test:
  `BooksControllerTest::test_connect_refuses_an_org_already_mapped_to_another_client`.
  Suite went 117→118 passing; the 9 reds (8 `SmartImportTest` hitting the nonexistent
  `/books/import/bank-csv/post` route, + `csv import uses ai to infer missing types`)
  are PRE-EXISTING, verified by stashing.
- *Live probe against the Railway server, all four questions answered YES:*
  two generated emails → two DISTINCT orgs; orgs are fully isolated; a token is
  ORG-BOUND (token A + org B header → 401), so per-org stored credentials are
  mandatory; and **re-registering an existing email returns the SAME org, confirming
  one email = one organization** — auto-generated credentials are REQUIRED, not merely
  tidier. Provisioning costs ~16-21s per org (register ~2-6s, build ~1s, readiness
  poll ~13s), so a 3-company client is ~50s sequentially → must be a background job.
  Bigcapital exposes NO org-delete endpoint; deletion is a manual Railway DB action,
  which is why Phase 1 archives instead of deleting.
- *Still unmeasured:* per-tenant DB footprint (needs Railway Postgres access). This is
  the real scaling limit of "one org per company", not the email question.
- `BIGCAPITAL_BASE_URL` was previously ABSENT from Amin's local `.env`, so the whole
  Books tab was dead locally; now set to the Railway server (`.env` is gitignored).
- ⚠️ Probe litter owed on the server: orgs/users `zz-test-12f3c3-a` and `-b`.

Related: [[client-registry-multi-company]], [[client-workspace-architecture]],
[[past-clients-access-revocation]], [[bigcapital-deployment]],
[[wait-for-user-test-before-deploy]].
