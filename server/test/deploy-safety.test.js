import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtemp, readFile, rm, mkdir, writeFile, utimes, readdir, stat } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';
import { join } from 'node:path';
import { execFileSync } from 'node:child_process';
import Database from 'better-sqlite3';
import { backupDatabase } from '../src/backup.js';
import { bootstrapEnv } from '../../deploy/bootstrap-env.mjs';

const root = fileURLToPath(new URL('../..', import.meta.url));
async function fixture(t) {
  const path = await mkdtemp(fileURLToPath(new URL('./.backup-', import.meta.url)));
  t.after(() => rm(path, { recursive: true, force: true }));
  return path;
}

test('backup awaits WAL snapshot, validates a restorable database, and retains in the same directory', async (t) => {
  const dataDir = await fixture(t);
  const source = new Database(join(dataDir, 'ironforge.db'));
  t.after(() => source.close());
  source.pragma('journal_mode = WAL');
  source.exec("CREATE TABLE records (value TEXT); INSERT INTO records VALUES ('preserved WAL data')");
  const backupDir = join(dataDir, 'backups');
  await mkdir(backupDir);
  const now = new Date();
  const old = join(backupDir, 'ironforge-2000-01-01.db');
  const recent = join(backupDir, 'ironforge-2000-01-02.db');
  const unrelated = join(backupDir, 'do-not-delete.db');
  for (const path of [old, recent, unrelated]) await writeFile(path, 'fixture');
  const expired = new Date(now.getTime() - 15 * 86400000);
  for (const path of [old, unrelated]) await utimes(path, expired, expired);

  const path = await backupDatabase({ dataDir, now });
  const restored = new Database(path, { readonly: true });
  try {
    assert.equal(restored.prepare('SELECT value FROM records').get().value, 'preserved WAL data');
    assert.equal(restored.pragma('integrity_check', { simple: true }), 'ok');
  } finally {
    restored.close();
  }
  assert.equal((await stat(path)).mode & 0o777, 0o600);
  assert.equal((await stat(backupDir)).mode & 0o777, 0o700);
  const files = await readdir(backupDir);
  assert.ok(!files.includes('ironforge-2000-01-01.db'));
  assert.ok(files.includes('ironforge-2000-01-02.db'));
  assert.ok(files.includes('do-not-delete.db'));
  assert.ok(!files.some((file) => file.endsWith('.tmp')));

  // Same-day reruns safely replace the previous snapshot only after success.
  source.exec("INSERT INTO records VALUES ('second snapshot')");
  await backupDatabase({ dataDir, now });
  const updated = new Database(path, { readonly: true });
  try { assert.equal(updated.prepare('SELECT count(*) AS n FROM records').get().n, 2); }
  finally { updated.close(); }
});

test('failed backup never creates a missing source or prunes existing backups', async (t) => {
  const dataDir = await fixture(t);
  const backupDir = join(dataDir, 'backups');
  await mkdir(backupDir);
  const goodBackup = join(backupDir, 'ironforge-2000-01-01.db');
  await writeFile(goodBackup, 'previous snapshot');
  await utimes(goodBackup, new Date('2000-01-01'), new Date('2000-01-01'));
  await assert.rejects(backupDatabase({ dataDir }));
  assert.equal(await readFile(goodBackup, 'utf8'), 'previous snapshot');
  assert.deepEqual(await readdir(dataDir), ['backups']);
});

test('additive schema upgrade preserves legacy kegel rows and can run repeatedly', async (t) => {
  const dataDir = await fixture(t);
  const database = new Database(join(dataDir, 'ironforge.db'));
  try {
    database.exec(`
      CREATE TABLE users (id INTEGER PRIMARY KEY, username TEXT UNIQUE NOT NULL, password_hash TEXT NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')));
      CREATE TABLE kegel_logs (id INTEGER PRIMARY KEY, user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        date TEXT NOT NULL, sets INTEGER NOT NULL, hold_seconds INTEGER NOT NULL,
        created_at TEXT NOT NULL DEFAULT (datetime('now')));
      INSERT INTO users(id,username,password_hash) VALUES (1,'legacy-fixture','unused');
      INSERT INTO kegel_logs(id,user_id,date,sets,hold_seconds) VALUES (42,1,'2026-09-30',2,3);
    `);
    const schema = await readFile(join(root, 'server/schema.sql'), 'utf8');
    database.exec(schema);
    database.exec(schema);
    assert.equal(database.prepare('SELECT sets FROM kegel_logs WHERE id=42').get().sets, 2);
    database.prepare('INSERT INTO kegel_requests(user_id,client_id,payload,kegel_id) VALUES (1,?,?,42)').run('key', '{}');
    database.prepare('DELETE FROM kegel_logs WHERE id=42').run();
    assert.equal(database.prepare('SELECT kegel_id FROM kegel_requests').get().kegel_id, null);
  } finally {
    database.close();
  }
});

test('bootstrap serialization preserves special characters without env interpolation or AI keys', () => {
  for (const password of ['Training$UNSET-123', "quote'and\"double#hash\\slash", '  spaces stay  ', 'emoji🔐pass123']) {
    const serialized = bootstrapEnv(password);
    const lines = serialized.trim().split('\n');
    assert.equal(lines.length, 2);
    assert.equal(lines[0], 'BOOTSTRAP_USERNAME=mjonir');
    const encoded = lines[1].slice('BOOTSTRAP_PASSWORD_BASE64='.length);
    assert.match(encoded, /^[A-Za-z0-9+/]+=*$/);
    assert.equal(Buffer.from(encoded, 'base64').toString('utf8'), password);
    assert.ok(!serialized.includes('OPENROUTER'));
  }
  for (const invalid of ['short', 'x'.repeat(129), 'line\nbreak123', 'null\0byte123']) {
    assert.throws(() => bootstrapEnv(invalid));
  }
});

test('deployment/hardening scripts parse and retain explicit safety boundaries (not executed)', async () => {
  // Syntax-only: never run deployment, ssh, docker, crontab, firewall or rsync.
  for (const script of ['deploy/deploy.sh', 'deploy/harden.sh']) {
    execFileSync('bash', ['-n', join(root, script)]);
  }
  const deploy = await readFile(join(root, 'deploy/deploy.sh'), 'utf8');
  assert.match(deploy, /--exclude '\.env\*'/);
  assert.match(deploy, /--exclude \/downloads\//);
  assert.match(deploy, /--exclude \/data\//);
  assert.match(deploy, /--exclude \/node_modules\//);
  assert.match(deploy, /if \[ "\$SKIP_APK" -eq 0 \]; then\s+"\$RSYNC_BIN"/);
  assert.doesNotMatch(deploy, /\/tmp\/if-env|scp |SESSION_SECRET|OPENROUTER_API_KEY/);
  assert.match(deploy, /umask 077/);
  assert.match(deploy, /ln "\$tmp" ~\/ironforge\/server\/\.env/);
  assert.match(deploy, /--provision/);
  const harden = await readFile(join(root, 'deploy/harden.sh'), 'utf8');
  assert.match(harden, /node src\/backup\.js/);
  assert.match(harden, /crontab -l 2>\/dev\/null \|\| true/);
  assert.doesNotMatch(harden, /db\.close\(\)|find \/home\/gomango/);
  const ignore = await readFile(join(root, 'server/.dockerignore'), 'utf8');
  assert.match(ignore, /^\.env\*/m);
  assert.match(ignore, /^data\//m);
});
