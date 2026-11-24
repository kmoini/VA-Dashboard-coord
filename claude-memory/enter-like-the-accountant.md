---
name: enter-like-the-accountant
description: "FEEDBACK 2026-11-19 (Amin): every field of a row must come from how the accountant treated the vendor before (QBO, Accounting History, approved rows), in every upload path. cp-539 built the tax figure; cycle and bill date still open."
metadata:
  node_type: memory
  type: feedback
  originSessionId: b8393a83-dfbe-4f43-b6a8-1b2fb17a18fe
  modified: 2026-11-20T15:47:43.544Z
---

Amin, 2026-11-19 (Axle Corp., Desktop vs QBO): reading the books must not stop at HST. For EVERY field the engine looks at how the accountant treated the vendor and does exactly that, "as if the accountant entered it", both on a Record Keeping upload and on "Upload its document" in Bank Reconciliation.

**Why:** Toronto Hydro notice printed no HST; we booked 409.44, the accountant 362.34 + 47.10. Reports of the two books must match.

**How to apply:**
- Put any such rule in `V2DraftPipeline` (the one pipeline both upload paths reach), never in one screen.
- cp-539 (commit 208f1ca4, 2026-11-19): `BooksTaxResolver` works the tax out INSIDE the amount when the document prints none and the vendor's entries carry it (tax pattern first, then history; 3 entries / 80%). Replaces the old "never invent a tax figure" rule only for this case; the amount still never moves. Doc: docs/TAX-FROM-BOOKS-2026-11-19.md. See [[sales-tax-hst-gst]], [[historical-context-roadmap]].
- cp-540 (5fd6761b, LIVE on prod 2026-11-19, prod test by Amin pending): the accountant names utilities with account and unit ("Toronto Hydro 8877050000(UNIT300)") while the bill prints the legal name, so `VendorMatch::similar` never found the books (account, bank AND tax). `HistoricalContextService::matchingNames` now compares the name without number tokens; the numbers printed on the document pick the meter. Check name matching FIRST when "history exists but nothing was decided".
- cp-541..545 (2026-11-19/20, cp-544 LIVE = 16cba8fd; cp-545 = 9ff37c62 committed locally, push pending): `CompanyFromBooks` is the FIRST pipeline step. A row with no company (client with 2+ companies) takes it from (1) a company name or registry alias in the document text, (2) a registered bank account number on the document, (3) the one company whose history holds the vendor. History is per company, so NO company = no history decisions at all: check `client_company_id` first. The cached reading now keeps `document_text` (a replay had none). cp-542: Bank Reconciliation follows the header company switcher.
- ⚠️ PaddleOCR can DROP a line (Axle Interac summary: "From Account" with the value "00021473851 - AXLE CORP - CAD" missing) and split a first letter ("C OMFORT"). Ask for `ai_extract_raw.document_text` before blaming the rules.
- Known limit, offered not built: the QuickBooks register on Bank Reconciliation only reads when the client has exactly ONE QBO connection (`QuickBooksRegisterMirror::connectionFor`).
- cp-546 (87fd31b9, LIVE): `PartyFromBooks`: the row's vendor/customer takes the name QuickBooks already has when the document's name CONTAINS it (2+ words, exactly one party).
- ⚠️ cp-547 (f48a0c2f, committed locally 2026-11-20, push pending): DECISION by Amin with the accounting team's yes: AMENDS [[open-question-etransfer-without-bill]]. A payment with no bill, to a vendor the books know, is recorded as the books record that vendor (`PaymentBookedLikeBooks`: bills -> AP_CREATION paid from the bank line; cheques/cards -> EXPENSE_PURCHASE), with account and tax from the books. ONE history entry is enough for this case (`books_payment_min_entries`, Amin: "that one entry is what the accountant did"); elsewhere the minimum stays 3. A vendor unknown to the books still waits for its invoice.
- Still NOT from the books (needs the accounting team): bill vs direct purchase (suggestion only), the date of a bill. My interpretation: Amin wants these too once the team answers.
- It only works for a company whose books we hold. Axle's real books are in Desktop: check whether its history is imported before promising results.
- cp-547 and cp-548 are LIVE on prod (96e1b78b, verified by Amin 2026-11-20 on the Comfort row). cp-548: a vendor the books do NOT know: the engine works out nothing; the accountant answers on the row with `PaymentWithoutBill.jsx` ("Expense, no invoice" / "Bill with tax": any code, editable figure / leave it waiting), `POST /recordkeeping/{transaction}/book-payment`. Amin's rule: the tax must be a choice of every code with a changeable amount, never a fixed 13%.
- cp-549 (31e5461b, LIVE, verified by Amin 2026-11-20; cp-550 adds a "recorded as" line under the entry: kind + tax): the same answers under the Bank Reconciliation line (`BankLinePresenter::entry()` -> `awaiting_invoice`). Amin's standing expectation: what the Record Keeping drawer offers for a row must also be reachable on the bank line, no trip between pages.
- "My upload did not go to the OCR" (Amin, 2026-11-20/21, health check fine): the cause was an IDENTICAL file uploaded before (`tryReuseByChecksum` replays the cached reading). Check that first; next a digital PDF with a text layer (read locally, never sent to OCR), last `OCR_ENABLED`. Shahab fixed the dropped two-column value on 2026-11-20 (service falls back to `layout_text`; `boxes=1` gives per-line box + score, diagnosis only).

## cp-551 (2026-11-21, LIVE 2d1ca2fe, confirmed by Amin): the company is checked against the document
Amin's order for choosing a row's company (2026-11-21): the ACCOUNT NUMBER first, then the COMPANY NAME, then everything else; "there is always something on the document to link it to the right company". Case: row 2533, a BMO deposit slip with no name and account 1473-851 landed under "1940844 Ontario Inc" because the model named it and `ClientRegistryMatcher` accepts any registered name. `CompanyFromBooks::checked()` now checks a named company: written on the document stands; else account number; else the name written; else the books; else it stays. The slip itself was a 2025 file uploaded by mistake (human error), not a misread date.

## cp-552 / cp-553 (2026-11-21, LIVE e23b956c, verified by Amin's screenshots)
cp-552: the ONE registered account a document's number names becomes the row's bank account (no "funding account ambiguous"), and the replaced company's name leaves the row's own From/To side. cp-553: OCR returns a boxed account number ("1473-851", one digit per box) as two separate runs ("0 0 2 2 1 4 7 3" ... "8 5 1"); `HistoricalContextService::numbersIn` joins each boxed run to the next. To diagnose such a row: `business_event_modifiers.company_from_history.source` (bank_account / document_name / history) and the attachment's `ai_extract_raw.document_text`.

## checkpoint-554 (2026-11-23, LIVE 55071cad, verified on prod by screenshots)
A cheque whose payee is the row's own company and whose payer is someone else (not a client company or bank account) is money received: `ClientRegistryMatcher::chequeReceived` flips it to revenue, payer as customer, AR_COLLECTION, modifier `direction_corrected` (payer, payee). `TransactionDraftValidator`: a printed date with an unreadable year ("22C -9 01") keeps month and day, year = latest not after today, status resolved_by_window. From prod row 2559 (Illstyl3 Sammies cheque 6,107.65, 2026-09-01). Local full `tests/Feature` run does not finish (SameBooks test hangs; `artisan test` child hits 512M): run folders with `php -d memory_limit=4G -d max_execution_time=0 vendor/bin/phpunit <folder>`.

## checkpoint-556 (2026-11-23, awaiting push + prod test)
`CompanyFromBooks::writtenInShort`: a company the reading named stands when the document writes the leading words of its name ("Home Leader" for Home Leader Realty Inc), before history. Amin agreed 2026-11-23: name on the document beats the books; who paid is asked on the bank line (cp-555). cp-555 + cp-556 LIVE 54dc396a, note seen on prod 2026-11-23 (Move button click not yet confirmed).
