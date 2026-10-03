---
name: tentpole-funnel-brief-pending
description: "PENDING (2026-10-02): Kamyar's brief 'wire the 11 free tools at public-tentpole-matrix.vercel.app back to VoiceAccountant signup'. Amin said HOLD; he forwarded four options to Kamyar and will relay the answer. Do NOT start until Amin says which option. Findings already made (no CSV exports exist, no voiceaccountant://import route, shared ToolShell) are recorded here."
metadata:
  node_type: memory
  type: project
  originSessionId: c334b938-b380-462a-9f99-a6dc60fb3de9
  modified: 2026-10-02T23:07:32.928Z
---

**Status 2026-10-02 (evening):** on hold. Amin forwarded the four options below to Kamyar and will tell Claude the answer. Nothing has been changed in any repo for this brief.

**The brief (Kamyar):** on each of the 11 tools add (1) a "Powered by VoiceAccountant" footer with logo link to www.voiceaccountant.com, the subtext "Ready to automate your whole practice? Stop chasing documents, post to QuickBooks, reconcile your bank, all in one place." and a "Start free trial" button to my.voiceaccountant.com/register; (2) a "Send to VoiceAccountant app" deep link on exports (`voiceaccountant://import?data=...`) with a web fallback to for-clients.html; (3) a footer comment in every CSV/XLSX export with App Store / Play / web-app links; (4) a post-calculation banner "This took 5 minutes. VoiceAccountant does this automatically every day. Try free for 14 days." Tone: "Whether you're a freelancer, contractor, store owner, retailer, corporation, or any business type...", no fake claims, Lighthouse 90+.

**Findings (verified 2026-10-02):**
- Repo `kmoini/public-tentpole-matrix` (private, last push 2026-07-20) is readable with Amin's gh login; it is NOT on this machine (Kamyar keeps it at d:\projects). A throwaway clone was made in the session scratchpad only. Deploy is manual `vercel --prod` from Kamyar's Vercel (snap-dance team); Claude cannot deploy it ([[tentpole-satellite-tools]]).
- Routes match the brief's 11 paths under `src/app/{ca,us,tools}/...`. All share `src/components/ToolShell.tsx` (31 lines; only a "back to home" link, no footer branding, no signup CTA), so items 1 and 4 are ONE shared-component change.
- `src/components/DeepLinkButton.tsx` + `src/lib/deepLink.ts` + `useDeepLinkFallback.ts` exist and build the REAL link `voiceaccountant://record?text=...&type=...&autosend=...`, but **zero pages use DeepLinkButton**.
- The mobile app (va-mobile) has NO `voiceaccountant://import` route; only `record`, `join`, `auth` (checked `app/record.tsx`, `app.json` scheme). Item 2's format as written cannot work; use the record link or the web fallback.
- There are NO CSV/XLSX exports anywhere in the tools (grep for text/csv, Blob, xlsx: nothing). Item 3 has nothing to attach to unless exports are built first.
- The site currently has no funnel at all; the only VA links in code are the two store URLs in a constants file.

**The four options sent to Kamyar (keep the same wording when he answers):**
1. **Implement on a branch in Kamyar's repo (Claude's recommendation):** footer "Powered by VoiceAccountant" + Start free trial + post-calculation banner in ToolShell, plus an "Open in the app" button using the real record deep link with web fallback; drop CSV-footer and import-link items as they have nothing to attach to; push a branch, Kamyar deploys with `vercel --prod`.
2. **Marketing site only:** add a "Free tools" link in the marketing header/footer pointing at the tools site, and hand the brief back to Kamyar with the findings.
3. **Both** (1 + 2).
4. **Neither, report only:** send Kamyar the findings, touch no code.

**How to apply:** when Amin relays Kamyar's choice, do exactly that option. For option 1/3, remember the deep-link and no-export facts above; commit on a branch (not main) in `kmoini/public-tentpole-matrix`, never deploy. For option 2/3, the marketing-site link follows [[marketing-scope-and-blog-placement]] (Amin decides header vs footer placement; a brief that says header/footer is honored as written for a PAGE link).
