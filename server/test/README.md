# Isolated regression tests

Run `npm test` from `server/`. These Node tests use Fastify injection (no listener),
synthetic users, and fresh databases under `server/test/.regression-*` or
`server/test/.backup-*`; fixtures are removed afterward. Local `.env` loading is
explicitly disabled before database imports, and AI requests are not exercised.
They do not use `server/data`, bootstrap credentials, or a live server.

Coverage:
- Full workout replacement, duplicate/zero-rep rejection, transaction rollback
  after an injected SQLite write failure, and user/exercise isolation.
- Kegel IDs; persistent user-scoped idempotency receipts; edit/replay behavior;
  conflicting keys; delete tombstones; legitimate multiple sessions per day.
- Complete check-in/kegel histories past the former 60/90-row cutoffs.
- Real calendar dates (including leap-year rules), strict reminder flags/time
  strings, unknown fields, and authentication boundaries.
- Awaited WAL backup, restored-data/integrity checks, permissions, same-day
  replacement, successful-only retention, and missing-source failure.
- Literal-safe synthetic bootstrap password serialization and static deployment
  safety assertions. `bash -n` checks both shell scripts without executing them.

The older `smoke.sh`/`extended.sh` scripts target a running server and can mutate
its data; they are NOT part of `npm test`. Do not use them against production as
an audit. These regressions do not establish live SSH/rsync behavior, actual cron
installation, container-volume permissions, an off-host restore, Android signing,
or production recovery readiness.

## Updated API contracts

`POST /api/logs/workout` replaces all sets for the authenticated user's
`(date, exercise)` in one transaction. Omitted sets are removed. Empty arrays,
repeated set numbers, zero/fractional reps, and unknown fields return HTTP 400.

`POST /api/logs/kegels` returns `{ "ok": true, "id": <server id> }`. For safe
retry, generate one durable `clientId` per logical session and reuse it unchanged
on every retry. `idempotencyKey` in the body or the `Idempotency-Key` header are
aliases; if more than one is supplied they must match. Keys allow 1–128 ASCII
letters, digits, `.`, `_`, `:`, `-` and are scoped to the authenticated user.

Identical retries return the original ID without changing the row. Reusing a key
with a different creation payload returns 409. Receipts retain the original
payload even after edits; a retry does not undo those edits. Deletion retains a
receipt tombstone, so retry after deletion returns 409 rather than resurrecting
the session. A request without a key still creates a new legitimate session;
legacy clients do not gain replay protection until they persist and send a key.
`/api/state` includes each session's `clientId` (null for legacy unkeyed rows).
The additive `kegel_requests` table is created by the normal schema startup path.

`/api/state` now returns complete stored histories, not an implicitly bounded
snapshot. Dates must be real Gregorian dates in `YYYY-MM-DD` (years 0001–9999).
`reminder_enabled` accepts only the strings `0` and `1`. Clients must handle
validation responses rather than assuming success.
