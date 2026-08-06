# Inbox — Messages for Amin's Claude

## 2026-08-06 — false-positive "Reauth needed" badge in BooksController (Bigcapital)

Kamyar found and fixed a UI bug on `/accounting` (QuickBooks tab) and traced the identical
bug into `BooksController.php`, which you currently have locked — leaving this here so your
Claude can pick it up without waiting on the lock.

**The bug:** `BooksController::presentConnection(BigcapitalConnection $c)` at
`app/Http/Controllers/BooksController.php:1127` sets the `token_expired` prop from
`$c->isAccessTokenExpired()`. That method (in `app/Models/BigcapitalConnection.php:58`) just
checks whether the *cached login token* (`token_expires_at`, short TTL per
`config('services.bigcapital.token_ttl')`) is stale — which is expected almost all the time
between calls, since `BigcapitalService` re-logs-in lazily on the next authenticated request
(mirrors `QuickBooksService::ensureValidToken()`). It is NOT a signal that the org actually
needs reconnecting.

Net effect: the `/books` `ActiveOrgBanner` (or equivalent) shows a false "Reauth needed" /
token-expired warning for any Bigcapital org that just hasn't been hit in a while — exactly
the same false alarm Kamyar saw on `/accounting` for a QuickBooks sandbox company.

**Reference fix already applied** (QuickBooks side, `app/Http/Controllers/AccountingController.php:229`):
```php
// Genuine reauth need = no refresh token to lazily renew with, not the
// ~1h access token being stale (that's expected and self-heals via
// QuickBooksService::ensureValidToken() on the next API call).
'token_expired' => ! $c->isConnected(),
```
`QuickBooksConnection::isConnected()` already existed (`! empty(realm_id) && ! empty(refresh_token)`).

**What `BigcapitalConnection` needs:** it has no `isConnected()`/equivalent method yet — check
`app/Models/BigcapitalConnection.php` for what actually indicates a live, usable connection
(likely `! empty($this->organization_id) && ! empty($this->email) && ! empty($this->password)`,
mirroring the QBO pattern of "do we have what we need to silently re-auth", not "is the cached
token fresh right now"). Add that method, then swap `BooksController.php:1127`'s
`'token_expired' => $c->isAccessTokenExpired()` to use it instead. Leave `isAccessTokenExpired()`
itself alone — it's correctly used internally by `BigcapitalService` to decide when to
re-login (same as the QBO side).

No test currently asserts on `token_expired` in `tests/Feature/Bigcapital/`, so this is a
safe, isolated change — just the one line in `presentConnection()` plus the new model method.
