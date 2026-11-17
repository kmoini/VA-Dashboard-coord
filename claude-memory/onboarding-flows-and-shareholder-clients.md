---
name: onboarding-flows-and-shareholder-clients
description: "Session 2026-10-19 (marketing-repo session, dashboard questions): how accountant sign-up, self-serve client → firm connection, closed-account emails and \"3 clients who are shareholders of one corporation\" behave TODAY, plus the two invitation fixes shipped (cp-307, closed-account message). READ before onboarding, invitation, account-close or shareholder-client questions."
metadata:
  node_type: memory
  type: project
  originSessionId: 764f174e-6cce-4fdb-a02c-bf2a4f5d6188
  modified: 2026-11-14T15:21:54.415Z
---

Written 2026-11-14 from the 2026-10-19 session (Amin asked, in Persian). Repo copy:
`va-dashboard2/docs/ONBOARDING-FLOWS-AND-SHAREHOLDER-CLIENTS.md` (same content, English,
for the team) and `docs/REFERRAL-ACCEPT-ACTOR-FIX-2026-10-19.md` (the incident).

## What was asked and answered

1. **Can an accountant sign up with a company email?** Yes. `/register` only needs a valid,
   unique email (no domain rule). `RegistrationService::firm()` makes the firm + super_admin
   owner, mails verification, registers the firm in the mobile directory. Phone, Google and
   Facebook sign-up call the same service.
2. **How does a self-serve (client-workspace-only) client join an accountant?** Only one web
   path: the accountant invites that SAME email (ReferralToken); the client opens the link and
   enters their EXISTING password; `ReferralController::accept()` grants the firm access to the
   existing client (ClientAccessService::switchTo, scope all/from_date, books_access). Nothing
   is re-parented; `ClientAdoptionService::adopt()` has NO web caller (only releaseToSelfServe).
   Clients cannot search/invite an accountant on the web (mobile app only). Each client accepts
   separately; no bulk connect.
3. **"Account already exists" on the referral page** = the email is an accountant/staff user or a
   firm-managed client. By design the referral never takes those over. Check on the server with
   tinker (`User::where('email',..)` → type, client_id, firm, is_personal). Accountant type →
   use another email or close that account.
4. **Closing an account does NOT free the email.** Users soft-delete; `users.email` stays unique
   across trashed rows ON PURPOSE (migration 2026_08_11_000003 released phone numbers and
   deliberately not emails: an address is an identity in the mobile directory). Phone memory
   records this as a decision not to reverse. Releasing an address is an operator action:
   `User::onlyTrashed()->where('email',X)->firstOrFail()->forceFill(['email'=>'closed-<id>-X'])->save()`
   (full command in the docs file). `/register` also says "taken" for such emails.
5. **3 clients who are shareholders of one private corporation.** A corporation is a
   `client_companies` row inside ONE client file, not a client. Correct setup: a client file for
   the corporation itself; each shareholder keeps their own file; in the corporation's People tab
   add each shareholder (role shareholder + ownership_percent, `linked_client_id` → their own
   file); optionally a RelatedEntity (owner_controlled) between files so interco matching
   proposes transfer pairs. Shareholder GIFI rules (2781 / 1300 etc.) apply per the entry's
   company entity type. GAPS: the AI does not read People yet (People phase 3, unbuilt); no
   automatic mirror entry in the other file; one portal user per client, so 3 shareholders cannot
   each log into the corporation's file; no shareholder-balance view.

## What shipped

- cp-307 = 29f40d8 LIVE 2026-10-19: guest routes (`/refer/{token}` accept, team invitation
  accept) passed no `user_id` to the activity log → `chk_activity_logs_user_or_ai` → whole
  sign-up rolled back behind "We could not complete your registration". Both controllers now
  pass the acceptor explicitly. Test `tests/Feature/Referral/GuestAcceptanceActivityLogTest.php`
  (3 tests; flips `isRunningInConsole` by reflection + drops ValidateCsrfToken so the log row is
  really written). See [[activity-log-entity-type-trap]] (4th hit).
- 845cf25 (on origin/main, shipped in a later checkpoint): referral accept checks
  `User::onlyTrashed()` first and names the closed account instead of the generic failure.
- Tag mishap that day: Amin ran `git tag` on the SERVER before pulling; recorded in
  [[checkpoint-rule]].

**How to apply:** answer these questions from this file + the docs copy; do not promise
bulk-connect, client-side accountant search, email release on close, or AI-read People,
none exist. Candidate builds if asked: multiple portal users per client file, People phase 3,
shareholder balance view, clearer `/register` message for closed emails.

Related: [[client-workspace-architecture]], [[registry-people-redesign-plan]],
[[shareholder-gifi-rules]], [[phone-authentication]], [[past-clients-access-revocation]].
