---
name: marketing-site-suite
description: Two-project suite (marketing voiceaccountant.com + Laravel dashboard); marketing-platform decision (WordPress vs Statamic vs Astro) PENDING; never merge/embed marketing into Laravel
metadata: 
  node_type: memory
  type: project
  originSessionId: 084a50d5-8c7b-4f0e-bfaf-6ded6fb36d14
---

`E:/Projects/voiceaccountant` = the PUBLIC marketing site for **voiceaccountant.com** (currently 8 static HTML pages, Tailwind via CDN). `E:/Projects/va-dashboard2` = the Laravel app on **my.voiceaccountant.com**. SEPARATE repos / domains / deploys — must stay that way.

**SEO + LLM-discoverability is the goal for the MARKETING site only.** The dashboard is behind auth and must stay `noindex` (it's client-rendered Inertia/React, no SSR — fine, since it should never be indexed).

Decisions locked (2026-06-26):
- **Do NOT merge** marketing into the dashboard repo, and **do NOT embed WordPress inside Laravel** — no SEO benefit + routing/security/deploy-coupling cost; iframe embed is an SEO disaster. They're on different hostnames already, so there is nothing to embed.
- Target architecture: `voiceaccountant.com` → standalone marketing platform (blog at `/blog` as a **subdirectory**, not a subdomain); `my.voiceaccountant.com` → Laravel app untouched; login/register hand off (already wired in the static HTML).

Marketing-platform choice **PENDING** (user wants options first, builds only on explicit go-ahead). My recommendation order:
1. **Statamic** (Laravel-native CMS) — same stack/skills/hosting as the final Laravel product = "smooth transition"; top pick.
2. **WordPress** (standalone, managed host like Cloudways) — if a non-technical team writes content.
3. **Astro** — best raw Core Web Vitals, but Node stack diverges from Laravel.
4. Static-cleanup = valid 1-week stopgap (compile Tailwind, add sitemap/robots/llms.txt/JSON-LD).

Current static-site SEO gaps STILL open: no `sitemap.xml` / `robots.txt` / `llms.txt`, no JSON-LD, Tailwind via CDN (hurts Core Web Vitals — kept because the static stack mandates CDN).

**2026-06-29 — DESIGN-SYSTEM v2 REDESIGN DONE + PUSHED.** All 8 pages rebuilt from the mobile-app tokens (20px heading cap) to a marketing-grade system: IBM Plex Sans + **Plex Mono for $ figures/GIFI**, fluid type scale, shadcn-style components reproduced in plain HTML (no React/build), refined motion + a11y. `index.html` = golden reference; full token spec is documented in `voiceaccountant/CLAUDE.md` (new "MARKETING DESIGN SYSTEM v2" block — supersedes the old strict 20px/no-style/no-JS rules). Built with the `frontend-design` + `ui-ux-pro-max` skills (the latter needs `py -3`; Playwright was pip-installed for visual QA). The dead `login.html`/`signin.html` forms now **route to `my.voiceaccountant.com`** (no credential fields on the marketing domain); removed an unverifiable "5,000+ firms" claim. Rollback point if ever needed: `git reset --hard marketing-pre-redesign` (annotated tag at the pre-redesign baseline).

⚠️ **The marketing repo's `origin` is now `github.com/Amin88-hub/va-website`** (renamed from `voiceaccountant`) and — like the dashboard — has an **auto-commit + auto-push daemon** (commits authored "Shahab Avin", ~every minute). So manual pushes RACE the daemon (fetch+rebase before push), the working tree gets pushed to GitHub without review, and **secrets must never be written here** ([[autocommit-leaks-secrets]] applies to this repo too). Repo also has a `Privacy.html` vs `privacy.html` case-collision (two index entries, one physical file on Windows) — worth a `git rm` cleanup later.

Tooling already done: multi-root VS Code workspace + parent CLAUDE.md + DuoSync now on BOTH repos (see [[duosync-setup]]). Honor [[wait-for-user-test-before-deploy]] and [[autocommit-leaks-secrets]].