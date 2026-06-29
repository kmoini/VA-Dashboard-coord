---
name: client-workspace-firm-tools-and-inbox
description: "2026-06-27 session — client portal Inbox overhaul (attachments+voice, Invitation folded in) + Books/Report/Accounting/Integration added to the client workspace, scoped per-client. Read before touching the client portal or exposing any firm tool to clients."
metadata: 
  node_type: memory
  type: project
  originSessionId: 17bad86a-d76b-4d18-8ff0-27c8095a333f
---

Work done 2026-06-27 (extends [[client-workspace-architecture]]). **All code on origin/dev (auto-commit). NOT checkpointed/deployed — waiting for Amin to test** per [[wait-for-user-test-before-deploy]]. Prod owes only `npm run build`. Full handoff: `docs/client-workspace-inbox-and-firm-tools-handoff.md`.

**A. Client portal "Messages" → "Inbox":**
- Attachments now RENDER in the thread (image / `<audio>` player / file card) via `MsgAttachment` + `detectFileKind()` (keys off MIME + filename ext, so mobile `video/webm` voice notes get a player).
- Client can SEND files (paperclip, up to 5) + record VOICE (MediaRecorder → `voice-message-*.webm`). `sendMessage` validates `attachments[]`, body nullable, reuses `storeUploadedFiles()`. `ALLOWED_UPLOAD_TYPES` gained `audio/webm, audio/ogg, audio/wav, video/webm, image/gif`.
- Sidebar "Messages"→"Inbox"; standalone "Inbox" (notifications) → "Invitation", then **folded INTO** the Inbox page as a pinned left-rail item (two-pane: rail = Invitation + firm conversation; right = thread/composer OR notifications). `messages()` also passes `notifications`. Composer `lg:pr-20` so Send clears the AI Assistant FAB.

**B. Firm tools in the client workspace — Books · Report · Accounting · Integration, each scoped to the client's own `client_id`** (Amin chose "all 4, scoped"). THE REUSABLE PATTERN to expose any firm tool to clients safely:
1. Add the route name to the `ResolveTenant` client firewall allow-list (the `routeIs(...)` block).
2. Swap that route's `role.min:N` → **`role.min.client:N`** (new middleware `EnsureMinRoleLevelOrClient`, alias in `bootstrap/app.php`; passes client-portal users, still gates staff by level). ONLY the intended routes — Settings & Payroll stayed `role.min:3` so clients remain blocked.
3. Controller must scope to `activeClientId()` / `$tenant->clientId` for client-portal users.
4. Verify nothing firm-wide leaks. **Danger ones fixed:** `QuickBooksController@index` now filters to the client's own connection; `reports.*` (firm-wide ReportsController w/ all-clients picker) was deliberately LEFT blocked — the client "Report" tab points at `/report` which is a Coming-Soon placeholder. Books/Accounting were already `activeClientId`-scoped. QBO self-connect was already client-aware (`can.manage.quickbooks` + `targetClientId`).

Security verified (Playwright): client blocked from `/reports`, `/settings` (403), `/payroll`, `/clients`; Integration shows only their own QBO; accountant `/books /accounting /integration` still 200.
