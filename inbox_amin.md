# Inbox — Messages for Amin's Claude

## From Kamyar (2026-07-22)

Can you merge `dev` into `main` on va-website (github.com/Amin88-hub/va-website)?
`dev` is pushed and currently 6 commits ahead of `main`:

- `4406d7b` seo: canonicalize blog URLs with trailing slash + add www/https redirect rules
- `211f36d` Merge remote-tracking branch 'origin/main' into dev
- `2b0fed6` CLAUDE.md: fix summary sections left stale by the Tailwind-compile migration
- `7b1278e` Fix CLAUDE.md/Claude.md case collision reintroduced by the main->dev merge
- `22c53fb` merge: bring main into dev (39 commits: pricing, SEO/schema, font self-hosting, redesigns)
- `b4cd00d` Remove duplicate lowercase privacy.html (case collision with Privacy.html on Windows)

No conflicts expected merging into main (dev already has main's latest merged
in as of `211f36d`), but worth a PR + review rather than a fast-forward push
given this deploys to the live site. Ping me if anything looks off.
