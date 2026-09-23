---
name: canadian-standard-chart-of-accounts
description: "⚠️⚠️ The accounting team's Canadian_COA_QuickBooks_With_GIFI.xlsx has a FABRICATED GIFI column (revenue at 4000, CRA uses 8000). Its COA half is good and is now App\\Accounting\\CanadianChartOfAccounts with real CRA codes. Read before chart-of-accounts, GIFI mapping or that spreadsheet."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-22T19:20:18.704Z
---

The accounting team supplied `Canadian_COA_QuickBooks.xlsx` and
`Canadian_COA_QuickBooks_With_GIFI.xlsx` (Amin's Downloads, 2026-09-22). 165
accounts, ASPE, Canadian private enterprise. The first seven columns of both
files are identical; the second adds two GIFI columns.

**⚠️⚠️ THE GIFI COLUMN IS NOT CRA GIFI. Do not use it, and do not let it come
back.** Verified against CRA's own RC4088 page, not just our reference:

- it claims revenue is 4000-4999 and cost of sales 5000-5999; CRA uses
  8000-8299 and 8300-8519, and Schedule 125 runs 8000-9999
- 81 of its 150 codes sit in 4000-7999, which CRA does not use for anything
- 8299 "Total revenue" and 9060 "Salaries and wages" are absent entirely
- where a number does exist in CRA's index it means something else: its 1060 is
  "Petty cash" (CRA: accounts receivable), 1400 is inventory (CRA: due from
  related parties), 8100 is donations (CRA: interest income of fin. institutions)

Almost certainly AI-generated: the rest of the workbook is accurate, which is
what makes the column dangerous. Amin could not reach the team to confirm and
told me to do the right thing, so the COA half was taken and the GIFI half
rewritten.

**✅ SHIPPED (commit after `e53b9e4`):**
- `App\Accounting\CanadianChartOfAccounts`, 165 accounts with QuickBooks type +
  subtype + tax code + a REAL CRA GIFI code, all pinned by
  `CanadianChartOfAccountsTest` (code exists in CRA's index, right side of the
  books, subtype allowed under that type).
- ⭐ **The type column now shows QuickBooks' UI spelling.** Three of the fifteen
  differ from the API: `Accounts Payable (A/P)`, `Accounts Receivable (A/R)`,
  `Long-Term Liability`. THIS is most of why the mapping list kept being
  reported as non-standard, after I had already matched the right 15 types.
- Chart of Accounts pre-fills the GIFI box of every UNMAPPED account
  (`AccountingController::suggestGifiFor`): standard chart by name first, then
  `GifiResolver`. Nothing is saved until the accountant leaves the field.
- `NothingBlocksApproveAndPushTest`: save → map → approve → push with GIFI 8299
  end to end, so the removed refusals cannot creep back one layer at a time.

**⚠️ Gotchas:**
- CRA nets a gain and a loss on ONE line (8231 FX gains/losses, 8210 realized
  gains/losses), so an EXPENSE account correctly carries a revenue-side code.
  `CanadianChartOfAccounts::isTwoSided()` is the only side-check exemption.
- The file's Detail Type column is QuickBooks' UI wording, not API values; only
  32 of 87 matched as written. It also puts recoverable GST/HST under "Sales Tax
  Payable", which QuickBooks only offers on a liability.
- ⏭️ The 165 GIFI codes are MY reading of RC4088. The team still needs to review
  them; `CanadianChartOfAccounts` is the review document.

Related: [[never-overrule-the-accountant]], [[accounting-team-qbo-complaints]],
[[gifi-qbo-account-mapping]], [[international-quickbooks]].
