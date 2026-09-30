import './load-env.js';
import Database from 'better-sqlite3';
import { readFileSync, mkdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const __dirname = dirname(fileURLToPath(import.meta.url));
const DATA_DIR = process.env.DATA_DIR || join(__dirname, '..', 'data');
mkdirSync(DATA_DIR, { recursive: true });

const db = new Database(join(DATA_DIR, 'ironforge.db'));
db.pragma('journal_mode = WAL');
db.pragma('foreign_keys = ON');
db.exec(readFileSync(join(__dirname, '..', 'schema.sql'), 'utf8'));

// Periodic cleanup of expired sessions + old login attempts (every 30 min)
setInterval(() => {
  db.prepare(`DELETE FROM sessions WHERE expires_at < datetime('now')`).run();
  db.prepare(`DELETE FROM login_attempts WHERE attempted_at < ?`).run(Date.now() - 15 * 60 * 1000);
}, 30 * 60 * 1000).unref();

export default db;
