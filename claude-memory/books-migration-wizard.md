---
name: books-migration-wizard
description: "Full QuickBooks (Online + Desktop-CSV) to Books/Bigcapital migration wizard built 2026-07-06 in VA-Dashboard, NOT deployed, uncommitted at session end"
metadata: 
  node_type: memory
  type: project
  originSessionId: f03f092a-f2cd-4952-afe5-7e51db3ebca7
---

Built a complete migration wizard in VA-Dashboard (`d:\projects\VA-Dashboard`, branch `dev`)
so accountants can migrate a client's entire accounting history — accounts, customers,
vendors, items, invoices, bills, payments — from either QuickBooks Online (live API) or
QuickBooks Desktop (CSV upload, since Desktop has no API) into the in-house Books module.

**Why:** the previous migration path (`QuickBooksToBigcapitalMigrator` + `CsvAccountImporter`/
`CsvJournalImporter`) only covered Chart of Accounts + raw journal entries, and journal-entry
re-runs were non-idempotent (double-posted). User asked for a "seamless, complete" migration
with no records left behind and no silent errors, for both QBO Desktop and Online.

**What was built** (full detail in `docs/books-migration.md` in that repo):
- `AccountingMigrationEngine` (`app/Services/AccountingMigration/`) — 9-stage dependency-ordered
  engine (accounts→customers→vendors→items→invoices→bills→payments→bill_payments→journals),
  writes only to `BigcapitalProvider`, reads from either `QuickBooksProvider` (now also
  `implements MigrationSource` directly) or a new `DesktopCsvSource` wrapping 9 CSV parser
  classes (`App\Services\Csv*Importer`).
- New `accounting_migration_mappings` table (source-id → Bigcapital-id) makes EVERY entity
  idempotent, including journals — this is the actual fix for the old double-post bug.
- Dry-run/validation pass before the real run, plus a post-run reconciliation report
  (trial-balance diff vs QBO source, per-stage created/skipped/failed counts).
- `MigrateAccountingDataJob` — one stage per invocation, re-dispatches itself, `default` queue.
- `BooksMigrationController` + routes at `books.migration.*` (inherits client-portal access
  automatically via the existing `books.*` ResolveTenant allow-list wildcard — no separate
  allow-list edit needed).
- Frontend wizard in `Books/Index.jsx` → Accounting tab → new "Migrate" sub-tab (kept the old
  "Import" sub-tab alongside it, unchanged, rather than removing it).

**Non-obvious things found/fixed along the way:**
- `QuickBooksProvider` claimed `implements AccountingProvider` but was missing `createItem`/
  `createInvoice`/`createBill` — a latent fatal-on-autoload bug that had never fired because
  nothing in the app ever actually instantiated that class before this feature.
- `InvoiceDTO`/`BillDTO` gained an optional `lines` array (line items) and `customerId`/
  `vendorId` fields — previously only summary fields were read, not enough to actually
  recreate a document elsewhere.
- `ItemDTO` gained optional `incomeAccountId`/`expenseAccountId` (source-side account refs,
  migration-only).

**How to apply:** ⚠️ Built and verified this session (all new PHP lints clean, all routes
register via `route:list`, all 6 pending migrations pass `migrate --pretend`, `npm run build`
succeeds) but **NOT yet run against a real database, NOT committed, NOT deployed**. Read
`docs/books-migration.md` before touching this code further. Before relying on it: actually
run the migrations, exercise the wizard against a QBO sandbox or sample CSVs on
`pr.voiceaccountant.com`, and get it reviewed/committed.

Note: a teammate concurrently shipped an unrelated bank-reconciliation feature in the same
repo during this session (`BankReconciliationController`, `accountLedger()` added to
`AccountingProvider`/`QuickBooksProvider`/`BigcapitalProvider`) — no conflict with this work,
just be aware both landed uncommitted in the working tree at the same time.
