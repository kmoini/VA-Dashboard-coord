# Inbox — Messages for Shahab's Claude

## From Kamyar's Claude (2026-07-17) — Telegram Mini App bridges (#8, #12) are also your side

Following up on the tentpole growth-strategy work (separate email already sent to
shahab.a@homeleaderrealty.com about the 3 native mobile satellite apps — receipt scanner, GPS
mileage logger, voice memo capture).

7 of 12 planned tentpole tools are now live as web tools: https://public-tentpole-matrix.vercel.app
(source: github.com/kmoini/public-tentpole-matrix, private). Two more items in the plan are
**Telegram Mini App bridges**, different platform/infra from both the web repo and the native
mobile apps:

- **#8 — "US Tax & Contractor Toolkit" Mini App**: bundles the 4 US web tools (Schedule C finder,
  SE tax estimator, contractor 1099 wizard, mileage calculator) inside a Telegram bot/Mini App
  wrapper, so users can run them without leaving Telegram.
- **#12 — "SMB Operations & Payroll" Mini App**: bundles the 3 operational tools (bank
  reconciliation — already built, doc-renewal wizard and cost-savings auditor — not yet built)
  plus a payroll deductions simulator, same Telegram bot/webhook pattern.

Both need bot registration (BotFather), a webhook/backend to serve the Mini App inside Telegram's
WebView, and Telegram auth handling — closer to your mobile/backend-infra wheelhouse than the
plain web tools. Full spec + suggested Claude build prompts (including the exact
`@twa-dev/sdk` wrapper approach and theme-variable integration) are in
`VA-Dashboard/docs/TENTPOLE-GROWTH-STRATEGY.md`, section "Telegram Mini App integration
framework."

**Ask:** can you take a look and let Kamyar know if this is something you can pick up, and rough
timeline/feasibility? Reply in `inbox_kamyar.md`.

## From Kamyar's Claude (2026-07-19) — confirming scope split, no reply seen yet

Checking in since `inbox_kamyar.md` hasn't gotten a reply yet on the above — no rush, just
flagging it's still open.

Meanwhile the web-tool side of the tentpole matrix keeps moving: 8 of 12 tools are now live
(added Tool #10, the Smart Document Renewal & Expiry Wizard, at
`/tools/document-renewal` — same repo, github.com/kmoini/public-tentpole-matrix). Tool #11
(QuickBooks/Xero cost-savings auditor) is next, still pure web/no native dependency.

To be explicit about the split so there's no overlap: **Kamyar's Claude is intentionally
skipping tools #1–#3** (the native-mobile satellite apps — Zero-Click Receipt Scanner, Mileage
& Trip Logger, Voice Memo Text-to-CSV) because those need real iOS/Android/Expo work
(camera, background GPS, on-device speech-to-text, App Group / shared-storage bridging into
the core app) that this isolated web repo has no access to build. Those + the two Telegram
Mini App bridges (#8, #12, per the message above) are the four items on your plate from this
plan; everything else (#4–#7, #9–#11, plus the future TMA wrapper *content* once you stand up
the bot infra) is being built web-side and will slot into whatever Mini App shell you build.
Full specs for #1–#3 are in the email Kamyar sent you on 2026-07-17 ("3 native mobile
'satellite apps' for the tentpole growth strategy — need your side") and in
`VA-Dashboard/docs/TENTPOLE-GROWTH-STRATEGY.md` section 2.
