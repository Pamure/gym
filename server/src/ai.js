import db from './db.js';

const API_KEY = process.env.OPENROUTER_API_KEY || '';
const BASE = 'https://openrouter.ai/api/v1/chat/completions';
// Only explicitly free variants are permitted. The previously configured
// Minimax free variant is no longer listed by OpenRouter; leave the remote
// secret-bearing .env untouched and migrate that stale override at runtime.
// Both NVIDIA variants were verified against the configured key on 2026-09-30:
// Super responded in ~3–5 seconds; Ultra is the slower capacity fallback.
const FREE_PRIMARY = 'nvidia/nemotron-3-super-120b-a12b:free';
const FREE_FALLBACK = 'nvidia/nemotron-3-ultra-550b-a55b:free';
const RETIRED_MODEL = 'minimax/minimax-m3:free';
export function selectModels(env = process.env) {
  const configured = env.OPENROUTER_MODEL;
  const primary = configured?.endsWith(':free') && configured !== RETIRED_MODEL
    ? configured : FREE_PRIMARY;
  // Never append ':online': that variant has not been verified as free.
  return [...new Set([primary, FREE_FALLBACK])];
}
const MODELS = () => selectModels();

const SYSTEM_PROMPT = `You are IronCoach, the calm beginner coach inside IronForge.
Canonical user context: complete resistance-training beginner in Delhi, India; UFC-style gym; Sunday rest/closure. The user's own program start/end dates come from the current settings snapshot, not a hardcoded calendar. Do not invent age, height, weight, injuries, diet preferences or gym equipment. Use the user's logged data below when it exists.

CANONICAL PROGRAM SHOWN IN THE APP:
- Monday: Full Body A — goblet squat, dumbbell bench, lat pulldown, Romanian deadlift, dead bug.
- Wednesday: Full Body B — leg press, incline dumbbell press, single-arm row, dumbbell overhead press, lying leg curl, plank.
- Friday: Full Body C — goblet squat, bench press, single-arm row, lying leg curl, face pull, farmer walk.
- Tuesday/Thursday/Saturday: optional conversational-pace cardio and mobility. Sunday: full rest.
- Weeks 1-4: about 3 RIR and light technique practice; weeks 5-8: 2 RIR; weeks 9-12: 1-2 RIR. Start with 2 work sets, build toward 3 only when recovery and form are good. Most sets use 6-15 controlled reps. Rest about 2-3 minutes for demanding compounds and 1-2 minutes for smaller movements; rest longer if technique would otherwise fail.
- Progress by adding reps within the range first, then the smallest available load. Never prescribe max testing or failure on a big lift.

The trainer's original Mon-Sat body-part list is a starting point, not a moral failure. Explain that a six-day isolation split is unnecessarily complex for this first block, not that it is inherently useless. Preserve the exact names only when the user asks to compare them: Flate bench, Incline bench, Dicline bench, Flate dumble fly, Chest press machine, Pack deck fly, Dumble press, Side rase, Frnt rase, Revers, Shrugs, Lat pull, Behind lat pull, One arm machine, Seated, Close grip, Hyper extn, Barbell curl, Dumble curl, Cable curl, Pri chaire, Hammer, Single hand Dumble, Double hand Dumble, Pully push down, Dumble scul creashur, Roughf nd toughf, Squats, Leg press, Pron Leg curl, Leg extn, Calves. Never recommend behind-the-neck pulldowns or presses.

COACHING RULES:
- Keep answers short, practical and non-shaming. End with one concrete next action.
- Teach what the machine looks like, one setup cue, one breathing/form cue and a same-pattern alternative. Tell the user to ask their gym coach for a light demonstration when unsure.
- Warm up 5-8 minutes, use controlled reps, and leave 2-3 good reps in reserve by default. Sharp pain, chest pain, faintness, numbness or persistent pain means stop and seek a qualified clinician; do not diagnose.
- Cardio is optional at first and can build gradually toward public-health targets; it should not make strength sessions or recovery worse.
- Do not use guilt, punishment, forced extra sets or a six-day attendance target. Missing a session means resume the next planned session.
- Nutrition values and Delhi prices are approximate planning data, not medical prescriptions. Do not promise a fixed calorie target or protein result; ask for relevant details before personalizing.
- If asked for current research or web links, say what is verified and cite a reputable source rather than pretending to browse.
- The program lasts 12 weeks. Compute its inclusive end date from the user's saved start date; if not set, ask rather than inventing it.`;



function weekOf(startIso, todayIso) {
  if (!startIso || !todayIso) return null;
  const days = Math.round((Date.parse(`${todayIso}T00:00:00Z`) -
    Date.parse(`${startIso}T00:00:00Z`)) / 86400000);
  return Number.isFinite(days) && days >= 0 && days < 84 ? Math.floor(days / 7) + 1 : null;
}

export function buildContext(userId, now = new Date()) {
  const uid = userId;
  const delhiDate = new Intl.DateTimeFormat('en-US', {
    timeZone: 'Asia/Kolkata', year: 'numeric', month: '2-digit', day: '2-digit',
  });
  const iso = (d) => {
    const parts = Object.fromEntries(delhiDate.formatToParts(d).map((p) => [p.type, p.value]));
    return `${parts.year}-${parts.month}-${parts.day}`;
  };

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
  const kegelSummary = kegels.map((k) => `${k.date}: ${k.sets} recorded holds/sets of ${k.hold}s`).join('\n') || 'none yet';

  const checkins = db.prepare('SELECT date, energy, sleep_hours AS sleep, water_l AS water, mood FROM checkins WHERE user_id = ? ORDER BY date DESC LIMIT 14').all(uid);
  const checkinSummary = checkins.map((c) => `${c.date} energy:${c.energy ?? '?'} sleep:${c.sleep ?? '?'}h water:${c.water ?? '?'}L mood:${c.mood ?? '-'}`).join('\n') || 'none yet';

  const settingsRow = db.prepare(`SELECT key, value FROM settings WHERE user_id = ? AND key IN ('program_start_date','reminder_time','gym_time','wake_time')`).all(uid);
  const settings = Object.fromEntries(settingsRow.map((r) => [r.key, r.value]));

  // Show recent activity without treating optional recovery days as required.
  const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  const requiredStrengthDays = new Set([1, 3, 5]); // JS: Mon/Wed/Fri
  const hasLogDate = new Set(db.prepare('SELECT DISTINCT date FROM workout_logs WHERE user_id = ?').all(uid).map((r) => r.date));
  const att = [];
  const todayDelhi = iso(now);
  const startTime = Date.parse(`${settings.program_start_date}T00:00:00+05:30`);
  const endDate = Number.isFinite(startTime)
    ? iso(new Date(startTime + 83 * 86400000))
    : null;
  for (let i = 20; i >= 1; i--) { // today is not missed before the session ends
    const d = new Date(now.getTime() - i * 86400000);
    const di = iso(d);
    if (!endDate || di < settings.program_start_date || di > endDate) continue;
    const jsDay = new Date(`${di}T12:00:00Z`).getUTCDay();
    if (jsDay === 0) continue; // Sunday rest
    const status = hasLogDate.has(di)
      ? 'trained'
      : (requiredStrengthDays.has(jsDay) ? 'required strength missed' : 'optional movement not logged');
    att.push(`${di} ${dayNames[jsDay]}: ${status}`);
  }

  const ms = db.prepare('SELECT date, waist_cm AS waist, chest_cm AS chest, arm_cm AS arm FROM measurements WHERE user_id = ? ORDER BY date').all(uid);
  const msTrend = ms.map((m) => `${m.date} waist:${m.waist ?? '-'} chest:${m.chest ?? '-'} arm:${m.arm ?? '-'}`).join('\n') || 'none';

  const recent7 = db.prepare('SELECT COUNT(DISTINCT date) n FROM workout_logs WHERE user_id = ? AND date >= ?').get(uid, iso(new Date(now.getTime() - 6 * 86400000)));
  const todayLogs = db.prepare('SELECT COUNT(*) n FROM workout_logs WHERE user_id = ? AND date = ?').get(uid, todayDelhi).n;

  const prs = db.prepare(
    `SELECT exercise, MAX(weight_kg) kg FROM workout_logs WHERE weight_kg > 0 AND user_id = ? GROUP BY exercise ORDER BY kg DESC LIMIT 5`
  ).all(uid);

  return {
    snapshot_date: iso(now),
    week_of_program: weekOf(settings.program_start_date, todayDelhi),
    program_start_date: settings.program_start_date || 'not set',
    program_end_date: endDate || 'not set',
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
  const deadline = Date.now() + 75000; // shorter than the app's 90s timeout
  for (const model of MODELS()) {
    const remaining = deadline - Date.now();
    if (remaining < 3000) break;
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
        signal: AbortSignal.timeout(Math.min(remaining, 35000)),
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
