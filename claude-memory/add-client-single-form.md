---
name: add-client-single-form
description: "cp-247 (2026-09-19): ONE add-client form = the popup on /clients (MANUAL mode in Clients/Index.jsx); Clients/Create.jsx deleted, /clients/create redirects to /clients?add=manual. ⚠️ two forms had drifted and corrupted data. READ before touching client creation fields."
metadata: 
  node_type: memory
  type: project
  originSessionId: 874e2ef0-5494-42e8-8004-9a78a8cb856e
  modified: 2026-09-19T14:34:03.031Z
---

There used to be two add-client forms: the popup in `resources/js/Pages/Clients/Index.jsx`
and a `Clients/Create.jsx` page. The popup, the one actually used, had drifted:
its required "Corporation" was sent as `business_number` (company NAME in the tax
ID field), it never asked for the province (Canadian clients got 5% GST instead of
e.g. Ontario 13% HST, because `TaxRateResolver` needs the region), and its
"Additional Firm Info" was never sent.

Now there is one form (the popup) with the full field set. `ClientsController::create`
redirects to `clients.index?add=manual`, which opens it. The invite form's
Corporation travels as `referral_tokens.company_name` to the client created at signup.

Prod data repaired with `clients:move-company-out-of-business-number --apply`
(7 moved, 2 real numbers left alone). Tests: `tests/Feature/Clients/ClientAddFormTest.php`.

**Why:** duplicated forms drift, and the drift silently writes wrong data.
**How to apply:** add a client field in the popup only; never recreate a second
form. Amin deactivated all old companies except Kamyar Moini on 2026-09-19 so the
accounting team can start full testing.
