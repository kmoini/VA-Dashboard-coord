---
name: qbo-push-tax-needs-mapping
description: A pushed line's tax goes only when our tax code maps to a tax code of that QuickBooks company; cp-559 finds it by rate or holds the push
metadata:
  type: project
---

First real pilot push, 2026-11-23 (client 87, connection 16 "Axle Corp.", row 2562 → Bill 22343): the bill went 406.80 "Out of Scope of Tax", HST 46.80 lost, because connection 16 had NO tax code mappings and its codes are named `hst` (id 26), `G`, `S`, `E`, `Z`, `P`, `M`. A duplicate supplier "Aurora Star Tech Inc." was also created beside "Aurora Star Tech Inc".

checkpoint-559 (commit below in git log, built 2026-11-23, awaiting push + prod test): `QuickBooksReferenceResolver::taxCodeByRate` (rate from the row's own tax/net, one active code with that single rate, name word as tie-break, saved `source=auto`); no fit → push held `needs_mapping`; `sameNameInQuickBooks` before any party create; `CheckPayment.PrintStatus=NotSet`. Due date not read from documents (not fixed).

Still wrong in the REAL books until Amin repairs it: Bill 22343 has no HST and the duplicate supplier exists. `ACCOUNTING_V2_QBO_VENDOR_MATCH` default is false; whether it is on in prod is unknown.

Pilot gate (Amin to Kamyar 2026-11-23): full Bank Reconciliation send to QuickBooks not yet tested end to end; QBO vs QuickBooks Desktop reports must be compared before the accounting team (Mahdi) starts testing.

Related: [[bank-reconciliation-workspace]], [[sales-tax-hst-gst]], [[think-like-a-quickbooks-accountant]].
