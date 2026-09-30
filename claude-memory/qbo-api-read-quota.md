---
name: qbo-api-read-quota
description: "Intuit counts QBO READ calls (CorePlus) against a workspace-wide monthly quota; our 15-min CDC deletion watcher alone uses ~2,880 reads per connected company, so Builder's hard 500K cap is hit at ~130 companies."
metadata:
  node_type: memory
  type: project
  originSessionId: 668f5f60-13cc-428f-8e31-aa15415e6a13
  modified: 2026-09-29T21:36:04.751Z
---

Intuit App Partner Program (guide v1.2, Mar 2026): writes (Core) are free and unlimited; reads (CorePlus: queries, GET, CDC, reports) are counted per developer WORKSPACE. Builder (our tier as of 2026-09-29, free) = 500K reads/month, HARD block until month end. Silver ~$300/mo = 1M free then $3.50 per 1,000; Gold ($1,700, needs 500 connections) and Platinum ($4,500, 3,000) cannot be bought. Payroll API (Premium) needs Silver+.

Code audit 2026-09-29 (va-dashboard2): `quickbooks:watch-deletions` runs every 15 min, 1 CDC call per company with live pushed entries = ~2,880 reads/company/month (~80% of our reads). Each push also READS first (account list, TaxCode, TaxRate queries; resolver cache lives one job only), so hitting the cap breaks pushes too, not just reads. No Intuit webhooks, no read counter anywhere. Estimate ~3,500-4,000 reads per active company per month → Builder cap at ~125-140 companies; on Silver overage that is ~$13/company/month, more than the per-client price we proposed.

Also verified 2026-09-29: Intuit Payroll API (Premium, beta) returns NO data for non-US companies, so Silver buys nothing for Canadian payroll; our pay-stub → JournalEntry plan works on Builder (writes free). QBO has NO reconciliation API (cannot mark reconciled, cannot read "For Review" bank-feed lines): for QBO clients our bank rec = statement vs register pulled once as a report (~10-20 reads/account/month), final reconcile stays in QBO. Webhooks are not metered. Intuit Builder = forum support only (ticket closed 2026-09-29). Failed payment on a paid tier: 27 days grace, then ALL calls blocked incl. writes. Program excludes Quebec-based partners. Pricing page v4 (claude.ai/artifact/L6jrvoNCU12seYXTRQVmwo) carries all of this.

**Why:** QBO reads, not AI (~$0.30/client), can become our biggest per-client cost and a platform-wide outage.
**How to apply:** before launch or pricing sign-off: add a counter in `QuickBooksService::get()`, move the watcher to Intuit webhooks or hourly, cache account/tax lists across jobs. Pricing context: [[growth-marketing-center-plan]], [[payroll-hr-architecture]], [[quickbooks-push-idempotency]].
