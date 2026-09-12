# 11 — Security Architecture (Nobody Gets In But You)

Threat model: the app is exposed to the internet through a Cloudflare Tunnel. Attackers =
internet scanners, credential-stuffers, bots. Data = personal health/fitness data. Availability
matters less than confidentiality. Single user = we can be maximally strict.

## Defense in Depth — 6 layers

### Layer 1 · Cloudflare Access (edge gate) — the most important one
Even if the app had a zero-day, attackers never reach it:
1. Cloudflare Zero Trust dashboard → Access → Applications → Add application.
2. Domain: `gym.abba-s.dev` (confirmed hostname).
3. Policy: **Allow** → Emails → your exact email only.
4. Result: every visitor first hits Cloudflare's login (email OTP or your Google account).
   Scanners/bots get a Cloudflare page, never your app. Brute force on your app login
   becomes impossible from the internet.
5. Optional: enable Cloudflare WAF rules — block non-IN countries if you never travel.

### Layer 2 · No inbound ports
- App container binds `127.0.0.1:8420` — loopback only. `docker compose` publishes nothing to 0.0.0.0.
- Cloudflared connects OUTBOUND to Cloudflare; no router forwarding, no firewall holes.
- SSH (port 22) stays as-is: key-based auth only. `harden.sh` enforces
  `PasswordAuthentication no` if not already set.

### Layer 3 · Application auth (single user)
- One account: username `mjonir`. No registration endpoint exists at all.
- Password stored as **argon2id** hash (memory-hard, the current best practice). Never plaintext.
- **2FA removed 2026-09-05 (user request):** login is password-only (argon2id). Cloudflare Access at the edge remains the mandatory second gate — internet attackers never reach the login form. Re-add TOTP later by restoring the otplib flow if desired.
- Session: 128-bit random ID, HttpOnly + Secure + SameSite=Strict cookie, 12 h expiry,
  rotated on login. Server-side session table → instant revocation.
- Login rate limit: 5 attempts/min/IP, exponential backoff, 15 min lockout after 10 failures.
- Generic error messages ("invalid credentials") — never reveal which part failed.

### Layer 4 · Container hardening (Dockerfile + compose)
```yaml
# docker-compose.yml key settings
services:
  ironforge:
    build: .
    user: "10001:10001"            # non-root
    read_only: true                # immutable root fs
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    pids_limit: 200
    mem_limit: 512m
    volumes:
      - ironforge-data:/data       # ONLY writable path (SQLite lives here)
    ports:
      - "127.0.0.1:8420:8420"      # loopback only — never 0.0.0.0
    restart: unless-stopped
```

### Layer 5 · API & HTTP hardening
- Security headers on every response: `Content-Security-Policy` (self + YouTube only),
  `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, `Referrer-Policy: no-referrer`,
  `Permissions-Policy: camera=(), microphone=(), geolocation=()`.
- Strict JSON schema validation (ajv) on every request body — unknown fields rejected.
- SQL: better-sqlite3 **prepared statements only** — injection is structurally impossible.
- No eval, no dynamic require, no user-controlled paths (path-traversal-proof static serving).
- APK download requires a valid session — no public link to leak.
- CORS: same-origin only (API and web served from one origin → no CORS needed at all).

### Layer 6 · Server hygiene (harden.sh)
- UFW: default deny incoming; allow 22 (SSH) + existing services only. Nothing new opened.
- unattended-upgrades enabled for security patches.
- App runs as dockerized non-root; host user `gomango` untouched.
- Secrets: `/home/gomango/ironforge/.env`, chmod 600, never in git, never in the Docker image
  (mounted at runtime).

## Secrets inventory (what must never leak)
| Secret | Where it lives |
|---|---|
| Admin password (argon2id hash) | server `.env` / generated at first boot |
| Session secret (32 B random) | server `.env` |
| TOTP secret | SQLite DB (encrypted at rest optional) |
| Cloudflare tunnel token | YOUR cloudflared config (not our repo) |
| APK signing keystore + passwords | local machine only + password manager backup |

## Backup & recovery
- Nightly cron on yarmuk: `sqlite3 /data/ironforge.db ".backup '/data/backups/ironforge-$(date +%F).db'"` — 14-day retention.
- Weekly: `rsync yarmuk:~/ironforge/server/data/backups/ ~/f/gym/backups/` from your PC.
- Worst case (server dies): reinstall = re-run deploy.sh + restore latest backup. ~15 min.

## If compromise is ever suspected
1. `docker compose down` on yarmuk (app offline instantly).
2. Delete the Cloudflare Access app / tunnel route.
3. Rotate: admin password, session secret, Cloudflare credentials, SSH keys.
4. Review `docker logs ironforge` + Cloudflare Access audit logs (Access logs every auth event).

## Explicitly out of scope (accepted trade-offs)
- Cloudflare terminates TLS and can technically see traffic — accepted; standard for tunnels.
- fail2ban not used: useless behind a tunnel (all IPs are Cloudflare's) — Access replaces it.
