---
name: cheques-feature
description: "Cheques (va-dashboard2): a bill in QuickBooks paid by a cheque made here, PDF laid out for the client's own cheque paper. Built 2026-11-25/26, committed locally as checkpoint-586 (push pending), NOT verified on a live QuickBooks. Read docs/cheques.md first."
metadata:
  node_type: memory
  type: project
  originSessionId: 2876e3a1-1192-4443-9ba3-fc6e0e078315
  modified: 2026-11-27T15:52:22.415Z
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
1. 2026-11-26: Amin committed it as checkpoint-586; the push of main was rejected (45 teammate commits), the tag went up on the old hash. Rebased onto origin/main here (one conflict, Sidebar import) and `ChequeSampleReader` moved to `AiModels::for('file')` (the team's new NoHardCodedAiModelTest). Amin then pushed it: main = 074f278c, tag checkpoint-586 moved onto it. The server was still on a6c7f9a2 ("Nothing to migrate") when he ran the post-deploy commands, so the deploy pull had not happened; he then ran `git pull --ff-only origin main` on the server by hand and it is LIVE on prod at 074f278c (cheques migration DONE, build ok, 2026-11-26), awaiting his sandbox test; test guide PDF (Persian) left in his Downloads as cheques-test-guide.pdf. Amin tags and pushes from his laptop ([[checkpoint-rule]], [[wait-for-user-test-before-deploy]]). Server needs `php artisan migrate --force` and `npm run build`.
2. Never run against a live QuickBooks (the local Postgres was down, so no sandbox run from here). Three calls to confirm on the sandbox: BillPayment with DocNumber + NotSet keeps its number; vendor credit applied as a zero BillPayment with a VendorCredit line; a no-bill cheque with a tax code (`GlobalTaxCalculation: TaxInclusive`).
3. Not built on purpose: warning when the cheque exceeds the book balance; a Document Hub copy of the PDF; part payments and credits inside the cheque run.

**2026-11-26/27, from Amin's test of the paper setup on prod (LIVE through checkpoint-599, ef8143a1):** a PDF scan the browser cannot draw is drawn on the server (PdfPageSplitter) and its pages offered; the page picker stays so a wrong pick is one click; the picture enlarges (100/200/400%), a step is 0.1 mm, arrow keys work, the picked field is red and see-through; each stub has its own `foot` (distance to its last line), because QuickBooks' own print puts it at 69.1 mm on the first stub and 67.4 mm on the second (measured on his scan), so a rigid block cannot match both. Amin confirmed the stub setting works. Sections B to E of the test (real entries on a sandbox QuickBooks) still not run. ⚠️ Another session commits checkpoints in the same checkout at the same time: fetch tags before picking a number, add only own files, and always include `php artisan migrate --force` in the server commands.

**How to apply:** start from `docs/cheques.md` (it carries the click-by-click test). Test only on a client whose QuickBooks connection is a sandbox: a cheque made here is a real payment in the connected books.
