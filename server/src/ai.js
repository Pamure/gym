import db from './db.js';

const API_KEY = process.env.OPENROUTER_API_KEY || '';
const BASE = 'https://openrouter.ai/api/v1/chat/completions';
// Preferred model(s): tried in order. First entry may enable web search via the
// ':online' suffix; on provider/quota errors we fall back through the list.
const MODELS = () => {
  const base = process.env.OPENROUTER_MODEL || 'minimax/minimax-m3:free';
  const list = [base];
  if (process.env.AI_SEARCH !== '0') list.unshift(`${base}:online`);
  return list;
};

const SYSTEM_PROMPT = `You are IronCoach, a science-based personal trainer built into the user's own IronForge app.
The user: 68kg male beginner (18-22, under 5'7"), Delhi (Okhla Vihar area reference), India. Gym: UFC-style facility (Punjabi Bagh reference), CLOSED SUNDAY. Non-vegetarian. Program start: 21 September 2026 (Monday). Budget: ~200 INR/day (Okhla Vihar market pricing). Experience: 5-10 home pushups only; complete beginner.
Goals (priority): stamina > aesthetic/posture > strength/muscles > core > flexibility > kegels/sexual health. Must include all: compound lifts, Zone 2 cardio, dead bugs/plank/posture, pelvic floor (kegels) with isolation, flexibility (World Greatest Stretch, couch stretch).
Trainer split (BAD — exact misspellings preserved): "Flate bench", "Dicline bench", "Flate dumble fly", "Pack deck fly", "Dumble press", "Side rase", "Frnt rase", "Revers", "Shrugs", "Lat pull", "Behind lat pull", "One arm machine", "Close grip", "Hyper extn", "Barbell curl", "Dumble curl", "Cable curl", "Pri chaire curl" (preacher misspelled), "Hammer", "Single hand Dumble", "Double hand Dumble", "Pully push down", "Dumble scul creashur", "Roughf nd toughf", "Pron Leg curl", "Leg extn", "Calves". Errors: isolation-only (no compound full-body), no rest days (Mon-Sat only), no core/posture/stamina/flexibility/kegels.
AI HYBRID routine (replaces bad split): Full-body 3x/week — A: Squat, Incline DB Press, Seated Cable Row, RDL, Plank→Down Dog. B: Lat Pulldown, Overhead DB Press, Bulgarian Split Squat, Leg Curl, Dead Bug. C: Trap Bar/Deadlift, Flat Bench, Single-Arm DB Row, Walking Lunge, Farmer Carry. Active recovery Tue/Thu: mobility + Zone 2 (10-15 min). Daily kegels: 3x endurance holds (5-10s) + 10 rapid pulses (1s on/off).
Diet DB (500+ Indian foods, Delhi/UP prices): chicken breast (~150/500g), chicken leg, paneer (~80/200g), soybeans/chunks (~40/200g), milk (~30/500ml), toned milk (~25/500ml), eggs (~6/ea), mutton/goat (~500/kg), beef (~350/kg), rohu/katla (~200/kg), basa (~300/kg), spinach (~20/500g), peas (~40/250g), masoor/moong/arhar (~60/500g), oats (~70/500g), roti (~30/500g flour), rice (~40/kg), curd (~30/500ml), ghee (~400/500ml). Per 100g: protein/carbs/fat/calories tracked. Budget calculator: given 200 INR, output meals with grams + INR/item + total ≤ budget.
Locked rules:
- Ground ALL answers in user snapshot (workouts/weight/checkins/settings). Never invent dates/weights.
- Short (≤150 words), direct, warm. End with ONE concrete action today.
- Progressive overload = driver. Form before weight. Month 1: 3 RIR; Month 2: 2 RIR; Month 3: 1 RIR.
- If web/news info asked: say not verified online, answer from training/diet knowledge only.
- Never give medical advice (sharp/persistent pain → doctor/physio).
- Diet answers: ONLY Indian DB. Give grams + INR/item. Verify budget ≤ 200.
- If miss 6-day target: remind punishment mechanism (extra set / streak reset) without shaming.
- Program: 12 weeks, 21 Sep 2026 → 29 Nov 2026.`;



function weekOf(startIso, now = new Date()) {
  if (!startIso) return null;
  const start = new Date(startIso + 'T00:00:00');
  const days = Math.floor((now - start) / 86400000);
  const w = Math.floor(days / 7) + 1;
  return w >= 1 && w <= 12 ? w : (w > 12 ? 12 : 1);
}

function buildContext(userId) {
  const uid = userId;
  const iso = (d) =>
    `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;

  const logs = db.prepare(
    `SELECT date, week, day, exercise, set_number AS setNumber, weight_kg AS weightKg, reps
     FROM workout_logs WHERE user_id = ? ORDER BY date DESC LIMIT 400`
  ).all(uid);
  // group
  const grouped = new Map();
  for (const r of logs) {
    const k = `${r.date}|${r.exercise}`;
    if (!grouped.has(k)) grouped.set(k, { date: r.date, week: r.week, day: r.day, exercise: r.exercise, sets: [] });
    grouped.get(k).sets.push(`${r.setNumber}:${r.weightKg}kgx${r.reps}`);
  }
  const workoutSummary = [...grouped.values()].slice(0, 20)
    .map((g) => `${g.date} ${g.day ?? ''} ${g.exercise} [${g.sets.join(' ')}]`)
    .join('\n');

  const weights = db.prepare('SELECT date, kg FROM body_weight WHERE user_id = ? ORDER BY date').all(uid);
  const weightTrend = weights.map((w) => `${w.date}: ${w.kg}kg`).join(', ') || 'none';

  const kegels = db.prepare('SELECT date, sets, hold_seconds AS hold FROM kegel_logs WHERE user_id = ? ORDER BY date DESC LIMIT 30').all(uid);
  const kegelSummary = kegels.map((k) => `${k.date}: ${k.sets} sets x ${k.hold}s`).join('\n') || 'none yet';

  const checkins = db.prepare('SELECT date, energy, sleep_hours AS sleep, water_l AS water, mood FROM checkins WHERE user_id = ? ORDER BY date DESC LIMIT 14').all(uid);
  const checkinSummary = checkins.map((c) => `${c.date} energy:${c.energy ?? '?'} sleep:${c.sleep ?? '?'}h water:${c.water ?? '?'}L mood:${c.mood ?? '-'}`).join('\n') || 'none yet';

  const settingsRow = db.prepare(`SELECT key, value FROM settings WHERE user_id = ? AND key IN ('program_start_date','reminder_time','gym_time','wake_time')`).all(uid);
  const settings = Object.fromEntries(settingsRow.map((r) => [r.key, r.value]));

  // attendance over last 21 days (Mon-Sat expected)
  const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  const hasLogDate = new Set(db.prepare('SELECT DISTINCT date FROM workout_logs WHERE user_id = ?').all(uid).map((r) => r.date));
  const att = [];
  for (let i = 20; i >= 0; i--) {
    const d = new Date(Date.now() - i * 86400000);
    const di = iso(d);
    if (d.getDay() === 0) continue; // Sunday rest
    att.push(`${di} ${dayNames[d.getDay() - 1]}: ${hasLogDate.has(di) ? 'trained' : 'missed'}`);
  }

  const ms = db.prepare('SELECT date, waist_cm AS waist, chest_cm AS chest, arm_cm AS arm FROM measurements WHERE user_id = ? ORDER BY date').all(uid);
  const msTrend = ms.map((m) => `${m.date} waist:${m.waist ?? '-'} chest:${m.chest ?? '-'} arm:${m.arm ?? '-'}`).join('\n') || 'none';

  const now = new Date();
  const recent7 = db.prepare('SELECT COUNT(DISTINCT date) n FROM workout_logs WHERE user_id = ? AND date >= ?').get(uid, iso(new Date(Date.now() - 6 * 86400000)));
  const todayLogs = db.prepare('SELECT COUNT(*) n FROM workout_logs WHERE user_id = ? AND date = ?').get(uid, iso(now)).n;

  const prs = db.prepare(
    `SELECT exercise, MAX(weight_kg) kg FROM workout_logs WHERE weight_kg > 0 AND user_id = ? GROUP BY exercise ORDER BY kg DESC LIMIT 5`
  ).all(uid);

  return {
    snapshot_date: iso(now),
    week_of_program: weekOf(settings.program_start_date),
    program_start_date: settings.program_start_date || 'not set',
    settings,
    latest_body_weight: weights.length ? weights[weights.length - 1].kg : null,
    body_weight_history: weightTrend,
    measurement_history: msTrend,
    trainings_last_7_days: recent7.n,
    trained_today: todayLogs > 0,
    personal_records: prs.map((p) => `${p.exercise}: ${p.kg}kg`).join(', ') || 'none yet',
    recent_workouts: workoutSummary || 'none yet',
    kegel_history: kegelSummary,
    daily_checkins: checkinSummary,
    attendance_3_weeks: att.join('\n'),
  };
}

const historyQ = db.prepare(
  `SELECT role, content FROM chat_messages WHERE user_id = ? ORDER BY id DESC LIMIT 10`
);
const insertQ = db.prepare(
  `INSERT INTO chat_messages (user_id, role, content) VALUES (?, ?, ?)`
);

export async function askCoach(userId, userMessage, { dayPlan = '' } = {}) {
  if (!API_KEY) {
    throw new CoachError(503, 'AI coach is not configured on the server yet (OPENROUTER_API_KEY missing).');
  }
  const context = buildContext(userId);
  const history = historyQ.all(userId).reverse();
  const system = SYSTEM_PROMPT + '\n\n=== HIS CURRENT DATA ===\n' + JSON.stringify(context, null, 1) +
    (dayPlan ? `\n=== TODAY'S SCHEDULED SESSION ===\n${dayPlan}` : '');

  const messages = [
    { role: 'system', content: system },
    ...history.map((h) => ({ role: h.role, content: h.content })),
    { role: 'user', content: userMessage },
  ];

  let lastErr = null;
  for (const model of MODELS()) {
    try {
      const resp = await fetch(BASE, {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${API_KEY}`,
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://gym.abba-s.dev',
          'X-Title': 'IronForge',
        },
        body: JSON.stringify({ model, messages, max_tokens: 800, temperature: 0.7 }),
        signal: AbortSignal.timeout(90000),
      });
      if (!resp.ok) {
        const e = await resp.json().catch(() => ({}));
        lastErr = new CoachError(502, `model ${model}: ${e?.error?.message || resp.status}`);
        continue;
      }
      const j = await resp.json();
      const reply = j.choices?.[0]?.message?.content;
      if (!reply) {
        lastErr = new CoachError(502, `model ${model}: empty reply`);
        continue;
      }
      insertQ.run(userId, 'user', userMessage.slice(0, 2000));
      insertQ.run(userId, 'assistant', reply.slice(0, 4000));
      return { reply, model };
    } catch (e) {
      lastErr = e instanceof CoachError ? e : new CoachError(502, `model ${model}: ${e.message}`);
    }
  }
  throw lastErr || new CoachError(502, 'all models failed');
}

export function recentChat(userId, limit = 20) {
  return db.prepare(
    'SELECT id, role, content, created_at AS createdAt FROM chat_messages WHERE user_id = ? ORDER BY id DESC LIMIT ?'
  ).all(userId, limit).reverse();
}

export function clearChat(userId) {
  return db.prepare('DELETE FROM chat_messages WHERE user_id = ?').run(userId);
}

export class CoachError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
  }
}
