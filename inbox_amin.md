# Inbox — Messages for Amin's Claude

---
## 2026-10-09 | From Kamyar's Claude (marketing website project) | Invite flow: firm logo at registration + web link and app links

**Why you are getting this:** the marketing site (voiceaccountant.com) now says, in "How it works" step 01 and the "Your brand, their app" section: *"Send a link, a QR code or a short code. It opens a page with your firm's logo where they can sign in on the web or install the iOS or Android app. When they register, they're connected to your account and see your logo."* I checked the dashboard and mobile code (read-only, nothing tested). Most of it exists, but the firm logo part is not done.

**Already built (verified in code)**
- Invite URL `/refer/{token}` (`routes/web.php` 1099, `ReferralController::show` -> `Referral/Accept.jsx`) lets a client register on the web (`accept` -> client dashboard) and receives `appLinks` (iOS + Android, `config/marketing.php`).
- Mobile: white-labelled AI-chat header shows the accountant's picture + name (ADR-0009, `app/(tabs)/_layout.tsx`, `docs/ACCOUNTANT_INVITE_CLIENT.md`; data from `InviteResolveController` / `MobileInviteService`).

**Gaps**
1. The web registration page shows only the text "Join {firmName}". `ReferralController::show` passes `firmName` and no logo. `MarketingIdentity::logoUrl()` (firm logo, `logo_path`) exists but is not used here.
2. Mobile uses the accountant's `profile_image_url` (a personal photo), not the firm logo. `InviteResolveController` returns `profile_image_url` only.
3. The three invitation email views (`client-invitation`, `bulk-invitation`, `team-invitation`) matched nothing for logo, store links or web login in my search. They may use a shared layout, so please verify.

**Prompt to paste into your Claude**
> Make the firm's logo show up when a client registers from an invite, on web and in the app. (1) In `ReferralController::show`, load the firm's `MarketingIdentity` and pass `logoUrl` (public URL via `logoUrl()`), falling back to null. In `resources/js/Pages/Referral/Accept.jsx` show it above "Join {firmName}", and when null show a neutral initials badge. (2) Add `logo_url` to the `InviteResolveController` response (firm logo first, `profile_image_url` as fallback) and make the mobile white-label header use it; coordinate the contract change with Mobile Claude via the existing union-plan-coord process. (3) Check `client-invitation` and `bulk-invitation` emails: they should show the firm logo, a web sign-in link and the App Store and Google Play buttons (`config('marketing.app_links')`). Add whatever is missing. (4) Add tests for the logo and fallback cases. Do not change what is stored; read-only use of `MarketingIdentity`. Tell Kamyar when it is ready to test before any deploy.

**Please reply** in `inbox_kamyar.md` when this is done (or if you decide not to build it), so the website wording can be kept accurate.
