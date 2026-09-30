import { randomBytes } from 'node:crypto';
import argon2 from 'argon2';
import db from './db.js';

// A private single-user app should not unexpectedly log out during a normal
// training block. Keep the HttpOnly cookie, but use a 30-day bounded session;
// explicit logout and password changes still invalidate it immediately.
const SESSION_HOURS = 24 * 30;
const RATE_WINDOW_MS = 60 * 1000;       // 1 min
const RATE_MAX = 5;                      // 5 attempts/min
const LOCK_THRESHOLD = 10;               // attempts in window
const LOCK_MS = 15 * 60 * 1000;          // 15 min lockout

const q = {
  userByName: db.prepare('SELECT * FROM users WHERE username = ?'),
  insertSession: db.prepare(
    `INSERT INTO sessions (id, user_id, expires_at) VALUES (?, ?, datetime('now', '+${SESSION_HOURS} hours'))`),
  sessionById: db.prepare(
    `SELECT s.id AS sid, s.user_id, s.expires_at, u.username FROM sessions s
     JOIN users u ON u.id = s.user_id
     WHERE s.id = ? AND s.expires_at > datetime('now')`),
  deleteSession: db.prepare('DELETE FROM sessions WHERE id = ?'),
  deleteUserSessions: db.prepare('DELETE FROM sessions WHERE user_id = ?'),
  addAttempt: db.prepare('INSERT INTO login_attempts (ip, attempted_at) VALUES (?, ?)'),
  recentAttempts: db.prepare(
    'SELECT COUNT(*) AS n FROM login_attempts WHERE ip = ? AND attempted_at > ?'),
  clearAttempts: db.prepare('DELETE FROM login_attempts WHERE ip = ?'),
  setPassword: db.prepare('UPDATE users SET password_hash = ? WHERE id = ?'),
};

export function checkRateLimit(ip) {
  const { n } = q.recentAttempts.get(ip, Date.now() - LOCK_MS);
  if (n >= LOCK_THRESHOLD) return { locked: true, retryAfterSec: LOCK_MS / 1000 };
  const { n: recent } = q.recentAttempts.get(ip, Date.now() - RATE_WINDOW_MS);
  if (recent >= RATE_MAX) return { locked: true, retryAfterSec: 60 };
  return { locked: false };
}

export async function verifyLogin(ip, username, password) {
  const rl = checkRateLimit(ip);
  if (rl.locked) return { ok: false, locked: true, retryAfterSec: rl.retryAfterSec };

  q.addAttempt.run(ip, Date.now());
  const user = q.userByName.get(username);
  // Constant-shape: verify against a dummy hash when user missing (mitigates user enumeration timing)
  const hash = user?.password_hash
    || '$argon2id$v=19$m=65536,t=3,p=4$AAAAAAAAAAAAAAAAAAAAAA$AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';
  const passOk = await argon2.verify(hash, password).catch(() => false);
  if (!user || !passOk) return { ok: false };

  q.clearAttempts.run(ip);
  return { ok: true, user };
}

export function createSession(userId) {
  const id = randomBytes(32).toString('base64url');
  q.insertSession.run(id, userId);
  return id;
}

export function getSession(id) {
  if (!id || typeof id !== 'string' || id.length > 64) return null;
  return q.sessionById.get(id) || null;
}

export function destroySession(id) {
  q.deleteSession.run(id);
}

export function destroyAllSessions(userId) {
  q.deleteUserSessions.run(userId);
}

export async function changePassword(userId, newPassword) {
  q.setPassword.run(await argon2.hash(newPassword), userId);
}

export async function bootstrapUser(username, password) {
  const existing = q.userByName.get(username);
  if (existing) return existing;
  const hash = await argon2.hash(password);
  db.prepare('INSERT INTO users (username, password_hash) VALUES (?, ?)').run(username, hash);
  return q.userByName.get(username);
}

export const COOKIE_NAME = 'if_session';
export const COOKIE_OPTS = {
  path: '/',
  httpOnly: true,
  secure: true,
  sameSite: 'strict',
  maxAge: SESSION_HOURS * 3600,
};
