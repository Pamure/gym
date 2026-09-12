import Ajv from 'ajv';
import db from './db.js';
import { askCoach, recentChat, clearChat, CoachError } from './ai.js';
import {
  verifyLogin, createSession, getSession, destroySession, destroyAllSessions,
  changePassword,
  COOKIE_NAME, COOKIE_OPTS,
} from './auth.js';

const ajv = new Ajv({ allErrors: true, removeAdditional: true });

const s = {
  login: ajv.compile({
    type: 'object', required: ['username', 'password'], additionalProperties: false,
    properties: {
      username: { type: 'string', minLength: 1, maxLength: 32 },
      password: { type: 'string', minLength: 1, maxLength: 128 },
    },
  }),
  workout: ajv.compile({
    type: 'object', required: ['date', 'exercise', 'sets'], additionalProperties: false,
    properties: {
      date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
      week: { type: 'integer', minimum: 1, maximum: 12 },
      day: { type: 'string', maxLength: 16 },
      exercise: { type: 'string', minLength: 1, maxLength: 64 },
      sets: {
        type: 'array', minItems: 1, maxItems: 12,
        items: {
          type: 'object', required: ['setNumber', 'weightKg', 'reps'], additionalProperties: false,
          properties: {
            setNumber: { type: 'integer', minimum: 1, maximum: 12 },
            weightKg: { type: 'number', minimum: 0, maximum: 500 },
            reps: { type: 'integer', minimum: 0, maximum: 200 },
          },
        },
      },
      notes: { type: 'string', maxLength: 500 },
    },
  }),
  weight: ajv.compile({
    type: 'object', required: ['date', 'kg'], additionalProperties: false,
    properties: {
      date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
      kg: { type: 'number', minimum: 20, maximum: 400 },
    },
  }),
  measurements: ajv.compile({
    type: 'object', required: ['date'], additionalProperties: false,
    properties: {
      date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
      waistCm: { type: 'number', minimum: 30, maximum: 300 },
      chestCm: { type: 'number', minimum: 30, maximum: 300 },
      armCm: { type: 'number', minimum: 10, maximum: 100 },
    },
  }),
  kegels: ajv.compile({
    type: 'object', required: ['date', 'sets', 'holdSeconds'], additionalProperties: false,
    properties: {
      date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
      sets: { type: 'integer', minimum: 1, maximum: 20 },
      holdSeconds: { type: 'integer', minimum: 1, maximum: 60 },
    },
  }),
  settings: ajv.compile({
    type: 'object', required: ['key', 'value'], additionalProperties: false,
    properties: {
      key: { type: 'string', enum: ['program_start_date', 'units', 'reminder_time', 'reminder_enabled', 'gym_time', 'wake_time'] },
      value: { type: 'string', maxLength: 64 },
    },
  }),
  password: ajv.compile({
    type: 'object', required: ['currentPassword', 'newPassword'], additionalProperties: false,
    properties: {
      currentPassword: { type: 'string', minLength: 1, maxLength: 128 },
      newPassword: { type: 'string', minLength: 10, maxLength: 128 },
    },
  }),
  deleteWorkout: ajv.compile({
    type: 'object', required: ['date'], additionalProperties: false,
    properties: {
      date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
      exercise: { type: 'string', minLength: 1, maxLength: 64 },
    },
  }),
  deleteDate: ajv.compile({
    type: 'object', required: ['date'], additionalProperties: false,
    properties: { date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' } },
  }),
  deleteId: ajv.compile({
    type: 'object', required: ['id'], additionalProperties: false,
    properties: { id: { type: 'integer', minimum: 1 } },
  }),
  kegelEdit: ajv.compile({
    type: 'object', required: ['id', 'sets', 'holdSeconds'], additionalProperties: false,
    properties: {
      id: { type: 'integer', minimum: 1 },
      sets: { type: 'integer', minimum: 1, maximum: 20 },
      holdSeconds: { type: 'integer', minimum: 1, maximum: 60 },
    },
  }),
  checkin: ajv.compile({
    type: 'object', required: ['date'], additionalProperties: false,
    properties: {
      date: { type: 'string', pattern: '^\\d{4}-\\d{2}-\\d{2}$' },
      energy: { type: 'integer', minimum: 1, maximum: 5 },
      sleepHours: { type: 'number', minimum: 0, maximum: 16 },
      waterL: { type: 'number', minimum: 0, maximum: 10 },
      mood: { type: 'string', maxLength: 200 },
      notes: { type: 'string', maxLength: 500 },
    },
  }),
};

function requireAuth(req, reply) {
  const session = getSession(req.cookies[COOKIE_NAME]);
  if (!session) {
    reply.code(401).send({ error: 'unauthenticated' });
    return null;
  }
  return session;
}

const aiHits = {};

export default function routes(app) {
  app.post('/api/auth/login', async (req, reply) => {
    if (!s.login(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const { username, password } = req.body;
    const result = await verifyLogin(req.ip, username, password);
    if (result.locked) {
      return reply.code(429).send({ error: 'too many attempts, try later', retryAfterSec: result.retryAfterSec });
    }
    if (!result.ok) {
      return reply.code(401).send({ error: 'invalid credentials' });
    }
    const sid = createSession(result.user.id);
    reply.setCookie(COOKIE_NAME, sid, COOKIE_OPTS);
    return { ok: true, username: result.user.username };
  });

  app.post('/api/auth/logout', async (req, reply) => {
    const sid = req.cookies[COOKIE_NAME];
    if (sid) destroySession(sid);
    reply.clearCookie(COOKIE_NAME, { path: '/' });
    return { ok: true };
  });

  app.get('/api/me', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    const rows = db.prepare(
      `SELECT key, value FROM settings WHERE user_id = ?`
    ).all(session.user_id);
    const settings = Object.fromEntries(rows.map((r) => [r.key, r.value]));
    return {
      username: session.username,
      programStartDate: settings.program_start_date || null,
      units: settings.units || 'kg',
      settings,
    };
  });

  app.post('/api/auth/password', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.password(req.body)) {
      return reply.code(400).send({ error: 'new password must be 10-128 characters' });
    }
    const u = db.prepare('SELECT * FROM users WHERE id = ?').get(session.user_id);
    const check = await verifyLogin(req.ip, u.username, req.body.currentPassword);
    if (!check.ok) return reply.code(401).send({ error: 'invalid credentials' });
    await changePassword(session.user_id, req.body.newPassword);
    destroyAllSessions(session.user_id);
    const sid = createSession(session.user_id);
    reply.setCookie(COOKIE_NAME, sid, COOKIE_OPTS);
    return { ok: true };
  });

  // ---------- data routes (all auth-gated) ----------

  app.post('/api/logs/workout', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.workout(req.body)) return reply.code(400).send({ error: 'invalid request', details: s.workout.errors });
    const { date, week, day, exercise, sets, notes } = req.body;
    const stmt = db.prepare(
      `INSERT INTO workout_logs (user_id, date, week, day, exercise, set_number, weight_kg, reps, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(user_id, date, exercise, set_number)
       DO UPDATE SET weight_kg = excluded.weight_kg, reps = excluded.reps, week = excluded.week,
                     day = excluded.day, notes = excluded.notes`);
    const tx = db.transaction(() => {
      for (const set of sets) {
        stmt.run(session.user_id, date, week ?? null, day ?? null, exercise,
          set.setNumber, set.weightKg, set.reps, notes ?? null);
      }
    });
    tx();
    return { ok: true, saved: sets.length };
  });

  app.post('/api/logs/weight', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.weight(req.body)) return reply.code(400).send({ error: 'invalid request' });
    db.prepare(
      `INSERT INTO body_weight (user_id, date, kg) VALUES (?, ?, ?)
       ON CONFLICT(user_id, date) DO UPDATE SET kg = excluded.kg`
    ).run(session.user_id, req.body.date, req.body.kg);
    return { ok: true };
  });

  app.post('/api/logs/measurements', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.measurements(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const { date, waistCm, chestCm, armCm } = req.body;
    db.prepare(
      `INSERT INTO measurements (user_id, date, waist_cm, chest_cm, arm_cm) VALUES (?, ?, ?, ?, ?)
       ON CONFLICT(user_id, date) DO UPDATE SET waist_cm = excluded.waist_cm,
         chest_cm = excluded.chest_cm, arm_cm = excluded.arm_cm`
    ).run(session.user_id, date, waistCm ?? null, chestCm ?? null, armCm ?? null);
    return { ok: true };
  });

  app.post('/api/logs/kegels', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.kegels(req.body)) return reply.code(400).send({ error: 'invalid request' });
    db.prepare(
      'INSERT INTO kegel_logs (user_id, date, sets, hold_seconds) VALUES (?, ?, ?, ?)'
    ).run(session.user_id, req.body.date, req.body.sets, req.body.holdSeconds);
    return { ok: true };
  });

  app.get('/api/state', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    const uid = session.user_id;
    // Group per-set rows into workout entries with a sets[] array (client contract).
    const rows = db.prepare(
      'SELECT date, week, day, exercise, set_number AS setNumber, weight_kg AS weightKg, reps, notes ' +
      'FROM workout_logs WHERE user_id = ? ORDER BY date DESC, exercise, set_number'
    ).all(uid);
    const byKey = new Map();
    for (const r of rows) {
      const key = `${r.date}|${r.exercise}`;
      let entry = byKey.get(key);
      if (!entry) {
        entry = { date: r.date, week: r.week, day: r.day, exercise: r.exercise, notes: r.notes ?? null, sets: [] };
        byKey.set(key, entry);
      }
      entry.sets.push({ setNumber: r.setNumber, weightKg: r.weightKg, reps: r.reps });
    }
    const workouts = [...byKey.values()].map((e) => ({
      ...e,
      sets: e.sets.sort((a, b) => a.setNumber - b.setNumber),
    }));
    return {
      workouts,
      bodyWeight: db.prepare('SELECT date, kg FROM body_weight WHERE user_id = ? ORDER BY date').all(uid),
      measurements: db.prepare(
        'SELECT date, waist_cm AS waistCm, chest_cm AS chestCm, arm_cm AS armCm FROM measurements WHERE user_id = ? ORDER BY date'
      ).all(uid),
      kegels: db.prepare(
        'SELECT id, date, sets, hold_seconds AS holdSeconds, created_at AS createdAt FROM kegel_logs WHERE user_id = ? ORDER BY date DESC, id DESC LIMIT 90'
      ).all(uid),
      checkins: db.prepare(
        'SELECT date, energy, sleep_hours AS sleepHours, water_l AS waterL, mood, notes FROM checkins WHERE user_id = ? ORDER BY date DESC LIMIT 60'
      ).all(uid),
    };
  });

  app.post('/api/settings', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.settings(req.body)) return reply.code(400).send({ error: 'invalid request' });
    db.prepare(
      `INSERT INTO settings (user_id, key, value) VALUES (?, ?, ?)
       ON CONFLICT(user_id, key) DO UPDATE SET value = excluded.value`
    ).run(session.user_id, req.body.key, req.body.value);
    return { ok: true };
  });

  app.get('/api/download/apk', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    return reply.sendFile('ironforge.apk', process.env.DOWNLOADS_DIR || undefined);
  });


  // ---------- AI coach ----------
  app.get('/api/ai/chat', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    return { messages: recentChat(session.user_id) };
  });

  app.post('/api/ai/chat', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    const msg = req.body?.message;
    if (typeof msg !== 'string' || msg.trim().length === 0 || msg.length > 800) {
      return reply.code(400).send({ error: 'message must be 1-800 chars' });
    }
    const dayPlan = typeof req.body?.dayPlan === 'string' ? req.body.dayPlan.slice(0, 500) : '';
    // per-user rate limit: 8 asks / minute (in-memory; resets on restart)
    const now = Date.now();
    const arr = (aiHits[session.user_id] = (aiHits[session.user_id] || []).filter((t) => now - t < 60000));
    if (arr.length >= 8) return reply.code(429).send({ error: 'slow down — max 8 questions per minute' });
    arr.push(now);
    try {
      const r = await askCoach(session.user_id, msg.trim(), { dayPlan: dayPlan });
      return { ok: true, reply: r.reply, model: r.model };
    } catch (e) {
      if (e instanceof CoachError) return reply.code(e.status).send({ error: e.message });
      return reply.code(502).send({ error: 'coach unavailable: ' + e.message });
    }
  });

  app.delete('/api/ai/chat', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    clearChat(session.user_id);
    return { ok: true };
  });

  // ---------- edit / delete (fix mistakes) ----------

  app.delete('/api/logs/workout', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.deleteWorkout(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const { date, exercise } = req.body;
    const r = exercise
      ? db.prepare('DELETE FROM workout_logs WHERE user_id = ? AND date = ? AND exercise = ?')
          .run(session.user_id, date, exercise)
      : db.prepare('DELETE FROM workout_logs WHERE user_id = ? AND date = ?')
          .run(session.user_id, date);
    return { ok: true, deleted: r.changes };
  });

  app.delete('/api/logs/weight', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.deleteDate(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const r = db.prepare('DELETE FROM body_weight WHERE user_id = ? AND date = ?')
      .run(session.user_id, req.body.date);
    return { ok: true, deleted: r.changes };
  });

  app.delete('/api/logs/measurements', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.deleteDate(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const r = db.prepare('DELETE FROM measurements WHERE user_id = ? AND date = ?')
      .run(session.user_id, req.body.date);
    return { ok: true, deleted: r.changes };
  });

  app.delete('/api/logs/kegels', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.deleteId(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const r = db.prepare('DELETE FROM kegel_logs WHERE id = ? AND user_id = ?')
      .run(req.body.id, session.user_id);
    return { ok: true, deleted: r.changes };
  });

  app.put('/api/logs/kegels', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.kegelEdit(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const { id, sets, holdSeconds } = req.body;
    const r = db.prepare('UPDATE kegel_logs SET sets = ?, hold_seconds = ? WHERE id = ? AND user_id = ?')
      .run(sets, holdSeconds, id, session.user_id);
    if (r.changes === 0) return reply.code(404).send({ error: 'not found' });
    return { ok: true };
  });

  // ---------- daily check-ins (discipline data) ----------

  app.post('/api/checkins', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.checkin(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const { date, energy, sleepHours, waterL, mood, notes } = req.body;
    db.prepare(
      `INSERT INTO checkins (user_id, date, energy, sleep_hours, water_l, mood, notes)
       VALUES (?, ?, ?, ?, ?, ?, ?)
       ON CONFLICT(user_id, date) DO UPDATE SET
         energy = excluded.energy, sleep_hours = excluded.sleep_hours,
         water_l = excluded.water_l, mood = excluded.mood, notes = excluded.notes`
    ).run(session.user_id, date, energy ?? null, sleepHours ?? null, waterL ?? null, mood ?? null, notes ?? null);
    return { ok: true };
  });

  app.delete('/api/checkins', async (req, reply) => {
    const session = requireAuth(req, reply);
    if (!session) return;
    if (!s.deleteDate(req.body)) return reply.code(400).send({ error: 'invalid request' });
    const r = db.prepare('DELETE FROM checkins WHERE user_id = ? AND date = ?')
      .run(session.user_id, req.body.date);
    return { ok: true, deleted: r.changes };
  });

}
