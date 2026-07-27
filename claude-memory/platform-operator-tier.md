---
name: platform-operator-tier
description: platform_admin tier + Telescope + view-as impersonation (cp162-163); super_admin scope bug fixed; operator accounts via platform:admin cmd
metadata: 
  node_type: memory
  type: project
  originSessionId: b625b019-e764-4bae-b047-0190c8750810
  modified: 2026-07-23T00:33:59.847Z
---

Platform operator tier shipped 2026-07-22 (checkpoint-162 Telescope, checkpoint-163 tier + impersonation). Doc: `va-dashboard2/docs/platform-operator-tier.md` + `docs/monitoring-telescope.md`.

- ⚠️ SECURITY BUG FIXED: migration 2026_06_18_000001 had set super_admin (= EVERY CPA firm owner, assigned at registration) to scope='platform', making all firm owners pass PlatformAdminMiddleware/isPlatformScoped(). Fixed in cp-163 migration: only platform_admin stays scope='platform'.
- Monitoring gates (`/telescope` provider gate + `/admin/monitoring` platform.admin middleware) key on the EFFECTIVE operator (ImpersonationService::operator(), so they work mid-impersonation) + permission `platform.monitoring`. Never gate operator surfaces on isSuperAdmin() — that's a per-firm role.
- Impersonation: ImpersonationService session swap (`impersonator_id`), operators never impersonatable, activity log impersonate.start/stop (action CHECK superset — `transaction.merged` in the list is load-bearing). Routes /platform/* sit OUTSIDE resolve.tenant (portal firewall would trap "leave") with auth only.
- Operator accounts: `php artisan platform:admin <email> [--create --name=] [--revoke] [--reset-password]` — temp passwords print once to console, NEVER stored in repo (auto-commit!). Operators: moinikamyar@gmail.com, amin.1988.hn@gmail.com, shahab.arvin.sadr@gmail.com.
- Deploy webhook DID run composer install on prod (telescope live+403 right after push) — more capable than old memory said; but migrate + optimize:clear stayed manual (platform routes 404'd until optimize:clear).

**Why:** operator vs firm tiers must never blur; cross-firm surfaces are permission-gated (platform.monitoring / platform.impersonate), not role-name-gated.
**How to apply:** READ before touching roles.scope, monitoring gates, impersonation, or adding cross-firm operator features. See [[checkpoint-rule]], [[activity-log-entity-type-trap]], [[deploy-process]].
