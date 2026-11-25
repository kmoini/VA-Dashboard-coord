---
name: push-failures-for-people-and-support
description: FEEDBACK 2026-11-24, Amin: a user must never see a provider's raw error; every failure needs something support can be handed to know where and what failed
metadata:
  type: feedback
---

Amin, 2026-11-24, on seeing `QuickBooks createPurchase failed HTTP 400: {"Fault":...` on the Bank Reconciliation line: "the customer must not see the error like this" and "there should be something they can give the support team so it knows where and what the error is".

**Why:** the product is sold on ease; raw JSON on a screen reads as broken, and support could not locate a failure from a screenshot.

**How to apply:** any failure shown to a user is one plain sentence (what happened, that nothing was recorded, what to do), names the object at fault when it can be found, and carries a reference with a copyable block for support. Raw provider text goes to storage and logs only. Built for QuickBooks pushes in checkpoint-569: `App\Integrations\PushFailure` (explain / display / supportText / reference `QB-<base36 sync id>-<hash>`), `transaction_integration_syncs.error_detail`, `php artisan support:push-error <ref>`, doc `docs/PUSH-FAILURES-FOR-PEOPLE-AND-SUPPORT-2026-11-24.md`. My interpretation: the same standard applies to new error surfaces elsewhere (OCR, uploads, email intake), not only pushes.

Related: [[no-dash-in-frontend]], [[automate-dont-add-manual-steps]], [[qbo-push-tax-needs-mapping]].
