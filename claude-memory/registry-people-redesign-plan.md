---
name: registry-people-redesign-plan
description: "LOCKED 2026-09-19 with Amin: Registry/People/Profile redesign in 5 phases (0 bugs+tables-as-source, 1 People table, 2 bank owner/users + QBO bank mapping + realm per company, 3 AI shareholder rules, 4 linked counterparts). ⚠️ NEVER copy a transaction into several clients; client workspace parity required. READ before registry, people, shareholders, QBO realm routing."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-19T20:03:13.186Z
---

Decisions (Amin, 2026-09-19), after a full code survey:

- **Owner vs user split.** A legal entity (ClientCompany, incl. entity_type
  `personal` for a person's own file) owns bank accounts, has one Book and ONE
  QBO realm. A bank account has exactly one legal owner plus a list of USERS
  (e.g. shareholders using the company card). Amin's firm really runs one QBO
  per company AND per person, so routing push by owner entity is correct.
- **Shareholders are accounts in QBO, not people.** Personal purchase on a
  company card = due from shareholder (GIFI 1300 / QBO LoansToOfficers), company
  expense on a personal card = expense + due to shareholder (2780). Codes and
  subtypes already exist, nothing used them.
- **⚠️ Never duplicate one transaction into every related client** (Amin's
  original idea; it double-counts). Record once at the account owner; create a
  LINKED COUNTERPART as a pending draft in a linked person's own client only
  when it concerns them. Same firm: auto-proposed. Other firm on platform:
  read-only grant + proposal in their inbox. Off platform: shareholder
  statement export.
- **People** = real table (replaces clients.metadata.partners JSON), person
  links to companies with MULTIPLE roles (shareholder, director, partner,
  employee, signing) and ownership % (shareholder/partner only); optional link
  to another client (their personal file). No SIN stored now (payroll phase
  later, encrypted). Payment nature = HINT to AI only, never auto-applied.
  Visible AND editable in the client portal, with change history and a
  "changed by client" marker for the accountant.
- **Client workspace parity is required** for every phase (Amin: "things for
  client workspace must be done too").

Phases: 0 fix the six data-corrupting bugs + tables become source of truth
(not metadata JSON) · 1 People · 2 bank owner/users, QBO bank mapping,
quickbooks_connections.client_company_id + push routing (fixes push fan-out to
every realm and first-bank fallback) · 3 AI shareholder/personal rules +
push handling (prompt changes need publish migration) · 4 linked counterparts.

**Phase 0 BUILT (b5e0995, 2026-09-19), awaiting Amin's test/deploy:** tables are
the only store (metadata companies/bank_accounts removed by migration
2026_09_19_000002, reversible); `ClientRegistryProjector::save()/forUi()` used by
BOTH forms; full account number encrypted in `client_bank_accounts.account_number`,
shown masked; registry writes need firmCanWrite. ⚠️ Don't reintroduce reads of
`metadata['companies'|'bank_accounts']`: they no longer exist.

Parked prior design reused: docs/backlog-people-registry-and-cheque-rule.md.
Related: [[client-registry-multi-company]], [[books-multi-company-plan]],
[[sub-company-switcher]], [[add-client-single-form]].
