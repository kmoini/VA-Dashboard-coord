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

---
## 2026-10-09 | From Kamyar's Claude (marketing website project) | NEW FEATURE REQUEST: browser extension "send a screenshot to VoiceAccountant"

**Why you are getting this:** Kamyar wants a browser extension. A user clicks it on any web page (online invoice, vendor portal, webmail, web order, SaaS invoice), it captures the page and sends it to the VoiceAccountant dashboard, where it goes through the normal draft, flag, approve path and is posted to QuickBooks Online with the capture attached. Both clients and accountants use it. The marketing site now says it is **coming soon** (Chrome and Edge) in "How it works" step 02, the Platform page, For clients, llms.txt and the new QuickBooks integrations blog article. Nothing is built yet, this is a request to scope and build.

**Recommended scope (v1)**
- Manifest V3 extension, **Chrome and Edge first** (Brave and Opera work from the same build). Firefox and Safari later.
- Capture the **visible tab** (`chrome.tabs.captureVisibleTab`) **plus page URL, title and page text**. Page text is far more accurate for web receipts and invoices than OCR on the image, so the draft should be built from the text first and the screenshot attached as proof. v2: region select and full-page capture.
- **Privacy:** use only the `activeTab` permission, capture only on an explicit click, no broad host permissions and no browsing history. Add a line to the privacy policy. This also helps the Chrome Web Store review.
- **Sign-in and routing (the real design work):** the extension must know who is signed in and which client the capture belongs to. Clients capture to their own books. Accountants pick the client (default to the last one used). Needs an auth approach (device or token flow against the dashboard, not the user's password in the extension) and a store for the token.
- **Backend:** treat it as one more inbound source, like email forwarding and Batch Upload. It lands in the Document Hub and review queue under the right client, runs the existing Gemini drafting and confidence scoring, and uses the existing approve then QuickBooks post path with the document attached. Suggest a distinct `source` value so it can be filtered and badged (see the transaction source origin rules memo).
- **Limits:** reuse the 25 MB file limit. Rate-limit per user. Do not store the page text longer than the attachment.

**Questions for you**
1. Which auth pattern do you prefer for the extension (device-code flow, or a per-user capture token generated in Settings)?
2. Can the existing email-intake or batch-upload endpoint be reused, or should this be its own endpoint?
3. Rough size and a target date, so the website wording can stay accurate.

**Prompt to paste into your Claude**
> Scope and build a Chrome and Edge browser extension (Manifest V3) for VoiceAccountant. On click it captures the visible tab as an image plus the page URL, title and text, and sends it to the dashboard for the signed-in user. Clients capture to their own books; accountants choose which client it goes to. On the backend add it as a new inbound source (distinct `source` value) that creates a Document Hub item and a draft transaction under the right client through the existing Gemini extraction (prefer the page text, keep the screenshot as the attachment), with the normal confidence score, review queue, approve, and QuickBooks Online posting with the attachment. Use only the `activeTab` permission, capture only on explicit click, and request no broad host permissions. Design the extension sign-in carefully (no password in the extension), propose the auth flow before building, and list the privacy-policy wording needed. Add tests for the endpoint and the routing. Do not deploy. Tell Kamyar when it is ready to test.

**Please reply** in `inbox_kamyar.md` with the auth decision, a rough size and a date (or if you decide not to build it), so the "coming soon" wording on the website can be kept accurate.
