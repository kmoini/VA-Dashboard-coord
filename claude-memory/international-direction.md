---
name: international-direction
description: Product is going international — i18n must support all languages incl. RTL; affects all future UI/string work.
metadata: 
  node_type: memory
  type: project
  originSessionId: 5fe207d9-93e9-4fb5-895e-1d9f44c90457
---

Amin stated (2026-06-08) the dashboard will operate internationally and "needs all languages eventually." i18n is therefore an architectural stance, not a feature.

**Why:** At all-language scale, naive approaches break — Arabic has 6 plural forms, RTL must be designed in (not retrofitted), and number/currency formatting becomes a correctness issue in an accounting product.

**How to apply:** When advising or building any UI/string work, assume: RTL-safe layout (Tailwind logical properties `ms-/me-`, needs Tailwind 3.3+ bump from current 3.2; numbers/tables stay LTR even in RTL pages), ICU MessageFormat (FormatJS or i18next+ICU, not a naive `t()` helper), JSON lang files that round-trip with a TMS (Tolgee/Weblate/Crowdin), and all numeric/date/currency display via `Intl`. Caveat: true internationalization also touches domain logic (GIFI codes, tax terms are Canada-specific) — that's separate from translation.

As of 2026-06-08 this is ADVISORY only — no build started. White-labeling (Tier 1 in-app theming, gated on converting hardcoded [[checkpoint-rule]]-era Tailwind colors to CSS variables) and a `driver.js` walkthrough on the existing OnboardingService were also discussed but parked.
