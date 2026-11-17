---
name: community-public-forum
description: "Public Flarum forum LIVE at community.voiceaccountant.com since 2026-11-13 (Railway, own project); security rules until image 1.8.21; how SSO, logout and the API key work"
metadata:
  node_type: memory
  type: project
  originSessionId: 08810cd8-2dab-46c6-98b8-1b1b915ab7e2
  modified: 2026-11-13T21:10:15.847Z
---

Kamyar decided 2026-11-13: public forum (guests read, members post, anti-spam, indexed, Guidelines, /community redirects). LIVE and COMPLETE the same day. ⭐ READ FIRST: va-dashboard2 `docs/community-public-forum.md` = the one complete record (where things live, sign-in flow + code map, forum config, security rules, runbook, pitfalls, open items). Forum admin username is `Amin` (renamed from `flarum`).

Hosting: Railway project `voiceaccountant-community` (separate from Bigcapital, [[bigcapital-deployment]]), US East. Services `flarum` (crazymax/flarum:1.8.20, volume /data) + `mariadb` (mariadb:10.11). Railway's MySQL 8.4 template does NOT work with this image. DNS by Shahab: CNAME community -> 7p9sdlpu.up.railway.app, DNS only.

Dashboard side (LIVE at checkpoint-485, 4957c8b0): /community is public and redirects; verified signed-in users get `flarum_remember` on `.voiceaccountant.com`; dashboard logout revokes the user's Flarum session tokens (dropping the cookie alone does not sign the forum out); sign-in ADDS the Verified Accountant group (id 5), never replaces groups.

Non-obvious facts:
- `FLARUM_API_KEY` is a Developer Token of the forum admin (Flarum 1.8 has no API-key screen; a user token works in the same header).
- Never change `FLARUM_SSO_SECRET`: forum passwords of SSO users derive from it. An EMPTY secret silently sends users to the forum as guests.
- Forum mail = Resend SMTP on port 2587/tls (587 fails from Railway).
- Third-party extensions are installed from Railway > flarum service > Console tab (a shell in the container): `extension require <pkg>:<constraint>` records it in /data/extensions/list so it survives redeploys; `extension list` shows them. Installed 2026-11-13: fof/recaptcha 1.3.6 (Sign Up + Forgot Password, NOT Log In), fof/anti-spam 1.1.6 (replaces abandoned stopforumspam/spamblock), fof/sitemap 2.6.1 (runtime, profiles excluded). Dashboard SSO account creation still works with them on.
- ⚠️ Core is still 1.8.20 (no 1.8.21 image on 2026-11-13): never grant "Edit user groups" to non-admins (GHSA-fqc7-2f6r-m84c). flarum/mentions:^1.8.7 is installed AND recorded in the extension list (XSS closed, Mentions enabled). Nicknames off.
- Theme (brand bar, footer, LESS) lives in va-dashboard2 docker/community/theme and is pasted into Flarum Appearance by hand; Guidelines = /d/1-community-guidelines (sticky, locked). Dashboard sidebar opens the forum in a new tab (cp-486).
- A browser that used dashboard SSO is switched to that forum account; admin work with the separate `flarum` account needs a private window.
- Amin drives Railway through Claude Cowork with prompts written here; Cowork did the whole Railway setup.
- ⚠️ A git worktree needs its OWN `composer install`: a junction to the main vendor makes the autoloader load the MAIN checkout's app/. Fresh worktrees also lack storage/framework/* dirs and M2M keys (unrelated M2M test failures). Worktree: E:/Projects/va-dashboard2-community, branch work/community-public-forum-20261113, local PG database va_gate_test_community.

Open on 2026-11-13 (everything merged and pushed, va-dashboard2 main = dfb19103): image 1.8.21 pending (Railway "Patch Update Available"); the rest is with Kamyar (message pushed to coord inbox_kamyar.md, commit 63c319d).
