---
name: languages-eight-language-plan
description: "Eight-language dashboard (en es fr de it ar fa hi); dashboard is the reference, mobile repo is NOT ours to touch; phases 1 to 4 built 2026-11-26 (checkpoints 589 to 598), 589..594 live, 595..598 pushed and awaiting Amin's deploy and test."
metadata:
  node_type: memory
  type: project
  originSessionId: 668006a0-c5ee-4a41-89d5-5d9fb2a1f41e
  modified: 2026-11-27T01:43:23.060Z
---

Amin decided on 2026-11-26 (after Kamyar's Qatar deck claimed "8 languages live today"
while only the mobile UI had them) that the dashboard gets the same eight languages as
the mobile app, and that the AI assistants must understand and answer in them, typed and
spoken. Authoritative doc: `va-dashboard2/docs/languages.md` (start at "Where it stands").
Test guide handed to Amin: `va-dashboard2/docs/languages-test-guide.pdf` (Persian, 9 pages).

**State at the end of 2026-11-26:**
- cp-589..594: assistants in eight languages + fixes from Amin's live tests. LIVE.
- cp-595 foundation (users.language MIGRATION, SetLanguage middleware, POST /language,
  resources/js/i18n, LanguageSwitcher, RTL codemod of 115 files), cp-596 (draft category,
  language-check `draft` kind), cp-597 (all 266 screen files wrapped in t(), ~6,300
  sentences x 7 languages in lang/*/ui.json), cp-598 (bidi fences, report card, test guide).
  PUSHED, NOT deployed, NOT tested by Amin. Deploy needs npm build + migrate.
- Not done: cheque pages (another agent was editing them), phase 5 emails/PDFs, server
  validation errors, native-speaker review of any translation, hearing measured with
  real recordings, re-run of `ai:language-check` after the schema made fields required.

**Decisions Amin confirmed (2026-11-26):**
- The dashboard is the heart of the project and the REFERENCE for language. The mobile
  team adapts to our data. ⚠️ Do NOT touch the mobile repo for this work. Their hand-off
  doc is `docs/languages-mobile-contract.md`.
- Cover exactly the languages a person can pick in the mobile app UI (the eight).
- Whatever the server says, the server translates; mobile only translates its own screens.
- Amounts always in Western (Latin) digits, dates always Gregorian, in every language.
- Client side first, then accountant; a client's non-English note should later show an
  English translation beside the original for the accountant (agreed, NOT built).

**How it is built (do not re-derive):**
- THE ENGLISH SENTENCE IS THE KEY: `t('Save changes')` from `@/i18n`, ICU MessageFormat,
  `lang/{language}/ui.json`. English needs no file. Server sentences beside the assistant
  use key-based `lang/{language}/assistant.json` via `App\Support\Lang\Messages`.
  (I told Amin "i18next + ICU" at first; built on `intl-messageformat` directly instead,
  same file format.) Rules for adding a screen: `docs/i18n-conventions.md`; terms:
  `docs/i18n-glossary.md`.
- Tools: `node scripts/i18n.mjs extract|check|missing|merge`, `scripts/i18n-patterns.mjs`,
  `scripts/i18n-selftest.mjs`, `scripts/rtl.mjs fix|check`. Three things break screens and
  `check` refuses them: t() at module level (use N_()), a local variable named `t`, and
  translating a value the code compares or sends.
- Language code = two letters. `locale` in this codebase already means COUNTRY in three
  letters, so the column is `language`.
- Production has `intl`: PHP 8.2.33, ICU 77.1 (CLI, checked 2026-11-26).
- Measurement: `php artisan ai:language-check --runs=3` on the server (needs the DB).
  First run 2026-11-26: spoken transactions 102/102 in all eight languages.

**Working method that worked for the mass conversion:** 37 batches of files to sonnet
subagents with one brief + conventions doc, then 26 translation chunks of 250 sentences to
sonnet subagents each writing seven JSON files checked by `scripts/i18n-chunk-check.mjs`.
⚠️ Subagents sharing the scratchpad overwrote each other's helper scripts: tell them to use
Edit only. ⚠️ Max 20 concurrent subagents.

**Local browser check without Postgres:** migrate + seed a SQLite file with env overrides
(`DB_CONNECTION=sqlite DB_DATABASE=<file> CACHE_STORE=file SESSION_DRIVER=file`),
`php artisan serve --host=127.0.0.1` (⚠️ not `localhost`: the sandbox refuses IPv6
loopback), then Python Playwright with `channel='chrome'`. Seeded logins:
sarah@greenfieldtax.ca and client@xyzltd.ca, password `password`. ⚠️ A local
`public/build/manifest.json` makes `CommunityPublicForumRedirectTest` fail (Inertia version
409); it passes without it. ⚠️ `php artisan test` for the whole suite runs out of memory
here; run phpunit with `-d memory_limit=3G` in folder groups under 10 minutes each.

Related: [[international-direction]], [[ai-prompt-registry]], [[extraction-measurement-harness]],
[[checkpoint-rule]], [[tests-step-by-step]].
