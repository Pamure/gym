// Load local server secrets without adding them to the Flutter bundle or Git.
// Production Docker/deploy environments can continue injecting process.env.
import { existsSync, readFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const envFile = join(here, '..', '.env');

// Isolated tests/tools must opt out before importing any database/auth modules.
if (process.env.LOAD_LOCAL_ENV !== '0' && existsSync(envFile)) {
  for (const rawLine of readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    const line = rawLine.trim();
    if (!line || line.startsWith('#')) continue;
    const equals = line.indexOf('=');
    if (equals <= 0) continue;

    const key = line.slice(0, equals).trim();
    let value = line.slice(equals + 1).trim();
    if (
      value.length >= 2 &&
      ((value.startsWith('"') && value.endsWith('"')) ||
        (value.startsWith("'") && value.endsWith("'")))
    ) {
      value = value.slice(1, -1);
    }
    // Explicit shell/Docker environment variables always win over .env.
    if (!(key in process.env)) process.env[key] = value;
  }
}
