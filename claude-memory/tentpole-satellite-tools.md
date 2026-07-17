---
name: tentpole-satellite-tools
description: "Tentpole/satellite growth strategy execution status — 7 of 12 tools live at public-tentpole-matrix.vercel.app, 3 remaining need Shahab (native mobile)"
metadata: 
  node_type: memory
  type: project
  originSessionId: 316a8d1f-1edb-4b47-a849-f2aab83110cc
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

**7 of 12 tentpole tools built** (all Playwright-verified against `next start`, not `next dev` —
`next dev`'s HMR websocket caused false-negative test flakiness mid-interaction): Quick Log
(bonus), CA mileage calculator, US mileage calculator, US Schedule C Finder, US SE Tax Estimator,
CA GIFI Code Lookup (dictionary sourced directly from VA-Dashboard's `DocumentAiExtractor` prompt
for consistency with the core app's own AI categorization), US 1099-NEC Contractor Wizard, and
Bank Feed Discrepancy Fixer (heuristic parser + fuzzy matcher, the most algorithmically complex
tool — verified against a hand-calculated deterministic test case).

**Known gaps on what's built:** mileage rate is a placeholder (0.70 $/unit), not a verified
current-year CRA/IRS figure — flagged with an on-page banner. `SITE_URL` auto-resolves from
Vercel's `VERCEL_PROJECT_PRODUCTION_URL` env var (no manual config needed).

**3 remaining tools need native mobile (React Native), not web** — receipt scanner (camera OCR),
GPS mileage/trip logger, voice memo capture. Can't be built in the Next.js repo. Emailed Shahab
(shahab.a@homeleaderrealty.com, found via a shared TestFlight invite thread — he's the
`shahabarvin/VA-Dashboard` GitHub owner per `.claude/CLAUDE.md`) a **draft** (not sent) pointing
him at the growth-strategy doc for the spec.

**Why:** positions VoiceAccountant as acquiring users at ~$0 CAC via SEO/free-tool funnels instead
of paid ads, per the original Gemini-sourced strategy conversation.

**How to apply:** read `TENTPOLE-GROWTH-STRATEGY.md`'s "Reality Check" section before building
any more tentpole tools — it documents which deep-link routes are real vs. aspirational. Check
this memory before re-scanning the codebase for tentpole status; it's current as of 2026-07-17.
