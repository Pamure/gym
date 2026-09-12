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
  static const _tabs = ['Coach', 'Nutrition', 'Warm-up', 'Kegels', 'Glossary'];

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
                const Text('Learn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                const Spacer(),
                Text('your gym crash-course', style: TextStyle(color: T.dim, fontSize: 12)),
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
                    color: _tab == i ? Colors.white : T.dim,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [
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
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
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
                Text('•  ', style: TextStyle(color: dot, fontWeight: FontWeight.w900)),
                Expanded(
                  child: Text(t,
                      style: TextStyle(
                          color: T.text.withValues(alpha: 0.9),
                          fontSize: 13,
                          height: 1.4)),
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
          title: 'Your 4 daily targets (68 kg)',
          child: _InfoCard(
            child: Column(
              children: [
                _TargetRow('Protein', '110-140 g', 'muscle repair — non-negotiable'),
                _TargetRow('Calories', '2,200-2,500', 'slight surplus — recomp, not bulk'),
                _TargetRow('Water', '3-4 L', 'Delhi heat + training'),
                _TargetRow('Sleep', '7-9 h', 'growth happens here'),
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
          title: 'Sample day (~125 g protein)',
          child: _InfoCard(
            child: _BulletList(const [
              'Morning: water + 5 soaked almonds + banana',
              'Breakfast: 3-4 egg whites + 2 whole eggs (bhurji/boiled) + 2 rotis or oats',
              'Mid-morning: curd + 50g roasted soya chunks',
              'Lunch: 150g chicken curry + 2 rotis + rice + salad',
              'Evening (pre-workout): peanut-butter sandwich + banana',
              'Dinner (post-workout): 100g chicken/paneer/soya + rotis + vegetables',
            ], dot: T.green),
          ),
        ),
        _Section(
          title: 'Truths that save beginners',
          child: _InfoCard(
            child: _BulletList(const [
              'Love handles shrink from the kitchen + full-body training — NOT ab exercises (spot reduction is a myth)',
              'Protein every meal (20-35g), don\'t hoard it for dinner',
              'Post-workout "anabolic window" is mostly myth — a normal meal within ~2h is enough',
              'Supplements needed: none. Optional: whey + creatine 3-5g/day (most-studied supplement ever)',
              'Skip: mass gainers (sugar), fat burners (useless/dangerous), "trainer special" supplements',
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
          Expanded(flex: 3, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(
              flex: 2,
              child: Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, color: T.pink))),
          Expanded(
              flex: 4,
              child: Text(note,
                  style: TextStyle(color: T.dim, fontSize: 11.5))),
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
                _RampRow('R', 'Raise', 'Heart rate up — brisk walk / jumping jacks', '2 min'),
                _RampRow('A', 'Activate', 'Glute bridges, bodyweight squats, band pull-aparts', '2 min'),
                _RampRow('M', 'Mobilize', 'Arm circles, hip circles, leg swings, cat-cow', '2 min'),
                _RampRow('P', 'Potentiate', '2 light sets of your first lift: 50% × 5, 70% × 3', '2 min'),
              ],
            ),
          ),
        ),
        const _Section(
          title: 'Why dynamic (not static) before lifting',
          child: _InfoCard(
            child: _BulletList(const [
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
              'Thursday has the full mobility circuit (see Workout → Thursday)',
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
            decoration: BoxDecoration(gradient: T.gradient, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(letter,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$name  ·  $time',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                Text(detail,
                    style: TextStyle(color: T.dim, fontSize: 12, height: 1.3)),
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
        _Section(
          title: 'Guided session',
          child: _KegelOpenCard(),
        ),
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
          child: _InfoCard(
            child: _BulletList(kegelGuide['setup']!),
          ),
        ),
        _Section(
          title: 'Technique',
          child: _InfoCard(
            child: _BulletList(kegelGuide['technique']!),
          ),
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
              child: Text('Run a guided set: squeeze-hold timer + auto save.',
                  style: TextStyle(color: T.dim, fontSize: 12.5)),
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
                  _Term('Set', 'A group of reps with rest after. "3×10" = 3 sets of 10.'),
                  _Term('RIR (Reps In Reserve)', 'How many more GOOD reps you could do. Month 1: 3 RIR means stop with 3 left. The core dial of your whole program.'),
                  _Term('Progressive overload', 'Doing slightly more over time (weight/reps/control). THE driver of muscle growth.'),
                  _Term('Double progression', 'Fill the rep range first (e.g. reach 12 everywhere), then add weight and start back at 10.'),
                  _Term('Compound', 'Multi-joint lift: squat, bench, deadlift, row, press. The foundation.'),
                  _Term('Isolation', 'One muscle: curls, pushdowns, lateral raises, leg curls.'),
                  _Term('Hypertrophy', 'Muscle growth. 6-15 hard reps = hypertrophy range.'),
                  _Term('Deload', 'A planned easy week (half sets, ~60% weight) so your body absorbs training.'),
                  _Term('DOMS', 'Dull muscle soreness 24-72h after training. Normal — not an injury, not a progress meter.'),
                  _Term('Eccentric / negative', 'The lowering half of the rep. Control it 2-3s — half the growth lives here.'),
                  _Term('Bracing', '360° core tightness (as if bracing for a punch) under load.'),
                  _Term('Mind-muscle connection', 'Feeling the target muscle work. Grows over weeks — the "which muscle burned?" check trains it.'),
                  _Term('Plateau', '2+ weeks with no progress. Check sleep → protein → attendance before changing anything.'),
                  _Term('Cut / Bulk', 'Eat to lose fat / gain weight. You are doing neither hard — you are recompositioning (muscle up, waist down).'),
                  _Term('1RM', 'One-rep max. Beginners never test it — your rep ranges do the job.'),
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
      title: Text(term,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
      childrenPadding: const EdgeInsets.only(bottom: 10),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(def,
              style: TextStyle(color: T.dim, fontSize: 12.5, height: 1.4)),
        ),
      ],
    );
  }
}
