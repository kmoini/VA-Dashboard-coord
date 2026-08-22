---
name: no-dash-in-frontend
description: "HARD RULE from Amin (angry, 2026-08-21): NEVER use the em-dash character or a spaced hyphen as punctuation in ANY user-visible frontend text, in every project (dashboard, marketing site, emails). Use a comma, colon, or period instead."
metadata: 
  node_type: memory
  type: feedback
  originSessionId: f15acdf7-3df5-4965-883a-7b62cd86273c
  modified: 2026-08-21T17:20:36.815Z
---

Amin hates the dash-as-punctuation character in UI copy and threatened to
cancel his Claude account over it (2026-08-21).

**Why:** He finds it ugly and it reads as AI-generated filler. The marketing
repo's CLAUDE.md already banned the em-dash for site copy; this extends the
ban to ALL user-visible text everywhere: va-dashboard2 React pages, emails,
PDF flyers, SMS bodies, campaign templates, seeded content, and the marketing
site.

**How to apply:**
- Never write ` — ` (em-dash) or ` - ` (spaced hyphen as a separator/pause)
  in any string a user can see. Rewrite with a comma, colon, or period.
- Hyphenated compound words are fine (toll-free, co-branded, ready-made).
- Code comments and commit messages are not user-visible; still prefer
  avoiding it out of habit.
- Before shipping UI copy, grep the touched files for the em-dash character.

Related: [[marketing-site-suite]]
