---
name: multi-currency-fx
description: "Multi-currency base-normalisation (model A / QuickBooks-style) DEPLOYED to prod — checkpoints 119-122 (core pipeline, worker-timeout fix, Gemini currency de-bias, self-serve books currency + FX catch-up + portal soft-delete). READ before touching amounts/currency/reports/projector."
metadata: 
  node_type: memory
  type: project
  originSessionId: 450de5d9-ae01-4f79-89e6-572e5d8cbbf6
---

Multi-currency normalisation for `va-dashboard2`, decided with Amin (2026-07-04):
model A (ledger `amount/currency` ALWAYS the client's base; original preserved),
free provider chain (Bank of Canada for CAD pairs — CRA-accepted — else
ECB/frankfurter), per-client base override from day one, backfill for existing
rows. Full doc: repo `docs/multi-currency.md`.

**Architecture:** `TransactionObserver` created/updated → dispatch
`ConvertTransactionCurrencyJob` (afterCommit) → `FxRateService` (permanent
`fx_rates` cache, one API call per date+pair ever) → normal `save()` so the
conversion itself is audit-logged + version-bumped. Rate ALWAYS at
`effective_date`; no date → stays unconverted (amber `USD → CAD?` chip) until a
date is set. locked/tax-submitted rows never touched. `fx_source=manual`
(accountant pins a rate in the details panel) is never auto-overwritten —
also the only path for IRR (official rate meaningless; ECB/BoC don't carry it).
Date edit → auto re-rate FROM the original. Base = clients.base_currency ?:
firm default_currency (Settings widened from 4 to ~31 currencies;
`FxRateService::BASE_CURRENCIES` mirrored in resources/js/constants/currencies.js).

**Gotchas learned:**
- MobileTransactionProjector rewrites amount/currency from the feed EVERY poll
  while pending → added FX guard (incoming == stored original → keep converted)
  or conversion would ping-pong forever.
- PowerShell Get-Content/Set-Content mangled UTF-8 (em-dashes → mojibake) in
  ClientsController; had to git checkout + redo with the Edit tool. Never bulk
  regex-replace PHP files via PS 5.1.
- Client Master File saves via `clients.update-registry` (NOT clients.update) —
  base_currency had to be added to BOTH validations + the show() serializer.
- SettingsController is also touched by the uncommitted SES work → next
  checkpoint needs surgical staging again for it.

**Verified live:** BoC USD→CAD 2024-01-24 = 1.3484 (weekend resolves to prior
business day), CAD→USD inversion, EUR→GBP via ECB, IRR→null, cache hit; full
chain e2e: created USD 45.50 → auto-converted CAD 61.35 by the running worker,
audit log + version 2. `php artisan fx:backfill [--dry-run|--client=]` queues
existing rows (skips locked/dateless).

**Full-matrix verification (2026-07-04):** all 32 convertibles returned live
rates →CAD (mix of boc/ecb) + cross pairs ✓; all 13 unsupported (IRR, AED,
SAR, RUB, EGP, NGN, UAH, PKR, BDT, VND, ARS, CLP, COP) → NULL ✓; e2e real
transactions: JPY/PLN/PEN auto-converted, all 13 unsupported stayed pending
(amber row, manual-rate path) ✓. **BGN gotcha:** Bulgaria adopted the euro
2026-01-01 → ECB stopped publishing BGN; added `fixedEuroBridge()` in
FxRateService (legal irrevocable 1 EUR = 1.95583 BGN, source 'eurofix',
const EURO_FIXED extensible for future euro adopters) — BGN now works for
both eras. Currency mislabeling incident: Gemini stamped ALL 8 international
receipts (£/€/A$/ریال) as CAD → fixed by enum-locking `currency` in the
response schema (ISO codes only, no '' member — Gemini 400s on empty enum),
anti-normalisation prompt rule (document's currency NEVER the books'), unknown
falls back to CLIENT base (validator $fallbackCurrency param; email path
untouched = CAD), and extras.model_currency debug provenance. UI: fx-pending
rows get a whole-row AMBER tint (frozen cells matched).

**Self-serve books currency (2026-07-05, COMMITTED checkpoint-122 9949250 + deployed):** client-portal
Settings gained a "Books currency" card (ClientPortal/Settings.jsx +
ClientPortalController::updateBooksCurrency + PATCH
/client/settings/books-currency) — self-serve users with no accountant pick
their own functional currency (31 options, writes clients.base_currency,
audit-logged, BaseCurrencyResolver::flush). QuickBooks-style guard: with
existing transactions the switch needs an explicit confirm checkbox and
NOTHING is restated — old entries keep their currency, only new ones use the
new base. Extended same day: opt-in **convert_existing** checkbox on switch +
a CATCH-UP panel ("N entries still in another currency → Convert to {base}")
for the already-switched state — dispatches ConvertTransactionCurrencyJob per
unlocked dated row (reconvert-from-original when original_currency set;
manual-rate rows skipped), each at its document-date rate. Same day: shared
`FxHistoryConverter` service extracted (portal + accountant use identical
eligibility rules) + ACCOUNTANT-side twin: PATCH /clients/{client}/
convert-currency (ClientsController::convertCurrency, ClientPolicy update) +
amber catch-up panel under the Books-currency select in Clients/Show
(ProfilePanel, fx prop via usePage). Catch-up button LOCKS after one click
(earlier confusion: single worker drains serially, user thought 1 click = 1
conversion; also fixed re-queue of already-converted rows). Same round enabled
portal bulk SOFT-delete (TransactionPolicy::delete → clientOwns() self-manage;
the ledger's portal permission branch had a hardcoded delete=false — fixed in
TransactionsController; forceDelete stays unconditionally false). All shipped
as checkpoint-122 (9949250, 2026-07-06) + prod webhook deploy (build OK). No
migrations, no queue:restart needed that round.

**checkpoint-121 — the CAD-stamping root cause (2026-07-04 night):** with all
of cp-119 live, the model STILL returned currency=CAD for explicitly-foreign
receipts. Two-part cause, verified by live probes: (1) the prompt's "Canadian
small-business bookkeeping engine" framing outweighed the currency-evidence
rule → de-biased to a neutral engine + CRITICAL never-convert block with
concrete £/€/A$/ریال examples; (2) with currency OPTIONAL in the schema the
model then OMITTED it even for explicit £ receipts → made currency REQUIRED
(forced pick on truly-ambiguous docs ≈ the client-base fallback anyway).
After both: single-GBP probe ×2 and a 4-currency collage probe all correct,
incl. exact Persian-numeral IRR amounts. DURABLE PROMPT RULES: never
nationality-frame an extraction prompt; enum fields the model must fill go in
schema `required`. Also cp-120 same night: worker pcntl-kill fix (job
$timeout must exceed total internal HTTP budget; GeminiClient now ONE retry).

**Status:** checkpoints 119 (4c197c2 core) → 120 (worker timeout) → 121
(Gemini currency de-bias) → 122 (9949250 self-serve books currency + FX
catch-up portal+accountant + portal soft-delete) ALL pushed + prod-deployed
via webhook. SES work kept out via surgical staging every time (web.php the
fourth time). Prod migrate/queue:restart/fx:backfill for cp-119 were DONE by
Amin 2026-07-04 and verified live (24 USD rows converted via BoC; 22 IRR
pending by design; 2 IRR receipts still await Amin's manual rate). cp-122
needed no migration/queue:restart. Amin still owes prod php.ini bumps
(max_file_uploads=100, upload_max_filesize=30M, post_max_size=100M) + the
optional Supervisor AI pool (--queue=ai ×6 + AI_QUEUE_NAME=ai).
