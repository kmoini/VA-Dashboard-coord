---
name: platform-operator-tier
description: platform_admin tier + Telescope + view-as impersonation (cp162-163); super_admin scope bug fixed; operator accounts via platform:admin cmd
metadata: 
  node_type: memory
  type: project
  originSessionId: b625b019-e764-4bae-b047-0190c8750810
  modified: 2026-07-30T20:51:17.338Z
---

Platform operator tier shipped 2026-07-22 (checkpoint-162 Telescope, checkpoint-163 tier + impersonation). Doc: `va-dashboard2/docs/platform-operator-tier.md` + `docs/monitoring-telescope.md`.

- ⚠️ SECURITY BUG FIXED: migration 2026_06_18_000001 had set super_admin (= EVERY CPA firm owner, assigned at registration) to scope='platform', making all firm owners pass PlatformAdminMiddleware/isPlatformScoped(). Fixed in cp-163 migration: only platform_admin stays scope='platform'.
- Monitoring gates (`/telescope` provider gate + `/admin/monitoring` platform.admin middleware) key on the EFFECTIVE operator (ImpersonationService::operator(), so they work mid-impersonation) + permission `platform.monitoring`. Never gate operator surfaces on isSuperAdmin() — that's a per-firm role.
- Impersonation: ImpersonationService session swap (`impersonator_id`), operators never impersonatable, activity log impersonate.start/stop (action CHECK superset — `transaction.merged` in the list is load-bearing). Routes /platform/* sit OUTSIDE resolve.tenant (portal firewall would trap "leave") with auth only.
- Operator accounts: `php artisan platform:admin <email> [--create --name=] [--revoke] [--reset-password]` — temp passwords print once to console, NEVER stored in repo (auto-commit!). Operators: moinikamyar@gmail.com, amin.1988.hn@gmail.com, shahab.arvin.sadr@gmail.com.
- Deploy webhook DID run composer install on prod (telescope live+403 right after push) — more capable than old memory said; but migrate + optimize:clear stayed manual (platform routes 404'd until optimize:clear).

**checkpoint-201 (2026-07-30) — cross-firm CLIENT directory.** Doc: `va-dashboard2/docs/platform-client-directory.md`. The switcher was firm-only, so a client with NO accountant was unreachable as a client: its personal workspace (`accountant_accounts.is_personal`) was listed as a fake firm and its `type='client'` viewer was offered as that firm's "accountant". Now: a second **Clients** tab (`GET /platform/clients`, flat cross-firm, server search + paging, filters no_accountant/no_login/inactive) and `POST /platform/enter-client/{client}` which resolves the identity itself (accountant + pinned client, else the client's own portal login, else 422). NOT deployed yet at time of writing.
- ⚠️ `ImpersonationService::isOperatorSession()` (active AND impersonator still holds platform.impersonate) now relaxes THREE user-facing dead ends for support only: lapsed subscription, inactive client (both in ResolveTenant), and unverified email — the `verified` alias points at `EnsureEmailIsVerifiedOrOperator`, because PersonalWorkspaceService leaves `email_verified_at` null so every fresh self-serve client bounced operators to /verify-email. Real users still hit all three.
- ⚠️ Never hand a column-limited Eloquent model to `Auth::login()`. The old portal-user lookup selected `id, client_id, name` only, so the impersonated user had no `accountant_account_id` → 403 "No tenant associated with this account" on the next request AND the audit row attributed to the OPERATOR's firm.
- Switching or leaving a target now clears `current_client_id` + the company scope; those pins belong to the previous identity. The header stays three chips (firm → client → company), and `client-switcher.company` is allowlisted in the portal firewall, so a client with no accountant can still narrow between several companies.

**Why:** operator vs firm tiers must never blur; cross-firm surfaces are permission-gated (platform.monitoring / platform.impersonate), not role-name-gated.
**How to apply:** READ before touching roles.scope, monitoring gates, impersonation, or adding cross-firm operator features. See [[checkpoint-rule]], [[activity-log-entity-type-trap]], [[deploy-process]].
