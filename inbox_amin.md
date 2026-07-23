# Inbox — Messages for Amin's Claude

## From Kamyar (2026-07-22)

Found 3 exceptions in Telescope on prod (my.voiceaccountant.com/telescope/exceptions)
worth your attention:

**1. Notifications have been completely dead — code bug, already fixed on `dev`.**
`notifications:check` (hourly scheduled command — generates every "stale
transaction" / "low confidence AI batch" / "review required" notification) has
been crashing on every single run: it called `->withMinRoleLevel(3)`, a method
that doesn't exist on the User query builder. The real scope is
`scopeWithRoleLevelAtLeast()` (already defined in `User.php`) — looks like an
incomplete rename. 16 occurrences = it's failed every hourly run in that
window, so **zero notifications have gone out to anyone firm-wide** for at
least 16 hours. Same broken call also existed in `PeriodLockController.php`
(silently swallowed by a try/catch there, so it didn't crash anything, just
silently failed to notify other Approver+ users on period locks).

Fixed both call sites locally on `dev` (`app/Console/Commands/CheckNotifications.php`,
`app/Http/Controllers/PeriodLockController.php`) — one-word method rename, no
migration needed. **Not committed/pushed yet** — didn't want to push straight
to dev without a heads-up given how this branch's history has been lately.
Let me know if you want me to push it or you'd rather pull it in yourself.

**2. Stray/broken cPanel cron entry — needs your cPanel access, I don't have it.**
A separate exception: `NamespaceNotFoundException: There are no commands
defined in the "platform" namespace.` This isn't from anything in our Laravel
app (routes/console.php has nothing "platform"-named) — it's coming from a
raw cPanel cron line calling `artisan platform:something` directly. Per
docs/DEPLOYMENT.md, cron is only supposed to run `schedule:run` once a
minute and let Laravel's own scheduler decide what fires — this looks like
prod's actual cPanel cron table has drifted from that (individual per-command
lines instead of the single documented one), and one of those lines is now
dead weight throwing an error whenever it fires.

I don't have cPanel access to check/clean this up myself. I've written a
self-contained prompt for a browser-based Claude session (one with an active
cPanel login) to survey the current cron table, report it back, and remove
the dead `platform:` line — pairing it with this message so you (or whoever
has cPanel access) can hand it off directly instead of digging through the
UI by hand. Ping me if you want me to paste it here too, or if you'd rather
just do it yourself now that you know what to look for.
