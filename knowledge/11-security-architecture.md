# 11 — Security architecture and verification boundaries

This is the **local implementation**, not proof that the live domain is protected. The app handles private fitness records, pelvic-floor logs, optional AI conversations and password-protected accounts. Do not assume external Cloudflare Access, backups or Android distribution are configured without checking the actual host.

## Edge and host

- If Cloudflare Tunnel and **Access** have been explicitly configured for the public hostname, an Access policy can restrict who reaches the app. Verify the policy and its fail-closed behavior independently, including on mobile data. Merely having a tunnel does **not** enable Access.
- Compose binds only `127.0.0.1:8420` on the host. This is not a substitute for host-firewall/SSH review. `deploy/harden.sh` checks SSH password-auth status and **warns**; it does not edit sshd settings or prove that password login is disabled.
- Compose uses non-root user `10001`, a read-only root filesystem, dropped capabilities and a persistent writable `/data` volume. Consult `server/docker-compose.yml` for current resource/security options.

## Login and HTTP

- The server uses Argon2id password hashes stored in SQLite. Login is password-only; there is no current TOTP feature or `totp_secret` column. The first-run provisioning variable (`BOOTSTRAP_PASSWORD_BASE64`, or legacy plaintext variable) remains a secret even when base64 encoded. Remove it **manually** from the server's `.env` after confirming the initial account; changing the login password does not scrub it.
- Session IDs use 32 random bytes (256 bits) and an HttpOnly, Secure, SameSite=Strict cookie. They expire after **30 days**; logout and password changes revoke sessions in SQLite. `SESSION_SECRET` is not used by this server auth implementation.
- Login limiting is a fixed 5-attempt/one-minute and 10-attempt/15-minute window keyed by Fastify's client IP, **not exponential backoff**. With `trustProxy:false` behind a tunnel, different visitors may share the proxy-peer rate bucket; verify edge limits and infrastructure behavior separately.
- Fastify has security headers and a restrictive CSP with explicit external asset allowlists, schemas for mutation bodies, and parameterized SQL. Unknown JSON fields are rejected at the mutation routes. No security claim follows from unit tests alone; review actual reverse-proxy settings and live headers.
- AI chat, if configured, sends selected fitness/log context and the message to OpenRouter. The owner controls the server-side key in an ignored, permission-restricted `.env`; never put it in the Flutter app, Git, logs or a public export. The provider may process transmitted records. Do not use AI chat for details you do not want sent outside the server.

## Recovery and secret inventory

| Material | Actual location / action |
|---|---|
| User password hash, sessions, logged data and chat | SQLite under the persistent `/data` volume; protect snapshots too |
| Initial account password | Server `.env` provisioner variable until manually removed |
| Optional OpenRouter key | Server-side ignored `.env` only; rotate if exposed |
| Cloudflare tunnel credentials | External host/Cloudflare configuration; not verified here |
| Android release signing keystore | **Not configured**; release currently uses debug signing and is not distribution-ready |

- `deploy/harden.sh` can install a nightly container job running `node src/backup.js`. That helper awaits a SQLite snapshot, verifies it and retains up to 14 days of backups **inside `/data/backups` on the same named volume**. The job has not been run against the live host as part of the 30 September fixes. Check job execution, ownership, available space and **restore to a disposable database** before trusting it.
- Same-volume backups do not survive volume/host loss. Export snapshots to independent access-controlled storage using the actual named volume, not the unrelated repository `server/data/backups` path. Securely store and periodically test an off-host copy. No untested “15-minute recovery” promise is made.
- Runtime database/WAL/SHM/bootstrap files were previously tracked. Their removal from the Git index prevents future tracking but does not erase historical commits; assess distribution and rotate affected material separately with explicit authorization.

If compromise is suspected: isolate the service, preserve evidence, revoke sessions/credentials, check Access and host logs, and restore only from a verified clean backup. Do not run host-hardening or deployment scripts as a diagnostic shortcut.
