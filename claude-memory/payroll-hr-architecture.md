---
name: payroll-hr-architecture
description: "Master plan for payroll & HR stack (Bigcapital + Frappe HR + custom engine) — Canada + US, open-source-first, ADP deferred. READ BEFORE starting any payroll work."
metadata: 
  node_type: memory
  type: project
  originSessionId: ce8bc17e-29ca-4188-a387-f2de591b5d26
  modified: 2026-09-28T23:38:27.059Z
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

## ✅ AGREED 2026-09-28 (Amin): payroll RECORD-KEEPING push to QBO — WAIT for Amin's "start"

Do not build until Amin says go. Agreed shape:
- Client sends pay stub / payroll register (from their own provider: ADP, Wagepoint, QBO Payroll...) → AI EXTRACTS (never calculates, so no CRA rule updates needed) → multi-line payroll record in our system → accountant reviews → one-click push as QBO **JournalEntry**.
- No separate API: same QBO connection/scope. Current push knows only 6 single-amount entities (QuickBooksEntityMapper: Purchase, Bill, SalesReceipt, Deposit, VendorCredit, RefundReceipt); generic QuickBooksService::createEntity already posts any entity name.
- To build: own multi-line payroll table (not transactions), prompt in the registry ([[ai-prompt-registry]]), deterministic checks (gross − deductions = net; employer EI ≈ 1.4× employee; employer CPP = employee CPP; debits = credits is the ONLY hard gate because QBO rejects unbalanced JEs, others are warnings), per-line-type account mapping chosen by the accountant (incl. CWELCC-style liability lines), Employee sync (JE lines reference Employee), review UI + push.
- ⚠️⚠️ Double counting: pay stubs are kept out of the ledger today ([[document-role-triage]]) and the bank feed brings the net-pay withdrawal + CRA remittance separately. Payroll must LINK those bank rows to the pay run, never push them again as Purchases.

## Open-source engines (colleague's AI suggestion, checked 2026-09-28)

Only relevant if we ever CALCULATE payroll (path B), not for the agreed record-keeping plan.
- LineLedger (github.com/lineledger/lineledger): real, AGPL-3.0, v1.1.0 2026-09-18, full accounting + CA payroll; its own docs warn payroll constants may be incomplete/wrong.
- "T4127-Engine, 92,000+ tests": could NOT be found; treat as unverified/possibly hallucinated.
- Found instead: takehome (github.com/GautamTalksDev/takehome): Apache-2.0 (no AGPL issue), Rust + npm/PyPI, 13 jurisdictions, NO Quebec, PDOC agreement 8838/9002 with 164 one-cent diffs documented; v0.1.0, solo dev, 1 star. Good reference/test oracle, too young to depend on.

## QBO as the GL target (discussed 2026-09-28, Amin)

- Amin asked about payroll wired to QBO instead of Bigcapital. The engine plan is unchanged; only the ledger target moves.
- QBO public Accounting API has NO Canadian pay-run/paycheque endpoints (Intuit payroll APIs are US, partner-gated). So: our engine computes, then posts a JournalEntry per pay run (wages/employer CPP+EI expense, source-deduction liability, net pay) and a Bill/Check to Receiver General for the PD7A remittance. Reuse payload-derived idempotency ([[quickbooks-push-idempotency]]) and the account mapping ([[gifi-qbo-account-mapping]]); accountant picks accounts ([[never-overrule-the-accountant]]).
- The link Amin gave (apps.cra-arc.gc.ca/ebci/rhpd/beta/entry) is PDOC beta: a manual web calculator, no API. Source of truth stays T4127 (Payroll Deductions Formulas, new edition 1 Jan + 1 Jul) stored as effective-dated rate data; PDOC only for expected-value regression fixtures. Quebec needs Revenu Quebec formulas + QPP/QPIP separately.
- Amin's QBO Canada sandbox shows Payroll with a diamond (paid add-on, locked); sandbox can't subscribe. Real test path = a trial company, and even then no API to run Canadian payroll.
- Real client sample (Blue Butterfly Montessori, QB Desktop journal): one paycheque = gross lines + Ontario childcare grants (Provincial Wage Enhancement, CWELCC) paid as wages but debited to 24200/24205 liability accounts, employee CPP/EI/tax + employer CPP (1x) and EI (1.4x) to 24000 Payroll Liabilities, net pay credited to bank. The engine needs custom earning types that map to ANY account, not just wage expense.
- "Auto-update rules" answer: no CRA machine feed; safe version = detect new T4127, parse to a DRAFT rate set, run PDOC fixtures, human approves, activate by effective date. Alternative: clients use QBO Payroll (Intuit owns tables + accuracy), we only read results.
