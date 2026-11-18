---
name: stripe-payments-architecture
description: "Stripe payment architecture for VoiceAccountant - audit 2026-11-14 found NO Stripe account connected; two money flows must stay separate (central account for platform revenue, Stripe Connect for accountant-to-client invoices); firm bank details + manual payment recording not built"
metadata:
  node_type: memory
  type: project
  originSessionId: 4ceb2498-7cff-4678-be7b-b3c7e902a515
  modified: 2026-11-14T15:23:57.634Z
---

Read-only audit + architecture decision set, 2026-11-14, answering Amin's question about
how payment should work for accountants, firms, and their invited clients. **Nothing was
built in this session and Amin has NOT yet picked a phase to start.**

## FINDING 1: the dashboard is connected to NO Stripe account

`va-dashboard2/.env` and `.env.example` both carry EMPTY placeholders:
`STRIPE_KEY=pk_test_`, `STRIPE_SECRET=sk_test_`, `STRIPE_WEBHOOK_SECRET=whsec_`,
`STRIPE_PRICE_STARTER` / `PROFESSIONAL` / `ENTERPRISE` = `price_`.

So locally no account is wired. **Production was NOT verified** (no access from this
session) - run `grep STRIPE` on the prod env on node5126 to confirm. If prod is also
empty, every payment path silently fails in production today.

The failure is easy to miss: `BillingService::stripe()` is deliberately lazy-loaded
(the service is instantiated on EVERY request via the Inertia shared billing prop), so a
missing key does not crash the app, it only throws at the first API call.

## What IS already built (code complete, waiting only for keys)

| Piece | Location |
|---|---|
| Customer + Checkout + Billing Portal | `app/Services/BillingService.php` |
| Webhook + idempotency | `StripeWebhookController.php`, table `stripe_webhook_events` (migration `2026_02_21_000005`) |
| 3-tier subscription | `config/services.php` -> `services.stripe.prices.*` |
| Dedicated number purchase | `app/Services/Marketing/NumberBillingService.php` |
| `stripe_customer_id` on firm | migration `2026_02_21_000001` |
| Billing UI | `resources/js/Pages/Billing/Index.jsx` |

**No Stripe JS anywhere in the frontend.** All 52 Stripe-touching files are PHP /
config / migration. Billing/Index.jsx only does `router.post('/billing/checkout')` and
`router.post('/billing/portal')` with a server-side redirect. `@stripe/stripe-js` and
Elements are NOT installed.

## DECISION: two money flows, never merged

**Flow A - money comes to us.** Accountant/firm -> VoiceAccountant: subscription,
phone numbers, SMS/AI overage. **One central Stripe account is correct here** and is
what is already coded. Each firm = one Stripe Customer with
`metadata.accountant_account_id`.

**Flow B - money goes to the accountant.** Client -> accountant, for invoices the
accountant issues.

**Flow B must NEVER pass through our central account.** Taking the client's money into
our balance and paying the accountant out makes us a Money Services Business under
FINTRAC in Canada (registration + reporting) and directly violates Stripe's ToS
("no payment aggregation"), which can close the main account and kill Flow A too.

Correct: **Stripe Connect, Express accounts.** Each firm onboards once (Stripe runs
KYC), store `stripe_connect_account_id` on `accountant_accounts`, funds land in the
accountant's own balance, we optionally take `application_fee_amount`. This was already
the documented intent: `docs/invoicing.md` says Phase 1 is generate+send+track and
"Online card payment (Stripe Connect) is a deliberate later phase".

## Tenant model

| Entity | In Stripe | Stored |
|---|---|---|
| Firm / independent accountant | Customer on OUR platform account (subscription, numbers, usage) + its own Connected Account (to receive client money) | `accountant_accounts.stripe_customer_id` + new `stripe_connect_account_id` |
| Accountant's invited client | Customer on the FIRM's connected account, NOT on ours | new column/table, firm-scoped |

## Accountant bank details page: YES, needed (not built)

Card fees make the manual path mandatory, not optional: 2.9% + 30c on a $5,000 invoice
is $145, no accountant accepts that. Most Canadian clients pay by e-Transfer.

Today `invoices` has only `status` / `paid_at` / `amount_paid_cents`; `markPaid()` just
flips status. No transaction reference, no payment method, no firm bank info anywhere.

**(a) `firm_payment_instructions`** - bank name, account number, Transit/Institution
(CA), Routing (US), IBAN, SWIFT/BIC, beneficiary address, e-Transfer email, free-text
instructions, per-method enable flag.

Non-negotiable security rules:
- all sensitive fields use Laravel's `encrypted` cast, never plain text
- UI shows last 4 only; full value only on the invoice PDF
- edit restricted to `role.min:4` (firm owner), not Editor - changing a firm's bank
  account is a classic fraud vector
- log every change to `activity_logs`, and **add the migration for the new
  entity_type/action first** or the Postgres CHECK constraint rolls back the whole
  transaction as an unrelated error (see [[activity-log-entity-type-trap]], bit us 4x)

**(b) `invoice_payments`** - `invoice_id`, `method` (stripe / e_transfer / wire_swift /
iban / other), `amount_cents`, `reference_number` (the transaction number Amin asked
for), `paid_on`, `reported_by`, `status` (reported / confirmed / rejected),
`confirmed_by`, `confirmed_at`. Flow: client pays, enters the reference in the portal,
invoice -> `payment_reported`, accountant is notified and confirms -> `paid`. The
confirm step matters: the client must never be able to mark an invoice paid itself.
`amount_paid_cents` already supports partial payments.

**(c)** `resources/views/invoices/pdf.blade.php` needs a "Pay online" (Connect link)
and a "Pay by transfer" block.

**Western Union: do NOT add as a structured method.** Use the free-text "other
instructions" field. Not used for B2B and a strong AML red flag.

## Payment method before buying a phone number

Current reality: `NumberController::checkout` goes straight to Stripe Checkout, which
collects the card inline, so buying a number WITHOUT a stored card already works and is
not blocked.

A saved payment method is still needed for **usage** charges (SMS, ringless voice, AI
overage) which cannot open Checkout each time.

**Simplification found:** no SetupIntent + Elements build needed. The Billing Portal is
already wired; pass `flow_data` with `type: 'payment_method_update'` in
`createPortalSession` and the user lands directly on the add-card screen. So phase 1 is
just `BillingService::hasDefaultPaymentMethod(firm)` **with a ~5 min cache** (same
`CACHE_TTL = 300` pattern as subscription status - BillingService runs on every request
via the Inertia shared prop, so an uncached Stripe API call there would slow the entire
dashboard), plus a gate that swaps the primary button for "Add payment method".
Elements only if we later want the card form inside our own dashboard; not worth it now.

## Also blocked on having a real Stripe account

Referral rewards. `app/Services/Marketing/ReferralRewardService.php` comment: "the
ledger never touches Stripe - platform admin approves, **Amin applies the credit in
Stripe**, the row is marked posted". Approved referrals pile up unposted until the
account exists. See [[growth-marketing-center-plan]].

## Bug found in passing

`NumberBillingService::checkout` hard-codes `'currency' => 'usd'`, but
`accountant_accounts.default_currency` defaults to **CAD** and the whole invoicing
system is CAD. Canadian firms get an FX conversion fee on their card statement.
Needs unifying. See [[multi-currency-fx]].

## Proposed phase order (awaiting Amin's pick)

| Phase | Work |
|---|---|
| **0** | Create the real Stripe account, Products/Prices for the 3 tiers, keys into the PROD env, register the webhook, full E2E with a test card. Everything is coded but has never run against real Stripe. |
| **1** | `hasDefaultPaymentMethod` + cache + Billing Portal `payment_method_update` link + gate on usage actions |
| **2** | `firm_payment_instructions` + `invoice_payments` + report/confirm flow + invoice PDF update |
| **3** | Stripe Connect Express: onboarding, client card payment, webhook -> auto-mark-paid |

Keys go ONLY in the prod env, never in any repo file. See [[autocommit-leaks-secrets]].

## Update 2026-11-17: production DOES have Stripe test keys

Amin ran a masked check on node5126 (prefix + length only, never the value): `STRIPE_KEY` = pk_test_ (108 chars), `STRIPE_SECRET` = sk_test_ (108 chars), `STRIPE_WEBHOOK_SECRET` = whsec_ (39 chars); `STRIPE_PRICE_STARTER` / `PROFESSIONAL` / `ENTERPRISE` are still placeholders (so the three-tier subscription checkout has no price to sell). TEST mode: no real money moves. His LOCAL `.env` is still all placeholders. The masked check command is in the financial reports session; never ask for or print the values.

Three Stripe code paths now exist and must not be confused: (1) `App\Services\BillingService` (subscriptions, Checkout, Billing Portal, customer on `accountant_accounts.stripe_customer_id`); (2) usage billed at month close as a Stripe invoice item, `App\Services\Marketing\OverageBilling` + `BillMarketingOverageJob` (the closest precedent for charging per report); (3) the colleague's SameBooks billing, `App\SameBooks\Billing\Stripe\StripeGateway` (SetupIntent + PaymentIntent, saved card, own webhook, `FakeStripeGateway` for tests; contract in va-dashboard2 `docs/SAMEBOOKS-BILLING-CONTRACTS.md`; its rule: every Stripe call of SameBooks goes through the gateway and BillingService stays untouched).

## Direction from Amin 2026-11-17: billing model NOT decided, build the base only

Amin: how the whole product charges customers is still undecided; the team is thinking about a CREDIT system. "You and I are building the base, first version now, and we complete it after the decision." So: do NOT build charging, prices, allowances, card capture or invoices for reports (or anything else) until he says the model is decided. Keep what is built neutral to the model: count every request, record who pays, show usage. Do not ask him again for a price or for invoice-versus-per-report: those wait for the model decision. He also relayed my question to the colleague (may reports use the SameBooks StripeGateway?) and will pass on the answer.

## Colleague's ruling on the SameBooks gateway (2026-11-17, relayed by Amin)

Same Stripe account and keys for other dashboard payments: fine. Do NOT call or edit `App\SameBooks\Billing\Stripe\*` (SameBooks' contract: on-session only, own metadata `purpose`, own webhook, nightly `samebooks:billing-reconcile`, own tests). Build new dashboard payments beside `BillingService` / `StripeWebhookController`: SetupIntent `usage=off_session` to save a card, off-session PaymentIntents with an idempotency key each, a distinct metadata purpose (e.g. `va_reports`) so SameBooks ignores them, a decline is a normal result, never log keys or card details. A shared gateway, if ever wanted, is extracted together with SameBooks' tests kept green.
