---
name: tentpole-satellite-tools
description: "Tentpole/satellite growth strategy execution status — all 7 web-buildable tools in the 12-tool matrix plus a bonus Payroll (FICA) Simulator are live at public-tentpole-matrix.vercel.app (local commits, not yet pushed/deployed as of 2026-07-19); 5 remaining matrix items are all Shahab's (3 native mobile + 2 Telegram Mini App bridges)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 316a8d1f-1edb-4b47-a849-f2aab83110cc
  modified: 2026-07-20T01:09:04.712Z
---

Built and deployed the "Tentpole Strategy" growth plan documented in
`VA-Dashboard/docs/TENTPOLE-GROWTH-STRATEGY.md` (2026-07-12, transcribed from a Gemini research
conversation): free, un-gated web micro-tools that hand off into the VoiceAccountant mobile app
via the real `voiceaccountant://record?text=...&type=...&autosend=...` deep link (confirmed by a
direct codebase scan — the app has no generic import route, only that one). Also produced
[[product-master-plan-doc]] (Sections 2/3A/3B/5 positioning update) in the same session.

**New repo:** `d:\projects\public-tentpole-matrix` — standalone Next.js 16 + Tailwind project,
zero dependency on VA-Dashboard/va-mobile source. GitHub: `github.com/kmoini/public-tentpole-matrix`
(private — created under kmoini's own account, NOT Amin88-hub, because collaborator access on
va-website doesn't grant repo-creation rights on someone else's personal GitHub account). **Live:**
https://public-tentpole-matrix.vercel.app (Vercel, `snap-dance` team scope, deployed via CLI
2026-07-17). ⚠️ Continuous deployment is NOT wired up — Vercel's GitHub App failed to auto-connect
to the repo on first deploy, so pushing to `main` does not trigger a redeploy; needs a manual
`vercel --prod` until someone grants the Vercel GitHub App access to the repo in GitHub settings.
Commits as of 2026-07-19 (through Tool #11) are local-only, NOT pushed/deployed yet.

**All 7 web-buildable items in the 12-tool matrix are now built** (all Playwright-verified against
`next start`, not `next dev` — `next dev`'s HMR websocket caused false-negative test flakiness
mid-interaction): #4 US Schedule C Finder, #5 US SE Tax Estimator, #6 US 1099-NEC Contractor
Wizard, #7 US+CA mileage calculators, #9 Bank Feed Discrepancy Fixer (heuristic parser + fuzzy
matcher), #10 Smart Document Renewal & Expiry Wizard (added 2026-07-19 — heuristic contract/
lease/policy text extraction: doc type, effective/expiration dates, parties, $ obligations,
suggested filing folder), #11 QuickBooks/Xero Parallel Cost-Savings Auditor (added 2026-07-19 —
pure client-side TCO math, 75% labor-reduction figure disclosed as a directional estimate, not
audited). Plus 2 bonus tools outside the numbered 12: Quick Log, CA GIFI Code Lookup (dictionary
sourced directly from VA-Dashboard's `DocumentAiExtractor` prompt for consistency with the core
app's own AI categorization).

**Every remaining item in the 12-tool matrix needs Shahab, not more web work:** #1-3 (native
mobile: receipt scanner, GPS mileage/trip logger, voice memo capture — can't be built in this
Next.js repo) and #8 + #12 (Telegram Mini App bridges — need bot registration, a webhook/backend,
Telegram auth; #12 also bundles a not-yet-built Payroll Deductions Simulator). The email to
Shahab about #1-3 (shahab.a@homeleaderrealty.com, found via a shared TestFlight invite thread —
he's the `shahabarvin/VA-Dashboard` GitHub owner per `.claude/CLAUDE.md`) was confirmed **actually
sent** 2026-07-17 (verified via Gmail search — an earlier note calling it an unsent draft was
stale, corrected 2026-07-19). #8/#12 were flagged to him via DuoSync inbox
(`VA-Dashboard-coord/inbox_shahab.md`) 2026-07-17, re-confirmed 2026-07-19 with an explicit
scope split (his: 1-3, 8, 12 / web-side: everything else); no reply from him in
`inbox_kamyar.md` as of 2026-07-19.

**Known gaps on what's built:** mileage rate is a placeholder (0.70 $/unit), not a verified
current-year CRA/IRS figure — flagged with an on-page banner. `SITE_URL` auto-resolves from
Vercel's `VERCEL_PROJECT_PRODUCTION_URL` env var (no manual config needed).

**Why:** positions VoiceAccountant as acquiring users at ~$0 CAC via SEO/free-tool funnels instead
of paid ads, per the original Gemini-sourced strategy conversation.

**Also built (2026-07-19), beyond the numbered 12:** Payroll (FICA) Tax Simulator
(`/us/payroll-simulator`) — the "+ Payroll Engine" content piece Tool #12's TMA would bundle,
built standalone ahead of Shahab's TMA wrapper (same pattern as #4-7 existing before #8's
bundle). Deliberately scoped to FICA only (Social Security 6.2% + Medicare 1.45% + 0.9%
Additional Medicare above threshold), explicitly excluding federal/state income tax withholding
for the same reason `selfEmploymentTax.ts` excludes it — W-4/state-dependent, changes yearly.
Verified against 2 hand-calculated cases including the SS wage-base cap and Additional Medicare
surtax. SS wage base ($175k) is a placeholder needing annual verification, same as the mileage
rate.

**How to apply:** read `TENTPOLE-GROWTH-STRATEGY.md`'s "Reality Check" section before building
any more tentpole tools — it documents which deep-link routes are real vs. aspirational. The web
side of the matrix is now feature-complete per the current plan — every remaining numbered item
needs Shahab. Check this memory before re-scanning the codebase for tentpole status; it's current
as of 2026-07-19.
