import Fastify from 'fastify';
import cookie from '@fastify/cookie';
import fastifyStatic from '@fastify/static';
import { readFileSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import routes from './routes.js';
import { bootstrapUser } from './auth.js';

const __dirname = dirname(fileURLToPath(import.meta.url));
const WEB_DIR = join(__dirname, '..', 'web');
const DOWNLOADS_DIR = join(__dirname, '..', 'downloads');
const MEDIA_DIR = join(__dirname, '..', 'media');
process.env.DOWNLOADS_DIR = DOWNLOADS_DIR;

async function bootstrap() {
  // Production: credentials injected via .env (BOOTSTRAP_USERNAME / BOOTSTRAP_PASSWORD).
  // Dev: optional bootstrap.json inside the data dir (gitignored, chmod 600).
  const envUser = process.env.BOOTSTRAP_USERNAME;
  const envPass = process.env.BOOTSTRAP_PASSWORD;
  if (envUser && envPass) {
    if (envPass.length < 10) {
      throw new Error('BOOTSTRAP_PASSWORD must be at least 10 characters');
    }
    await bootstrapUser(envUser, envPass);
    console.log(`[ironforge] bootstrap user '${envUser}' ensured (env)`);
    return;
  }
  const dataDir = process.env.DATA_DIR || join(__dirname, '..', 'data');
  const file = process.env.BOOTSTRAP_FILE || join(dataDir, 'bootstrap.json');
  if (existsSync(file)) {
    const { username, password } = JSON.parse(readFileSync(file, 'utf8'));
    if (typeof username !== 'string' || typeof password !== 'string' || password.length < 10) {
      throw new Error('bootstrap.json must contain username + password (>= 10 chars)');
    }
    await bootstrapUser(username, password);
    console.log(`[ironforge] bootstrap user '${username}' ensured (file)`);
    return;
  }
  console.warn('[ironforge] no bootstrap credentials found — login will fail until a user exists');
}

async function main() {
  await bootstrap();

  const app = Fastify({
    logger: { level: 'warn' },
    trustProxy: false,
    bodyLimit: 64 * 1024,
  });

  await app.register(cookie);

  app.addHook('onSend', async (req, reply) => {
    reply.header('Content-Security-Policy',
      "default-src 'self'; " +
      "script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com; " +
      "style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; " +
      "img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com data:; " +
      "frame-src https://www.youtube-nocookie.com https://www.youtube.com; " +
      "connect-src 'self' https://www.gstatic.com https://fonts.gstatic.com; " +
      "worker-src 'self' blob:; media-src 'self'; " +
      "object-src 'none'; base-uri 'self'; frame-ancestors 'none'");
    reply.header('X-Content-Type-Options', 'nosniff');
    reply.header('X-Frame-Options', 'DENY');
    reply.header('Referrer-Policy', 'no-referrer');
    reply.header('Permissions-Policy', 'camera=(), microphone=(), geolocation=()');
    reply.header('Cross-Origin-Opener-Policy', 'same-origin');
  });

  app.get('/api/health', async () => ({ ok: true }));

  await app.register(routes);

  if (existsSync(WEB_DIR)) {
    await app.register(fastifyStatic, {
      root: resolve(WEB_DIR),
      prefix: '/',
      index: ['index.html'],
      cacheControl: true,
      maxAge: '1h',
    });
  }
  if (existsSync(MEDIA_DIR)) {
    await app.register(fastifyStatic, {
      root: resolve(MEDIA_DIR),
      prefix: '/media/',
      decorateReply: false,
      cacheControl: true,
      maxAge: '7d',
    });
  }

  app.setNotFoundHandler((req, reply) => {
    if (req.method === 'GET' && !req.url.startsWith('/api/') && existsSync(join(WEB_DIR, 'index.html'))) {
      return reply.type('text/html').send(readFileSync(join(WEB_DIR, 'index.html')));
    }
    reply.code(404).send({ error: 'not found' });
  });

  const port = Number(process.env.PORT || 8420);
  const host = process.env.BIND || '127.0.0.1';
  await app.listen({ port, host });
  console.log(`[ironforge] listening on ${host}:${port}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
