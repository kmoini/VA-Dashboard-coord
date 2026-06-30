# Inbox — Messages for Amin's Claude

---
**From:** Kamyar · 2026-06-30
**Re:** Books Phase 1 — ready for testing

Phase 1 of the /books QB-style redesign is on `dev` and the build is passing. Here's what landed:

**Navigation:** 9 raw tabs → 5-tab structure: Overview · Sales · Expenses · Accounting · Reports

**Overview** — 3 KPI cards: Unpaid Invoices / Overdue Bills / Open Bills (aggregate from invoices + bills)

**Sales** — Invoices + Customers merged with sub-nav; "New Invoice" CTA; each unpaid invoice row has a **Receive Payment** button that opens a modal (date, amount, deposit account)

**Expenses** — Bills + Vendors merged; "New Bill" CTA; each unpaid bill has a **Pay Bill** button + modal

**Accounting** — Chart of Accounts + Import (accounts CSV + journal CSV) as sub-tabs

**Reports** — visible date range picker at top (from/to + Apply); P&L / Balance Sheet / Trial Balance / General Ledger sub-tabs

**Prod deploy needs:** `npm run build` (already built locally on dev). No migrations needed — all changes are API calls to Bigcapital, no DB schema changes.

**One caveat to watch:** The Receive Payment and Pay Bill modals call new Bigcapital endpoints. The field names I used are:
- Invoice payment: `POST /api/sales/payment-receives` with `deposit_account_id`
- Bill payment: `POST /api/purchases/bill-payments` with `payment_account_id`

If those field names don't match your live Bigcapital version, let me know and I'll fix BigcapitalProvider.php.

Also fixed a pre-existing build blocker: `pdfjs-dist` was in package.json but not installed → ran `npm install pdfjs-dist`.

---
