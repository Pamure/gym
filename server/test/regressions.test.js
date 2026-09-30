import { after, beforeEach, test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { execFileSync } from 'node:child_process';
import Fastify from 'fastify';
import cookie from '@fastify/cookie';

// Never load server/.env, bootstrap data, a real database or a provider key.
process.env.LOAD_LOCAL_ENV = '0';
process.env.OPENROUTER_API_KEY = '';
process.env.DATA_DIR = mkdtempSync(fileURLToPath(new URL('./.regression-', import.meta.url)));
const { default: db } = await import('../src/db.js');
const { default: routes } = await import('../src/routes.js');
const { createSession, COOKIE_NAME } = await import('../src/auth.js');
const { buildContext, selectModels } = await import('../src/ai.js');
const app = Fastify({ logger: false });
await app.register(cookie);
await app.register(routes);
await app.ready();
let user, other, cookies;

after(async () => {
  await app.close();
  db.close();
  rmSync(process.env.DATA_DIR, { recursive: true, force: true });
});
beforeEach(() => {
  db.prepare('DELETE FROM users').run();
  user = Number(db.prepare('INSERT INTO users(username, password_hash) VALUES (?, ?)').run('fixture', 'unused').lastInsertRowid);
  other = Number(db.prepare('INSERT INTO users(username, password_hash) VALUES (?, ?)').run('other', 'unused').lastInsertRowid);
  cookies = { [COOKIE_NAME]: createSession(user) };
});
const request = (method, url, payload, extra = {}) => app.inject({ method, url, payload, cookies, ...extra });
const post = (url, payload, extra) => request('POST', url, payload, extra);
const state = async () => (await request('GET', '/api/state')).json();
const workout = (count = 3) => ({ date: '2026-09-30', week: 2, day: 'Wednesday', exercise: 'Leg Press',
  sets: Array.from({ length: count }, (_, i) => ({ setNumber: i + 1, weightKg: 40, reps: 10 })) });
const kegel = (extra = {}) => ({ date: '2026-09-30', sets: 2, holdSeconds: 3, ...extra });

test('coach selects verified free variants and never enables paid online search', () => {
  const preferred = 'nvidia/nemotron-3-super-120b-a12b:free';
  const fallback = 'nvidia/nemotron-3-ultra-550b-a55b:free';
  assert.deepEqual(selectModels({ OPENROUTER_MODEL: 'minimax/minimax-m3:free', AI_SEARCH: '1' }),
    [preferred, fallback], 'retired remote override must not break new deployments');
  assert.deepEqual(selectModels({ OPENROUTER_MODEL: 'openai/gpt-4o', AI_SEARCH: '1' }),
    [preferred, fallback], 'paid model IDs must never be sent to the provider');
  assert.deepEqual(selectModels({ OPENROUTER_MODEL: fallback, AI_SEARCH: '1' }),
    [fallback], 'the fallback is not sent twice');
  assert.ok(selectModels({ OPENROUTER_MODEL: 'qwen/qwen3.8-27b:free' })
    .every((model) => model.endsWith(':free')));
});

test('coach context honors the saved plan dates and Delhi local date', () => {
  db.prepare('INSERT INTO settings(user_id, key, value) VALUES (?, ?, ?)').run(user, 'program_start_date', '2026-10-05');
  const ctx = buildContext(user, new Date('2026-10-06T23:30:00Z')); // Wed 05:00 Delhi
  assert.equal(ctx.snapshot_date, '2026-10-07');
  assert.equal(ctx.program_start_date, '2026-10-05');
  assert.equal(ctx.program_end_date, '2026-12-27');
  assert.equal(ctx.week_of_program, 1);
  assert.match(ctx.attendance_3_weeks, /2026-10-05 Mon: required strength missed/);
  assert.match(ctx.attendance_3_weeks, /2026-10-06 Tue: optional movement not logged/);
  assert.doesNotMatch(ctx.attendance_3_weeks, /2026-09-/);
  assert.doesNotMatch(ctx.attendance_3_weeks, /2026-10-07/);
  const before = buildContext(user, new Date('2026-10-03T00:00:00Z'));
  assert.equal(before.week_of_program, null);
  assert.equal(before.attendance_3_weeks, '');
});

test('workout save atomically replaces omitted sets and preserves other entries/users', async () => {
  assert.equal((await post('/api/logs/workout', workout())).statusCode, 200);
  await post('/api/logs/workout', { ...workout(), exercise: 'Bench Press' });
  await post('/api/logs/workout', workout(), { cookies: { [COOKIE_NAME]: createSession(other) } });
  const changed = workout(2);
  changed.sets[0].weightKg = 45;
  assert.deepEqual((await post('/api/logs/workout', changed)).json(), { ok: true, saved: 2 });
  const saved = await state();
  assert.deepEqual(saved.workouts.find((w) => w.exercise === 'Leg Press').sets, changed.sets);
  assert.equal(saved.workouts.find((w) => w.exercise === 'Bench Press').sets.length, 3);
  assert.equal(db.prepare('SELECT count(*) AS n FROM workout_logs WHERE user_id = ?').get(other).n, 3);

  db.exec("CREATE TEMP TRIGGER fail_set BEFORE INSERT ON workout_logs WHEN NEW.reps = 99 BEGIN SELECT RAISE(ABORT, 'fixture failure'); END");
  try {
    const failing = workout(3);
    failing.sets[1].reps = 99;
    assert.equal((await post('/api/logs/workout', failing)).statusCode, 500);
    assert.deepEqual(await state(), saved, 'failed replacement must roll back both deletion and partial inserts');
  } finally {
    db.exec('DROP TRIGGER fail_set');
  }
});

test('invalid sets cannot mutate an existing workout', async () => {
  await post('/api/logs/workout', workout());
  const saved = await state();
  for (const sets of [[], [{ setNumber: 1, weightKg: 40, reps: 0 }],
    [{ setNumber: 1, weightKg: 40, reps: 1.5 }], [workout().sets[0], workout().sets[0]]]) {
    assert.equal((await post('/api/logs/workout', { ...workout(), sets })).statusCode, 400);
    assert.deepEqual(await state(), saved);
  }
});

test('kegel POST returns distinct real ids for legitimate same-day sessions', async () => {
  const first = (await post('/api/logs/kegels', kegel())).json();
  const second = (await post('/api/logs/kegels', kegel())).json();
  assert.ok(Number.isInteger(first.id) && first.id > 0);
  assert.notEqual(first.id, second.id);
  assert.deepEqual((await request('DELETE', '/api/logs/kegels', { id: first.id })).json(), { ok: true, deleted: 1 });
  assert.deepEqual((await state()).kegels.map((k) => k.id), [second.id]);
});

test('kegel idempotency persists, is user-scoped, and survives edits/deletion safely', async () => {
  const body = kegel({ clientId: 'session-123' });
  const responses = await Promise.all([post('/api/logs/kegels', body), post('/api/logs/kegels', body)]);
  assert.ok(responses.every((r) => r.statusCode === 200));
  const id = responses[0].json().id;
  assert.equal(responses[1].json().id, id);
  assert.equal((await state()).kegels.length, 1);
  assert.equal((await state()).kegels[0].clientId, body.clientId);
  assert.equal(db.prepare('SELECT kegel_id FROM kegel_requests WHERE user_id = ? AND client_id = ?').get(user, body.clientId).kegel_id, id);
  const conflict = await post('/api/logs/kegels', { ...body, sets: 3 });
  assert.equal(conflict.statusCode, 409);
  await request('PUT', '/api/logs/kegels', { id, sets: 4, holdSeconds: 5 });
  assert.equal((await post('/api/logs/kegels', body)).json().id, id);
  assert.equal((await state()).kegels[0].sets, 4, 'replay must not revert a subsequent edit');
  const otherCookies = { [COOKIE_NAME]: createSession(other) };
  const otherResponse = await post('/api/logs/kegels', body, { cookies: otherCookies });
  assert.equal(otherResponse.statusCode, 200);
  assert.notEqual(otherResponse.json().id, id);
  assert.equal((await request('PUT', '/api/logs/kegels', { id, sets: 3, holdSeconds: 3 }, { cookies: otherCookies })).statusCode, 404);
  await request('DELETE', '/api/logs/kegels', { id });
  assert.equal((await post('/api/logs/kegels', body)).statusCode, 409, 'deleted command must not resurrect a row');
  assert.equal((await state()).kegels.length, 0);
});

test('kegel replay after a fresh server-process import returns the persisted id', async () => {
  const body = kegel({ clientId: 'survives-restart' });
  const created = (await post('/api/logs/kegels', body)).json();
  const result = execFileSync(process.execPath, ['--input-type=module', '-e', `
    import Fastify from 'fastify';
    import cookie from '@fastify/cookie';
    import routes from './src/routes.js';
    import db from './src/db.js';
    const app = Fastify({ logger: false });
    await app.register(cookie);
    await app.register(routes);
    const response = await app.inject(${JSON.stringify({ method: 'POST', url: '/api/logs/kegels', payload: body, cookies })});
    console.log(JSON.stringify({ status: response.statusCode, body: response.json() }));
    await app.close();
    db.close();
  `], {
    cwd: fileURLToPath(new URL('..', import.meta.url)),
    env: { LOAD_LOCAL_ENV: '0', DATA_DIR: process.env.DATA_DIR, OPENROUTER_API_KEY: '' },
    encoding: 'utf8',
  });
  const restarted = JSON.parse(result);
  assert.equal(restarted.status, 200);
  assert.equal(restarted.body.id, created.id);
  assert.equal((await state()).kegels.length, 1);
});

test('kegel supports header/body idempotency keys and rejects invalid or conflicting keys', async () => {
  const first = await post('/api/logs/kegels', kegel(), { headers: { 'idempotency-key': 'header-key' } });
  const replay = await post('/api/logs/kegels', kegel({ idempotencyKey: 'header-key' }));
  assert.equal(first.json().id, replay.json().id);
  for (const key of ['', 'has spaces', 'x'.repeat(129)]) {
    assert.equal((await post('/api/logs/kegels', kegel({ clientId: key }))).statusCode, 400);
    assert.equal((await post('/api/logs/kegels', kegel(), { headers: { 'idempotency-key': key } })).statusCode, 400);
  }
  assert.equal((await post('/api/logs/kegels', kegel({ clientId: 'a', idempotencyKey: 'b' }))).statusCode, 400);
  assert.equal((await post('/api/logs/kegels', kegel({ clientId: 'a' }), { headers: { 'idempotency-key': 'b' } })).statusCode, 400);
  assert.equal((await state()).kegels.length, 1);
});

test('full state returns complete check-in and kegel histories beyond old caps', async () => {
  const checkin = db.prepare('INSERT INTO checkins(user_id,date) VALUES (?,?)');
  const insertKegel = db.prepare('INSERT INTO kegel_logs(user_id,date,sets,hold_seconds) VALUES (?,?,1,3)');
  db.transaction(() => {
    for (let i = 0; i < 100; i++) {
      const date = new Date(Date.UTC(2026, 0, 1 + i)).toISOString().slice(0, 10);
      checkin.run(user, date);
      insertKegel.run(user, date);
    }
    checkin.run(other, '2026-01-01');
    insertKegel.run(other, '2026-01-01');
  })();
  const result = await state();
  assert.equal(result.checkins.length, 100);
  assert.equal(result.kegels.length, 100);
  assert.equal(result.checkins.at(-1).date, '2026-01-01');
  assert.equal(result.kegels.at(-1).date, '2026-01-01');
});

test('all dated mutations and program settings reject impossible calendar dates', async () => {
  const endpoints = [
    ['/api/logs/workout', workout()], ['/api/logs/weight', { kg: 70 }],
    ['/api/logs/measurements', { waistCm: 80 }], ['/api/logs/kegels', kegel()], ['/api/checkins', { energy: 3 }],
  ];
  for (const date of ['2026-02-30', '2025-02-29', '1900-02-29', '2026-13-01', '2026-00-10', '0000-01-01', '2026-04-31']) {
    for (const [url, body] of endpoints) {
      assert.equal((await post(url, { ...body, date })).statusCode, 400, `${url}: ${date}`);
      assert.equal((await request('DELETE', url, { date })).statusCode, 400);
    }
    assert.equal((await post('/api/settings', { key: 'program_start_date', value: date })).statusCode, 400);
  }
  for (const date of ['2024-02-29', '2000-02-29', '2026-09-30']) {
    for (const [url, body] of endpoints) assert.equal((await post(url, { ...body, date })).statusCode, 200, `${url}: ${date}`);
    assert.equal((await post('/api/settings', { key: 'program_start_date', value: date })).statusCode, 200);
  }
});

test('reminder flags, time values, and unknown fields are strictly validated', async () => {
  for (const value of ['banana', 'true', 'false', '', '2']) {
    assert.equal((await post('/api/settings', { key: 'reminder_enabled', value })).statusCode, 400);
  }
  for (const value of ['0', '1']) assert.equal((await post('/api/settings', { key: 'reminder_enabled', value })).statusCode, 200);
  for (const key of ['wake_time', 'gym_time', 'reminder_time']) {
    assert.equal((await post('/api/settings', { key, value: '24:00' })).statusCode, 400);
    assert.equal((await post('/api/settings', { key, value: '23:59' })).statusCode, 200);
  }
  assert.equal((await post('/api/logs/weight', { date: '2026-09-30', kg: 70, unexpected: true })).statusCode, 400);
  const invalid = workout();
  invalid.sets[0].unexpected = true;
  assert.equal((await post('/api/logs/workout', invalid)).statusCode, 400);
  assert.equal((await state()).bodyWeight.length, 0);
});

test('data mutations and snapshots still require authentication', async () => {
  assert.equal((await request('GET', '/api/state', undefined, { cookies: {} })).statusCode, 401);
  assert.equal((await post('/api/logs/kegels', kegel({ clientId: 'private' }), { cookies: {} })).statusCode, 401);
  assert.equal((await post('/api/logs/workout', workout(), { cookies: {} })).statusCode, 401);
});
