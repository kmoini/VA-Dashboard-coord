---
name: cheques-feature
description: "Cheques (va-dashboard2): a bill in QuickBooks paid by a cheque made here, PDF laid out for the client's own cheque paper. Built 2026-11-25/26, NOT committed, NOT verified on a live QuickBooks. Read docs/cheques.md first."
metadata:
  node_type: memory
  type: project
  originSessionId: 2876e3a1-1192-4443-9ba3-fc6e0e078315
  modified: 2026-11-26T01:40:37.122Z
---

Built 2026-11-25/26 in `va-dashboard2` at Amin's request ("the accountant tells the AI: prepare the cheque for that invoice and send it to me to print, sign and post"; nobody should open QuickBooks). Amin approved the full design in one release, no phases, and said: build everything, then hand over the commands and the test once.

**Where:** `app/Cheques/` (ChequeService = rules, ChequeBooks = QuickBooks calls, ChequeSheet = positions in mm, ChequePdf, AmountInWords, ChequeNotifier, ChequeSampleReader, AssistantCheques), `ChequesController`, `resources/js/Pages/Cheques/` + `Components/Cheques/`, tables `cheque_layouts` / `cheques` / `cheque_lines` (migration `2026_11_25_000001`), doc `docs/cheques.md`, tests `tests/Feature/Cheques/ChequesTest.php` (23, against a fake QuickBooks). Flag `FEATURES_CHEQUES` (default on).

**Facts found, not obvious from the code:**
- QuickBooks' API has NO PDF for a cheque or bill payment; the PDF is ours (dompdf).
- QuickBooks' own cheque numbering is unreliable (Cowork on a Canadian sandbox, 2026-11-25: offers used numbers; its print queue turned a typed 9010 into 9003). So the number is ours, per bank account (`cheque_layouts.next_number`), and entries are created with `PrintStatus: NotSet`.
- QuickBooks' stub holds 13 bill lines, then "Total of additional bills". Its alignment is one whole-page offset; its date order is fixed. Ours is per field, three date orders.
- Payments Canada Standard 006 (2024): numeric date in DDMMYYYY / MMDDYYYY / YYYYMMDD with no slashes; 10 pt minimum; asterisks only directly before the figures; nothing in the bottom 5/8 inch.

**Decisions:**
- The cheque's row in Record Keeping is a row mirrored FROM QuickBooks (`QuickBooksRegisterMirror::adopt`, source `quickbooks`). So nothing re-sends it and `StatementSettledSync` never moves its date: a cheque keeps the date it was written. Amin's answer to "issue date or bank date?" was "do what is standard and professional"; this is that, and it changed no existing rule.
- `BankLineMatcher` now adds +0.32 when the bank line's cheque number equals the entry's (auto-confirm with same amount and account). This also changed one assertion in `QuickBooksRegisterMirrorTest` (SUGGESTED to MATCHED for "CHEQUE 00412").
- A firm's client ASKS (status `requested`), the accountant makes it; same rule as `TransactionPolicy::push`.
- Audit rows reuse entity type `Client` and existing actions, so no CHECK-constraint migration.

**Open, in this order:**
1. Not committed. Amin tags and pushes from his laptop ([[checkpoint-rule]], [[wait-for-user-test-before-deploy]]). Server needs `php artisan migrate --force` and `npm run build`.
2. Never run against a live QuickBooks (the local Postgres was down, so no sandbox run from here). Three calls to confirm on the sandbox: BillPayment with DocNumber + NotSet keeps its number; vendor credit applied as a zero BillPayment with a VendorCredit line; a no-bill cheque with a tax code (`GlobalTaxCalculation: TaxInclusive`).
3. Not built on purpose: warning when the cheque exceeds the book balance; a Document Hub copy of the PDF; part payments and credits inside the cheque run.

**How to apply:** start from `docs/cheques.md` (it carries the click-by-click test). Test only on a client whose QuickBooks connection is a sandbox: a cheque made here is a real payment in the connected books.
