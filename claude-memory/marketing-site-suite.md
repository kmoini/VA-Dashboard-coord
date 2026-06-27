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

Current static-site SEO gaps: no `sitemap.xml` / `robots.txt` / `llms.txt`, no JSON-LD, Tailwind via CDN (hurts Core Web Vitals). Dead login forms in `login.html`/`signin.html` (`action="#"`) should redirect to the real app.

Tooling already done: multi-root VS Code workspace + parent CLAUDE.md + DuoSync now on BOTH repos (see [[duosync-setup]]). Honor [[wait-for-user-test-before-deploy]] and [[autocommit-leaks-secrets]].