---
name: clients-redesign-plan
description: Agreed IA for the accountant Clients-area redesign (workspace + tabs + Companies folded in). Read before building the clients redesign.
metadata: 
  node_type: memory
  type: project
  originSessionId: 17bad86a-d76b-4d18-8ff0-27c8095a333f
---

Redesign of the accountant **Clients** area, agreed with Amin 2026-06-25. **COMPLETE — phases 1-4 built + deployed (checkpoints 108-111).** Directory cards + one Add-client menu (108); client workspace tabs Overview/Profile (109); People tab (110); Companies tab + vendor auto-population/backfill + sidebar removal + matchByText fatal fix (111). Per-client Projects pick-list wired into RK/voice (109). Details below were the original plan.

**What each piece does today** (so the redesign preserves behavior):
- `/clients` (`ClientsController@index`, `Clients/Index.jsx`): directory of the firm's
  client businesses + onboarding (5 buttons: Generate Link, Bulk Email, Bulk SMS, Add,
  Register). Cards w/ status toggle + "Access Master File".
- `/clients/{id}` (`ClientsController@show`, `Clients/Show.jsx`): client master file —
  3 KPI cards, cash-flow area + income/expense bar charts, recent-tx feed, and a GIANT
  `AccountSettingsModal` (4 sections: Core Identity & Contact, Data/Notes/Milestones,
  Firm Stakeholders & Partners, Bank Infrastructure[hidden]) that PATCHes core+metadata.
- "Account Settings" = that modal (edits ONE client's profile/registry), NOT firm settings.
- Companies (`/vendors`, `VendorsController`, `Settings/Companies.jsx`): registry of
  VENDORS (third parties in clients' txns, e.g. Esso/Staples) auto-extracted, with
  default category/GIFI/project/tax_treatment + aliases + merge + AI-proposed rules.
  A vendor is either firm-wide (`client_id=null`) or client-scoped (`client_id=X`).
  IMPORTANT: Companies ≠ Clients (vendors vs the firm's customers).

**Agreed redesign (all 4 of my recommendations accepted):**
1. Client detail → a **tabbed full-page "Client Workspace"** (kill the giant modal). Tabs:
   Overview (KPIs+charts+feed) · Profile (the registry, inline) · People (partners+notes)
   · Companies (vendors) · Documents (placeholder).
2. **Companies folded INTO the client workspace** as the "Companies/Vendors" tab, scoped
   to that client, with a toggle to also show firm-wide shared vendors. Companies LEAVES
   the sidebar. (Keep firm-wide merge/catalog reachable via that toggle.)
3. Clients list → **refined cards** (denser/professional), prominent pending-count +
   quick actions.
4. Onboarding → **one "Add client" button + dropdown** (Invite / Manual / Link), bulk
   email/SMS as secondary in the menu (was 5 separate buttons).

**Design system:** the green palette from CLAUDE.md (#2CA01C etc.).

**Process:** Amin may design it first in an external AI (I gave a full English design
prompt). Build will be PHASED + per the [[wait-for-user-test-before-deploy]] rule
(implement → build → he tests → then checkpoint/deploy). Likely phases:
(1) directory redesign + consolidated Add-client, (2) workspace shell + Overview +
Profile tabs (replace modal), (3) People tab, (4) Companies tab + firm-wide toggle +
remove `/vendors` from sidebar.

Redundancy to fix along the way: shallow `ClientsController@edit` vs the deep modal
(consolidate into Profile tab); tax auto-vs-manual lock state should be explicit.
