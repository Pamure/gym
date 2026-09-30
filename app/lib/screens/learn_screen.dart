import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/program.dart';
import '../theme.dart';
import '../widgets/kegel_sheet.dart';
import 'coach_screen.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  int _tab = 0;
  static const _tabs = [
    'Start here',
    'Coach',
    'Nutrition',
    'Warm-up',
    'Kegels',
    'Glossary',
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Learn',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                Text(
                  'your gym crash-course',
                  style: TextStyle(color: T.dim, fontSize: 12),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ChoiceChip(
                selected: _tab == i,
                label: Text(_tabs[i]),
                onSelected: (_) => setState(() => _tab = i),
                selectedColor: T.indigo,
                labelStyle: TextStyle(
                  color: _tab == i ? T.bg : T.dim,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
                _BeginnerPlanTab(),
                CoachScreen(),
                _NutritionTab(),
                _WarmupTab(),
                _KegelsTab(),
                _GlossaryTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BeginnerPlanTab extends StatelessWidget {
  const _BeginnerPlanTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Section(
          title: 'Your first rule: learn, do not prove',
          child: _InfoCard(
            child: Text(
              'Three short full-body strength sessions are the required plan. '
              'Optional walking and mobility build stamina without turning your first month into a six-day exam. '
              'Start lighter than you think, leave 2–3 clean reps in reserve, and ask the gym coach to check one set.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ),
        _Section(
          title: 'Weekly map',
          child: _InfoCard(
            child: Column(
              children: [
                _PlanRow('MON', 'Full Body A', 'Required · 5–8 min warm-up'),
                _PlanRow(
                  'TUE',
                  'Easy cardio + mobility',
                  'Optional · conversation pace',
                ),
                _PlanRow('WED', 'Full Body B', 'Required · machines are okay'),
                _PlanRow('THU', 'Rest / easy walk', 'Optional · recover'),
                _PlanRow('FRI', 'Full Body C', 'Required · balanced finish'),
                _PlanRow('SAT', 'Zone 2 walk / cycle', 'Optional · stop fresh'),
                _PlanRow('SUN', 'Rest', 'Gym closed'),
              ],
            ),
          ),
        ),
        _Section(
          title: 'Your gym trainer plan',
          child: Column(
            children: [
              _InfoCard(
                child: const Text(
                  'This is the plan you brought from the UFC Okhla gym trainer. IronForge keeps the trainer labels, adds a beginner starting dose, and marks unclear or unsafe names instead of silently guessing.',
                  style: TextStyle(fontSize: 13, height: 1.45),
                ),
              ),
              const SizedBox(height: 8),
              for (final day in coachPlanDays.take(6)) _CoachDayCard(day: day),
            ],
          ),
        ),
        _Section(
          title: 'How to choose weight',
          child: _InfoCard(
            child: _BulletList(const [
              'Choose a load you can move with the same range and speed on every rep.',
              'Finish the set knowing you could do about 2–3 more good reps.',
              'When every set reaches the top of its range, add the smallest available plate.',
              'If the machine is busy, use the alternative shown inside the expanded exercise card.',
              'Sharp pain, numbness, chest pain or faintness is a stop signal — ask a qualified professional.',
            ], dot: T.green),
          ),
        ),
      ],
    );
  }
}

class _CoachDayCard extends StatelessWidget {
  final ProgramDay day;
  const _CoachDayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
        title: Text(
          day.title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        ),
        subtitle: const Text(
          'Start with 1 set · ask the trainer to show the machine',
          style: TextStyle(color: T.dim, fontSize: 12),
        ),
        children: [
          for (final item in day.items)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    item.coachPrescription ?? '',
                    style: const TextStyle(
                      color: T.coral,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          const Text(
            'Open Workout → Gym trainer plan for equipment, form cues and simpler alternatives.',
            style: TextStyle(color: T.teal, fontSize: 12, height: 1.3),
          ),
        ],
      ),
    );
  }
}

class _PlanRow extends StatelessWidget {
  final String day;
  final String title;
  final String note;
  const _PlanRow(this.day, this.title, this.note);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 360;
          final dayText = Text(
            day,
            style: const TextStyle(
              color: T.pink,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          );
          final titleText = Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          );
          final noteText = Text(
            note,
            style: TextStyle(color: T.dim, fontSize: 12, height: 1.25),
          );
          if (narrow) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 42, child: dayText),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [titleText, const SizedBox(height: 2), noteText],
                  ),
                ),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 44, child: dayText),
              Expanded(child: titleText),
              const SizedBox(width: 8),
              Flexible(
                child: Align(alignment: Alignment.centerRight, child: noteText),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final Widget child;
  const _InfoCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(padding: const EdgeInsets.all(14), child: child),
    );
  }
}

class _BulletList extends StatelessWidget {
  final List<String> items;
  final Color? dot;
  const _BulletList(this.items, {this.dot = T.indigo});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final t in items)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '•  ',
                  style: TextStyle(color: dot, fontWeight: FontWeight.w900),
                ),
                Expanded(
                  child: Text(
                    t,
                    style: TextStyle(
                      color: T.text.withValues(alpha: 0.9),
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ---------------- NUTRITION ----------------
class _NutritionTab extends StatelessWidget {
  const _NutritionTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Section(
          title: 'Food basics (no rigid diet required)',
          child: _InfoCard(
            child: Column(
              children: [
                _TargetRow(
                  'Protein',
                  'each meal',
                  'eggs, chicken, dairy, soy, dal or tofu',
                ),
                _TargetRow(
                  'Calories',
                  'steady meals',
                  'do not crash diet or force a bulk',
                ),
                _TargetRow(
                  'Water',
                  'drink regularly',
                  'more in heat; use thirst and urine as rough cues',
                ),
                _TargetRow('Sleep', '7-9 h', 'recovery and learning form'),
              ],
            ),
          ),
        ),
        _Section(
          title: 'Budget protein sources',
          child: _InfoCard(
            child: _BulletList(const [
              'Eggs — 6g each, cheapest complete protein',
              'Soya chunks (dry) — ~52g/100g, cheapest per rupee',
              'Chicken breast (cooked) — ~31g/100g, the gold standard',
              'Paneer — 18g/100g (calorie-dense, moderate)',
              'Curd/dahi — 8-11g/100g',
              'Dal — 7-9g cooked, combine with rice/roti',
            ]),
          ),
        ),
        _Section(
          title: 'Sample day (illustration, not a prescription)',
          child: _InfoCard(
            child: _BulletList(const [
              'Morning: water + a normal breakfast you can repeat',
              'Breakfast: eggs or soy/tofu + roti or oats + fruit',
              'Lunch: dal/chicken/paneer + rice or roti + vegetables',
              'Before training: a familiar meal or banana if hungry',
              'Dinner: a protein source + carbohydrates + vegetables',
              'Adjust portions to your hunger, goals, budget and clinician advice.',
            ], dot: T.green),
          ),
        ),
        _Section(
          title: 'Truths that save beginners',
          child: _InfoCard(
            child: _BulletList(const [
              'Love handles shrink from the kitchen + full-body training — NOT ab exercises (spot reduction is a myth)',
              'Include a protein source regularly; the exact amount depends on your body, goals and health.',
              'Post-workout timing is less important than your total daily food and consistency.',
              'Supplements are not required to start. Ask a clinician before using one.',
              'Skip mystery mass gainers, fat burners and any unlabeled “trainer special” product.',
            ], dot: T.amber),
          ),
        ),
      ],
    );
  }
}

class _TargetRow extends StatelessWidget {
  final String label, value, note;
  const _TargetRow(this.label, this.value, this.note);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: T.pink,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(note, style: TextStyle(color: T.dim, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}

// ---------------- WARM-UP ----------------
class _WarmupTab extends StatelessWidget {
  const _WarmupTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const _Section(
          title: 'RAMP warm-up — every session, 5-8 min',
          child: _InfoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RampRow(
                  'R',
                  'Raise',
                  'Heart rate up — brisk walk / jumping jacks',
                  '2 min',
                ),
                _RampRow(
                  'A',
                  'Activate',
                  'Glute bridges, bodyweight squats, band pull-aparts',
                  '2 min',
                ),
                _RampRow(
                  'M',
                  'Mobilize',
                  'Arm circles, hip circles, leg swings, cat-cow',
                  '2 min',
                ),
                _RampRow(
                  'P',
                  'Potentiate',
                  '2 light sets of your first lift: 50% × 5, 70% × 3',
                  '2 min',
                ),
              ],
            ),
          ),
        ),
        const _Section(
          title: 'Why dynamic (not static) before lifting',
          child: _InfoCard(
            child: _BulletList([
              'Static stretching BEFORE lifting temporarily reduces strength — save it for after',
              'Dynamic warm-up raises tissue temperature and preps the nervous system',
              'Never skip: cold muscles + load = the #1 beginner injury mechanism',
            ]),
          ),
        ),
        _Section(
          title: 'Post-workout cool-down (3-5 min)',
          child: _InfoCard(
            child: _BulletList(const [
              'Walk until breathing normalizes',
              'Static stretch the trained muscles 30s each — mild tension, never pain',
              'Optional recovery days show a short mobility circuit (see Workout → Tuesday/Thursday)',
            ]),
          ),
        ),
      ],
    );
  }
}

class _RampRow extends StatelessWidget {
  final String letter, name, detail, time;
  const _RampRow(this.letter, this.name, this.detail, this.time);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              gradient: T.gradient,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              letter,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name  ·  $time',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
                Text(
                  detail,
                  style: TextStyle(color: T.dim, fontSize: 12, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- KEGELS ----------------
class _KegelsTab extends StatelessWidget {
  const _KegelsTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _Section(title: 'Guided session', child: _KegelOpenCard()),
        _Section(
          title: 'Why kegels (men)',
          child: _InfoCard(
            child: _BulletList(const [
              'Stronger erections & ejaculatory control',
              'Better urinary control',
              'Stronger core floor supports heavy lifting',
              'Results typically at 6-8 weeks of daily practice',
            ], dot: T.green),
          ),
        ),
        _Section(
          title: 'Find the muscle (do this once)',
          child: _InfoCard(child: _BulletList(kegelGuide['setup']!)),
        ),
        _Section(
          title: 'Technique',
          child: _InfoCard(child: _BulletList(kegelGuide['technique']!)),
        ),
        _Section(
          title: 'Monthly progression',
          child: _InfoCard(
            child: _BulletList(kegelGuide['months']!, dot: T.pink),
          ),
        ),
        _Section(
          title: 'Mistakes',
          child: _InfoCard(
            child: _BulletList(kegelGuide['mistakes']!, dot: T.red),
          ),
        ),
      ],
    );
  }
}

class _KegelOpenCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'Run a guided set: squeeze-hold timer + auto save.',
                style: TextStyle(color: T.dim, fontSize: 12.5),
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: T.pink),
              onPressed: () => showKegelSheet(context, ref),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Start timer'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------- GLOSSARY ----------------
class _GlossaryTab extends StatelessWidget {
  const _GlossaryTab();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Section(
          title: 'Terms you will hear in the gym',
          child: Card(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                children: [
                  _Term('Rep', 'One complete movement. 10 push-ups = 10 reps.'),
                  _Term(
                    'Set',
                    'A group of reps with rest after. "3×10" = 3 sets of 10.',
                  ),
                  _Term(
                    'RIR (Reps In Reserve)',
                    'How many more GOOD reps you could do. Month 1: 3 RIR means stop with 3 left. The core dial of your whole program.',
                  ),
                  _Term(
                    'Progressive overload',
                    'Doing slightly more over time (weight/reps/control). THE driver of muscle growth.',
                  ),
                  _Term(
                    'Double progression',
                    'Fill the rep range first (e.g. reach 12 everywhere), then add weight and start back at 10.',
                  ),
                  _Term(
                    'Compound',
                    'Multi-joint lift: squat, bench, deadlift, row, press. The foundation.',
                  ),
                  _Term(
                    'Isolation',
                    'One muscle: curls, pushdowns, lateral raises, leg curls.',
                  ),
                  _Term(
                    'Hypertrophy',
                    'Muscle growth. 6-15 hard reps = hypertrophy range.',
                  ),
                  _Term(
                    'Deload',
                    'A planned easy week (half sets, ~60% weight) so your body absorbs training.',
                  ),
                  _Term(
                    'DOMS',
                    'Dull muscle soreness 24-72h after training. Normal — not an injury, not a progress meter.',
                  ),
                  _Term(
                    'Eccentric / negative',
                    'The lowering half of the rep. Control it 2-3s — half the growth lives here.',
                  ),
                  _Term(
                    'Bracing',
                    '360° core tightness (as if bracing for a punch) under load.',
                  ),
                  _Term(
                    'Mind-muscle connection',
                    'Feeling the target muscle work. Grows over weeks — the "which muscle burned?" check trains it.',
                  ),
                  _Term(
                    'Plateau',
                    '2+ weeks with no progress. Check sleep → protein → attendance before changing anything.',
                  ),
                  _Term(
                    'Cut / Bulk',
                    'Eat to lose fat / gain weight. You are doing neither hard — you are recompositioning (muscle up, waist down).',
                  ),
                  _Term(
                    '1RM',
                    'One-rep max. Beginners never test it — your rep ranges do the job.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Term extends StatelessWidget {
  final String term;
  final String def;
  const _Term(this.term, this.def);

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: Text(
        term,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
      ),
      childrenPadding: const EdgeInsets.only(bottom: 10),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            def,
            style: TextStyle(color: T.dim, fontSize: 12.5, height: 1.4),
          ),
        ),
      ],
    );
  }
}
