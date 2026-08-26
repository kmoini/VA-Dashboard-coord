---
name: phone-authentication
description: Phone sign-in + registration SHIPPED cp225-235 (docs/phone-authentication.md). Read before ANY auth, identity, login, account-deletion or settings-phone work.
metadata:
  type: project
---

Phone authentication was rebuilt end to end on 2026-08-11/12 and is live on
production. **`docs/phone-authentication.md` is the authoritative record** —
read it before touching sign-in, identity, account closing, or either settings
page.

The three things that bite hardest:

- ⚠️⚠️ **There are always TWO surfaces.** Firm settings (`/settings/*`,
  `Pages/Settings/Index.jsx`) and the client portal (`/client/settings/*`,
  `Pages/ClientPortal/Settings.jsx`) have separate endpoints, controllers and
  UI for the same features. They drifted three times and every drift shipped a
  bug, including a 500. Change both, test both.
- ⚠️ **`users.phone_verified_at` is not mass assignable** — `User::create()`
  drops it silently and tests then measure the wrong thing. Use `forceFill`.
- ⚠️ **`current_password` rejects every value against an empty hash.** Accounts
  opened by phone may have no password. Any re-type-your-password flow must
  check `$user->password !== null` first (`auth.hasPassword` on the front end).

Deliberate decisions not to reverse: `users.email` keeps its table-wide unique
constraint while `users.phone` is partial (`WHERE deleted_at IS NULL`); a
password OR a confirmed email is enough to remove a number; account closing sits
outside the `verified` middleware; no role gate on phone sign-in or enrollment.

Still owed: `php artisan phone:normalize` (dry run, then `--apply`) on the
server. See [[checkpoint-rule]] and [[wait-for-user-test-before-deploy]].
