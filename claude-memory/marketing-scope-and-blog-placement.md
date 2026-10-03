---
name: marketing-scope-and-blog-placement
description: "⚠️⚠️ FEEDBACK (Amin, 2026-10-02): in the marketing repo Claude is responsible for MARKETING ONLY. Never bring up, warn about, or condition marketing work on dashboard (va-dashboard2) status. Comparison / SEO content pages from Kamyar's briefs go under /blog/<slug>/index.html, NOT at the site root and NOT linked from the homepage, even if the brief says 'root level'."
metadata:
  node_type: memory
  type: feedback
  originSessionId: c334b938-b380-462a-9f99-a6dc60fb3de9
  modified: 2026-10-02T22:29:03.725Z
---

Amin's corrections on 2026-10-02 after the Dext comparison page:

1. **Marketing only.** When working in `voiceaccountant/` (va-website), do not mention the dashboard's deploy state, pending checkpoints or feature gaps. Amin: "you are responsible for marketing". The dashboard is someone else's concern in that context.
2. **Content pages live in the blog.** The brief from Kamyar said "root level, linked from homepage and blog", but Amin wanted it in the blog section (`blog/dext-alternatives-2026/index.html`, canonical `/blog/dext-alternatives-2026`), with the homepage untouched. Treat Kamyar's briefs as content specs; placement follows the site's structure (blog posts are `blog/<slug>/index.html`, listed as a card on blog/index.html, in sitemap.xml without `.html`, and in the llms.txt Blog list).

3. **Blog posts use the blog ARTICLE template, not landing-page sections.** Amin (same day): the first version, even after moving under /blog, was built like the homepage (hero grid, feature cards, dark sections, calculator) and he rejected it: "opening it feels like opening the homepage". Blog pages must copy an existing post (e.g. blog/best-dext-alternatives-2026/index.html) exactly: the same `<style>` prose block, `<main class="px-6 py-12 md:py-16"><article class="prose max-w-3xl mx-auto">`, backlink, h1, "Last updated" line, lede, TL;DR blockquote, plain `<table>`, h2/h3 prose, text FAQ, sources line, same footer and menu-only JS.

**Why:** the homepage is curated; comparison/SEO articles are blog content. Dashboard talk in a marketing session is noise to Amin.

**How to apply:** new SEO/comparison pages → `blog/<slug>/index.html` with `../../` asset paths, Blog marked current in nav, BreadcrumbList Home > Blog > page. Deploy of www is MANUAL by Amin: push, then tell him "pushed" so he deploys. Related: [[dext-alternatives-landing-page]], [[answer-in-persian]].
