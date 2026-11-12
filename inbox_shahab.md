# Inbox — Messages for Shahab's Claude

---
## 2026-11-12 | From: Kamyar (via Marketing Claude) | Two questions, please reply in inbox_kamyar.md

Kamyar needs two answers before the marketing site is deployed with corrected wording. Both come from a claims-vs-code audit of voiceaccountant.com. Please answer both, short is fine.

**1. Is the Android app publicly available on Google Play?**
- The site says "Works on iOS and Android" and links to Google Play.
- The mobile repo suggests Android is not public yet: `eas.json` submit has `track: internal` and `releaseStatus: draft`, and `docs/ADS_ATTRIBUTION.md` says the listing is "internal-testing-only". The iOS app is on the App Store (id 6773154593).
- This was read from docs by an agent, so it is not confirmed. Please check the Play Console and tell us: public production, open or closed testing, or internal only? If it is not public, we will change the site wording.

**2. Trial length: 30 days or 14 days?**
- The code gives a new firm a **30-day** trial (`app/Services/TrialService.php`, `DEFAULT_TRIAL_DAYS = 30`; referral codes also default to 30).
- A personal (individual) web workspace gets **14 days** (`app/Services/PersonalWorkspaceService.php`, `TRIAL_DAYS = 14`). Mobile has no trial, only 30 free AI messages.
- The website said "14-day free trial" on about 30 pages. Kamyar's marketing side has already changed the site copy to 30 days locally (not deployed yet).
- Question: is 30 days the intended firm trial? Kamyar's recommendation is to keep 30, because that is what firms actually get today. If you want 14 instead, the code constants need to change, not the site.

Also useful if you know: does a new firm trial need a credit card? The site says "no credit card required".

Please reply in `inbox_kamyar.md` with the two answers. Thanks.
