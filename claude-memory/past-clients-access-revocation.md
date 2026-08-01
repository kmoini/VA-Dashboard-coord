---
name: past-clients-access-revocation
description: "Ending an engagement = \"past client\" with history-kept (read_only + until_date) or cut (revoked); Delete Client REMOVED from /clients; enforce via Transaction::forFirm + new Attachment::forFirm. DEPLOYED to prod as checkpoint-194 (2026-07-30); migrate + optimize:clear owed on the server."
metadata: 
  node_type: memory
  type: project
  originSessionId: 0859969f-2119-4765-8978-807596d31e53
  modified: 2026-07-30T16:00:29.404Z
---

Ending a client engagement never deletes records, it only ends the FIRM's access.
Two outcomes, chosen by whoever ends it (client in portal, or admin on /clients),
and the client stays listed under **Past clients** either way:

- keep history → grant `status=active`, `access=read_only`, `until_date=<end day>`
- cut access   → grant `status=revoked` (name only, no data)

`client_firm_grants.until_date` (migration `2026_07_29_000001`) is the upper bound
mirroring the existing `from_date`. Enforced at two query chokepoints only:
`Transaction::forFirm()` and the NEW `Attachment::forFirm()` (documents have no
business date, so `created_at` is the bound; it replaced 14
`whereHas('client', …forFirm)` call sites in DocumentsController).

Client scopes: `forFirm` = any active grant · `currentForFirm` = active + full
(directory, ClientSwitcher, upload/create destinations) · `pastForFirm` = revoked
or read-only.

**Delete Client is gone** — the route `clients.destroy`, `ClientsController::destroy()`
and the UI menu item were removed; the three-dot menu now offers "End engagement"
(admin only). Do not reintroduce a client delete path.

Two non-obvious rules baked in: a read-only firm is NOT "the accountant"
(`currentAccountantFirmId` skips read-only), and `grant(exclusive:true)` only
revokes `access=full` grants so hiring a new accountant does not wipe an old
firm's agreed history.

Fixed along the way: soft-deleted clients kept ACTIVE grants, so their
transactions lingered in firm-wide "All clients" views (Amin reported this);
and `releaseToSelfServe()` crashed for clients with no email
(`accountant_accounts.firm_email` is NOT NULL).

State: **DEPLOYED to production 2026-07-30** as commit `cb64f2b` on `main`, tag
`checkpoint-194`. ⚠️ The n8n webhook only pulls + builds, so `php artisan migrate`
+ `optimize:clear` + `queue:restart` were still OWED on the server — until they
run, `/clients` errors (`until_date` missing) and the removed `clients.destroy`
route stays cached. Suite: 1062 pass / 75 fail, all 75 pre-existing.

⚠️ **CLAUDE.md's "all work on dev" rule was WRONG and has been rewritten**:
`dev` is 139 commits behind and abandoned; checkpoints 184-194 all live on
`main`, and production deploys from `main`. See [[checkpoint-rule]].

Docs: `docs/PAST-CLIENTS-ACCESS-REVOCATION.md` (incl. the deploy section) per
[[document-each-change]]. Related: [[client-workspace-architecture]],
[[client-registry-multi-company]], [[deploy-process]].
