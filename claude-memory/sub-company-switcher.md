---
name: sub-company-switcher
description: "Accountant header CompanySwitcher (2nd dropdown beside ClientSwitcher) narrowing surfaces to one of a client's registered companies + Unassigned bucket & bulk-assign. Built local 2026-07-25, NOT deployed. READ before header scope / current_client_company_id / company filtering."
metadata: 
  node_type: memory
  type: project
  originSessionId: 214b33a4-0102-4f94-a64b-81dc65df1f16
  modified: 2026-07-27T19:32:33.962Z
---

Second header dropdown beside ClientSwitcher letting an accountant narrow a
multi-company client's books to ONE registered company (see
[[client-registry-multi-company]] for the registry that supplies them).

**Two nested session scopes:** `current_client_id` (ClientSwitcher, existing) and
`current_client_company_id` (new). The company scope is SUBORDINATE — switching or
clearing the client clears it (ClientSwitcherController + ClientsController::show),
and every read re-validates the id still belongs to the pinned client.

`App\Services\ClientCompanyScope` is the single source of truth: `current()` /
`applyTo()` / `applyValue()`. Values: null = all · int = that company ·
`'unassigned'` = `client_company_id IS NULL`.

**Applies ONLY to transaction-derived surfaces** (they have a company dimension):
Record Keeping, Dashboard KPIs + cash flow, Reports/Client Ledger, exports.
Documents/Chat/Inbox/Books untouched (no `client_company_id` column). The Client
Ledger per-company TOTALS table stays unnarrowed on purpose (it IS the breakdown).

**Visibility rule:** renders only when ≥2 companies OR 1 company with untagged
rows; hidden otherwise (backend returns null prop `clientCompanyScope`).

**Unassigned discoverability** (owner explicitly asked it not be buried): amber
count badge on the closed switcher + first-class dropdown entry with counts +
BULK ASSIGN (`POST /recordkeeping/bulk-assign-company`) from the table toolbar.
Also auto-tags a NEW transaction with the pinned company.

⚠️ **Known limitation:** the table's `isSelectable` only allows selecting PENDING
unlocked rows, so bulk-assign covers those; an APPROVED untagged row still needs
the drawer. Widening it would change what Approve/Delete/Merge act on, so it was
left alone — owner decision pending.

**Why:** owner (2026-07-25) wanted per-sub-company views for multi-company clients.
**How to apply:** no migration/env; deploy = pull + npm build + `optimize:clear`
(3 new routes). Follow [[wait-for-user-test-before-deploy]] + [[checkpoint-rule]].
Doc: docs/sub-company-switcher.md.

⏭️ **NEXT PHASE agreed with owner: the CLIENT PORTAL gets the same sub-company
scope** for self-serve multi-company clients. Deliberately deferred (accountant
first) — do not forget it.
