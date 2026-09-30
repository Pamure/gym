// Run inside the application container: node src/backup.js
// Source, backups and retention all use the same named-volume DATA_DIR.
// Does not import db.js/load-env.js or bootstrap users.
import Database from 'better-sqlite3';
import { mkdir, chmod, rename, readdir, stat, unlink } from 'node:fs/promises';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import { randomUUID } from 'node:crypto';

export async function backupDatabase({ dataDir, backupDir = join(dataDir, 'backups'), now = new Date(), retentionDays = 14 }) {
  await mkdir(backupDir, { recursive: true, mode: 0o700 });
  await chmod(backupDir, 0o700);
  const target = join(backupDir, `ironforge-${now.toISOString().slice(0, 10)}.db`);
  const temporary = join(backupDir, `.backup-${randomUUID()}.tmp`);
  const db = new Database(join(dataDir, 'ironforge.db'), { readonly: true, fileMustExist: true });
  try {
    // better-sqlite3 backup is asynchronous: closing first loses the backup.
    await db.backup(temporary);
    await chmod(temporary, 0o600);
    const restored = new Database(temporary, { readonly: true, fileMustExist: true });
    try {
      if (restored.pragma('quick_check', { simple: true }) !== 'ok') {
        throw new Error('backup integrity check failed');
      }
    } finally {
      restored.close();
    }
    // Never replace a good backup until the new snapshot has completed/validated.
    await rename(temporary, target);
  } finally {
    db.close();
    await unlink(temporary).catch((error) => { if (error.code !== 'ENOENT') throw error; });
  }

  // Retention only runs after success, in the very directory we backed up into.
  const cutoff = now.getTime() - retentionDays * 24 * 60 * 60 * 1000;
  for (const entry of await readdir(backupDir, { withFileTypes: true })) {
    if (!entry.isFile() || !/^ironforge-\d{4}-\d{2}-\d{2}\.db$/.test(entry.name)) continue;
    const path = join(backupDir, entry.name);
    if (path !== target && (await stat(path)).mtimeMs < cutoff) await unlink(path);
  }
  return target;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  backupDatabase({ dataDir: process.env.DATA_DIR || '/data' })
    .then((target) => console.log(`Backup verified: ${target}`))
    .catch((error) => { console.error(`Backup failed: ${error.message}`); process.exitCode = 1; });
}
