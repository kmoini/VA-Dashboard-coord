---
name: payroll-hr-architecture
description: "Master plan for payroll & HR stack (Bigcapital + Frappe HR + custom engine) — Canada + US, open-source-first, ADP deferred. READ BEFORE starting any payroll work."
metadata: 
  node_type: memory
  type: project
  originSessionId: ce8bc17e-29ca-4188-a387-f2de591b5d26
---

# Payroll and HR Architecture Decision

**Status:** Approved, NOT YET BUILT. Bring this plan up when payroll work begins.

**Why:** ADP/Deel/Rippling cost is too high for early stage. Company is willing to own compliance internally. Migrate to commercial payroll when employee count or complexity justifies it.

## Selected Stack

| Layer | Tool |
|---|---|
| Accounting / GL | Bigcapital (already live) |
| HR & Employee Management | Frappe HR |
| Payroll Calculation | Internal payroll engine (custom) |

## System of Record Split

- **Frappe HR** owns: employees, salary structures, attendance, leave, payroll periods, payslips
- **Bigcapital** owns: general ledger, payroll expenses/liabilities, financial reporting

## Canada Requirements

**Calculate:** Federal income tax · Provincial income tax · CPP employee + employer · EI employee + employer

**Track liabilities:** Income Tax Payable · CPP Payable · EI Payable · Vacation Pay Accrual · Benefits Payable · Bonus Accruals

**Generate:** Payroll journal entries · T4 data · T4 Summary

**Remittance:** Monthly or accelerated CRA remittances via CRA My Business Account

**Source of truth:** Published CRA payroll deduction formulas and tables (NOT screen-scraping PDOC). PDOC is for verification/testing/regression only.

## United States Requirements

**Calculate:** Federal withholding · Social Security · Medicare · FUTA · State income tax · SUTA

**Generate:** Payroll journal entries · W-2 data · W-3 data

**Remittance:** IRS EFTPS + state tax portals

**Source of truth:** IRS withholding formulas + federal/state payroll tax tables. No runtime dependency on government calculators.

## Key Design Principles

1. Government calculators (CRA PDOC, IRS withholding calculator) = verification/testing only, never runtime dependencies.
2. All payroll formulas implemented directly from published official sources.
3. Payroll liabilities, remittances, and year-end forms maintained internally.
4. Bigcapital accounting architecture is NOT replaced when/if migrating to commercial payroll later.

## Growth Phases

**Phase 1 (current target):** Bigcapital + Frappe HR + custom engine · Canada primary + limited US · ~20–30 employees

**Phase 2 (scale trigger):** Multiple states/provinces, complex benefits, large workforce → evaluate ADP / Deel / Rippling / Dayforce WITHOUT changing accounting (Bigcapital stays).

**Why:** Lead with it — don't rebuild the stack unless payroll complexity genuinely demands it.
