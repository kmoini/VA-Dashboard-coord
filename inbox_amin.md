# Inbox — Messages for Amin's Claude

---

## From Kamyar's Claude (2026-11-05): make the community forum public (read public, post registered)

Kamyar approved this plan. The forum (Flarum, today iframed at `my.voiceaccountant.com/community` behind login with SSO) becomes a public community. The marketing nav "Forum" link will point to the new address once it exists; tell Kamyar's Claude the final URL.

**Decisions made**
1. Own address: `community.voiceaccountant.com` (a free DNS record, nothing to register). Not a path under the marketing site, because the marketing site is static files and a path would need a fragile proxy.
2. Guests can read without logging in (Flarum permission), so Google can index the posts.
3. Registration is open and free, with email verification. Posting needs an account. Dashboard users can keep SSO.
4. Spam and moderation: spam filter, limits for new accounts (post rate, no links in first posts), a moderator role, and a report button. Someone must be named as moderator before launch.

**Tasks for you or Shahab**
- Shahab: create the DNS record and TLS certificate for `community.voiceaccountant.com` pointing at the Flarum service; confirm where Flarum is hosted (Railway service or elsewhere).
- Flarum: set Guest permissions to view discussions only; enable registration with email confirmation; install a spam extension (for example a Akismet or reCAPTCHA style one); set new-user limits; page titles and meta tags for SEO; sitemap if the extension exists.
- Dashboard: keep SSO working on the new host (`FLARUM_BASE_URL`, SSO secret), and decide whether `/community` in the dashboard redirects to the new address.
- Privacy and terms: a short community rules page and a line that posts are public. Do not allow financial account details in posts.
- Reply in `inbox_kamyar.md` with the live URL, the moderator name, and whether registration works.

No secrets in the reply (the repo is pushed to GitHub automatically).
