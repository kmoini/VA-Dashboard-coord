---
name: io-lock-concurrent-edit
description: "IO Lock — advisory lease-based concurrent-edit guard so accountant + client can't clobber the same transaction / registry. cp-179 pushed 2026-07-25; prod owes optimize:clear for new /locks routes. READ before edit endpoints / ResourceLockService."
metadata: 
  node_type: memory
  type: project
  originSessionId: 214b33a4-0102-4f94-a64b-81dc65df1f16
  modified: 2026-07-25T04:55:31.348Z
---

Advisory "IO Lock" so two people (accountant AND/OR the client, who now share the
same client-owned data via [[client-registry-multi-company]] grants) can't save
over each other. Needed because the grant model made concurrent cross-party edits
real.

**Design (owner-approved):** PER-RESOURCE (never whole-client), LEASE with TTL +
heartbeat, PORTABLE via Laravel `Cache::add()` (local `database` store / prod
`redis` — NOT the Redis facade), ADVISORY (transaction `version` optimistic check
stays as backstop). One active accountant assumption unchanged.

**Backend:** `app/Services/ResourceLockService.php` — TTL_SECONDS=90; TYPES
`transaction` + `client_registry`; key `reslock:{type}:{id}`; meta {user_id, name,
role(accountant|client), acquired_at, expires_at}. Methods acquire/renew(=acquire)/
release(owner-only)/holder/lockedByOther. `app/Http/Controllers/ResourceLockController.php`
— POST /locks (acquire, 200 held|423 blocked), /locks/renew, /locks/release, GET
/locks/status; routes in the shared `auth`+`resolve.tenant` group so BOTH user types
reach them; guardAccess() re-authorizes (⚠️ base Controller already has a public
`authorizeResource` — do NOT name a method that; renamed to guardAccess). Write-side
guards return 423 `{message, locked_by}` in: `TransactionsController::update`,
`ClientsController::updateRegistry`, `ClientPortalController::updateRegistry`.

**Frontend:** `resources/js/hooks/useResourceLock.js` ({type,id,enabled} → {held,
holder, blocked, release}; heartbeat 30s, poll 5s auto-reacquire when freed,
sendBeacon release on pagehide). `resources/js/Components/LockBanner.jsx` (amber "X
is editing… unlocks automatically"). Wired: Transactions/Index.jsx drawer (enabled =
canEdit && touched — locks only on FIRST field edit, not on open), Transactions/Show.jsx
(enabled = isEditing), Clients/Show.jsx ProfilePanel + ClientPortal/Registry.jsx
(client_registry:<client.id>, same key both sides; touched via onFocusCapture/
onChangeCapture + markTouched in remove/toggle handlers). Each: banner + disabled
"Locked" Save + guard.

**cp-180 follow-ups (2026-07-25, pushed):** portal exercised the lock and exposed 2 bugs.
(1) ⚠️ `ResolveTenant` firewalls portal users to an ALLOW-LIST of route names; `/locks/*`
wasn't on it → every portal lock request redirected to dashboard → client showed permanent
"Locked". FIX: added `'locks.*'` to the allow-list. ANY new cross-cutting endpoint portal
users must hit needs the same. (2) hook was fail-CLOSED (`blocked = enabled && !held`) → any
failed/redirected lock req hard-blocked editing; now fail-OPEN (`blocked = enabled && id &&
holder`, only a real 423). Also: registry now uses DEBOUNCED auto-save on every change (add/
delete/inline edit) NOT gated on client-side lock (server 423 is authority); lock held for the
editing session, released on unmount (no per-save churn — that churn + single-thread `php
artisan serve` caused save flakiness). See [[registry-inline-edit-autosave]] +
docs/registry-inline-edit-autosave.md.

**Status:** cp-179 committed + tagged + PUSHED 2026-07-25 (Amin tested OK). Local:
10/10 service tests pass, php -l clean, npm build ok, 4 routes registered.
⚠️ import path is `@/Hooks/` (capital H) to match the repo's tracked `Hooks/` dir —
lowercase built fine on Windows but would break the case-sensitive prod build (git
core.ignorecase trap). No migration/env. Deploy = webhook git pull + npm build
(public/build is gitignored, server rebuilds) + MANUAL `php artisan optimize:clear`
(new /locks routes 404 until cleared); no queue restart. Prod owes optimize:clear.
Follows [[deploy-process]] + [[checkpoint-rule]] + [[document-each-change]].
