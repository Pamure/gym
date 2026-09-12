import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/exercises.dart';
import '../data/program.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kegel_sheet.dart';
import '../widgets/youtube_sheet.dart';

final selectedWeekProvider = StateProvider<int>((ref) => 1);
final selectedDayProvider = StateProvider<String>((ref) => 'monday');

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    final st = ref.read(appStateProvider);
    final week = st.currentWeek();
    // default: today's day unless dashboard already aimed at another day
    final weekday = DateTime.now().weekday; // 1=Mon
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (ref.read(selectedWeekProvider) != week && !_userTouchedWeek) {
        ref.read(selectedWeekProvider.notifier).state = week;
      }
      if (!_userTouchedDay) {
        ref.read(selectedDayProvider.notifier).state =
            programDays[weekday - 1].key;
      }
    });
  }

  bool _userTouchedWeek = false;
  bool _userTouchedDay = false;

  @override
  Widget build(BuildContext context) {
    final week = ref.watch(selectedWeekProvider);
    final dayKey = ref.watch(selectedDayProvider);
    final state = ref.watch(appStateProvider);
    final month = monthForWeek(week);
    final phase = phaseForWeek(week);
    final day = programDays.firstWhere((d) => d.key == dayKey);
    final loggedToday =
        state.logsOn(state.todayIso()).map((l) => l.exercise).toSet();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Workout plan',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    Chip(
                      backgroundColor: T.surface2,
                      label: Text(phase.name,
                          style: TextStyle(
                              color: T.pink,
                              fontSize: 11,
                              fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(phase.description,
                    style: TextStyle(color: T.dim, fontSize: 12, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // week selector
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: 12,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final w = i + 1;
                final selected = w == week;
                return ChoiceChip(
                  selected: selected,
                  label: Text('W$w'),
                  onSelected: (_) {
                    _userTouchedWeek = true;
                    ref.read(selectedWeekProvider.notifier).state = w;
                  },
                  selectedColor: T.indigo,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : T.dim,
                      fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // day selector
          SizedBox(
            height: 40,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: programDays.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final d = programDays[i];
                final selected = d.key == dayKey;
                final short = d.key.substring(0, 1).toUpperCase() + d.key.substring(1, 3);
                return ChoiceChip(
                  selected: selected,
                  avatar: Text(d.emoji, style: const TextStyle(fontSize: 12)),
                  label: Text(short),
                  onSelected: (_) {
                    _userTouchedDay = true;
                    ref.read(selectedDayProvider.notifier).state = d.key;
                  },
                  selectedColor: T.pink,
                  labelStyle: TextStyle(
                      color: selected ? Colors.white : T.dim,
                      fontSize: 12,
                      fontWeight: FontWeight.w700),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: day.restDay
                ? const _RestView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      Row(
                        children: [
                          Text('${day.emoji} ${day.title}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(width: 8),
                          Expanded(
                              child: Text(day.focus,
                                  style: TextStyle(color: T.dim, fontSize: 12))),
                          Text('${phase.rir}',
                              style: TextStyle(
                                  color: T.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Rest: compounds 2-3 min · isolation 60-90s · '
                          'Log weight & reps after every set.',
                          style: TextStyle(color: T.dim, fontSize: 11)),
                      const SizedBox(height: 12),
                      for (final pe in day.items)
                        _ExerciseCard(
                          key: ValueKey('${dayKey}-${pe.id}-$month'),
                          pe: pe,
                          month: month,
                          doneToday: loggedToday.contains(pe.id),
                        ),
                      const SizedBox(height: 12),
                      // warmup reminder footer
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: T.surface2,
                          border: Border.all(color: T.border),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.self_improvement, color: T.indigo),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  'Start with the RAMP warm-up (2 min raise → 2 min activate → 2 min mobilize → light first-set). See Learn → Warm-up.',
                                  style:
                                      TextStyle(color: T.dim, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RestView extends StatelessWidget {
  const _RestView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('😴', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 12),
              const Text('Sunday — REST DAY',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                  'Your gym is closed and that is a gift: muscles grow on rest days.\n'
                  '• Sleep 8 hours\n'
                  '• Protein 110-140g\n'
                  '• Drink water, walk a little\n'
                  '• Do one kegel set if you remember',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: T.dim, height: 1.7, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends ConsumerStatefulWidget {
  final ProgramExercise pe;
  final int month;
  final bool doneToday;
  const _ExerciseCard(
      {super.key,
      required this.pe,
      required this.month,
      required this.doneToday});

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  late final bool _isWeight =
      weightBasedIds.contains(widget.pe.id) && widget.pe.id != 'farmers-walk';
  final List<TextEditingController> _kg = [];
  final List<TextEditingController> _reps = [];
  bool _expanded = false;
  bool _saved = false;

  Exercise? get _ex => exercises[widget.pe.id];

  @override
  void initState() {
    super.initState();
    _saved = widget.doneToday;
  }

  @override
  void didUpdateWidget(_ExerciseCard old) {
    super.didUpdateWidget(old);
    if (widget.doneToday != old.doneToday) _saved = widget.doneToday;
  }

  @override
  void dispose() {
    for (final c in _kg) c.dispose();
    for (final c in _reps) c.dispose();
    super.dispose();
  }

  void _ensureControllers(AppState state) {
    if (_kg.isNotEmpty) return;
    final setsN = widget.pe.setsByMonth[widget.month];
    // prefill from most recent log of this exercise
    WorkoutLog? last;
    for (final l in state.workouts) {
      if (l.exercise == widget.pe.id) last = l;
    }
    for (var i = 1; i <= setsN; i++) {
      final s = last != null && i <= last.sets.length ? last.sets[i - 1] : null;
      _kg.add(TextEditingController(
          text: (s?.weightKg ?? 0) > 0 ? '${s!.weightKg}' : ''));
      _reps.add(TextEditingController(text: s != null ? '${s.reps}' : ''));
    }
  }

  Future<void> _save(AppState state, String date) async {
    final sets = <WorkoutSet>[];
    for (var i = 0; i < _kg.length; i++) {
      final kg = double.tryParse(_kg[i].text.trim()) ?? 0;
      final reps = int.tryParse(_reps[i].text.trim()) ?? 0;
      sets.add(WorkoutSet(i + 1, kg, reps));
    }
    await state.logWorkout(WorkoutLog(
      date: date,
      week: ref.read(selectedWeekProvider),
      day: ref.read(selectedDayProvider),
      exercise: widget.pe.id,
      sets: sets,
    ));
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${widget.pe.name} logged'),
          duration: const Duration(milliseconds: 1200)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final ex = _ex;
    final date = state.todayIso();
    final setsN = widget.pe.setsByMonth[widget.month];
    final repsTarget = widget.pe.repsByMonth[widget.month];
    final isKegel = widget.pe.id == 'kegels';

    // kegels / recovery special cards
    if (isKegel) return _KegelCard(pe: widget.pe, month: widget.month);
    if (ex == null) {
      const special = {
        'recovery-walk':
            'Light cardio — brisk walk / cycle / treadmill at conversational pace. 20 minutes.',
        'recovery-stretch':
            'Stretch + foam roll: 1 min per area (quads, hamstrings, glutes, upper back, lats) then static stretches 30s each.',
      };
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Text('🌿', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(special[widget.pe.id] ?? widget.pe.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 13.5, height: 1.4)),
              ),
            ],
          ),
        ),
      );
    }

    _ensureControllers(state);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (ex.gif != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(ex.gifAsset,
                          width: 64, height: 64, fit: BoxFit.cover,
                          gaplessPlayback: true),
                    )
                  else
                    Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        color: T.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.sports_gymnastics, color: T.indigo),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.pe.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14.5, height: 1.25)),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            for (final m in ex.muscles.take(3))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: T.indigo.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(m,
                                    style: const TextStyle(
                                        fontSize: 10, color: Color(0xFFB9BCFF))),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${setsN} × $repsTarget${widget.pe.unit ?? ''}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: T.pink)),
                      const SizedBox(height: 4),
                      _saved
                          ? const Icon(Icons.check_circle, color: T.green, size: 20)
                          : const Icon(Icons.unfold_more, color: T.dim, size: 20),
                    ],
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // demo + cues + mistakes
                Row(
                  children: [
                    if (ex.gif != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(ex.gifAsset,
                            width: 150, height: 150, fit: BoxFit.cover,
                            gaplessPlayback: true),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: ex.videoId != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                      backgroundColor: Colors.red.shade700),
                                  onPressed: () => showVideoSheet(
                                      context, widget.pe.name, ex.videoId!),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Watch tutorial'),
                                ),
                                const SizedBox(height: 6),
                                Text('Pro form demo (Jeff Nippard / Alan Thrall)',
                                    style: TextStyle(
                                        color: T.dim, fontSize: 10.5)),
                              ],
                            )
                          : Text('Follow the cues below — every rep controlled.',
                              style: TextStyle(color: T.dim, fontSize: 11.5)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _CuesBlock(title: '✅ Correct form', items: ex.cues, icon: T.green),
                const SizedBox(height: 8),
                _CuesBlock(
                    title: '⚠️ Never do this', items: ex.mistakes, icon: T.red),
                // logging area
                const SizedBox(height: 12),
                if (_isWeight) ...[
                  Text('Log today ($date)',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _kg.length; i++) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text('Set ${i + 1}',
                              style: TextStyle(color: T.dim, fontSize: 12)),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _kg[i],
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                hintText: 'kg'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _reps[i],
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                hintText: 'reps'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Row(
                    children: [
                      Text('Aim: ${setsN} sets · ~$repsTarget${widget.pe.unit ?? ''} · ${phaseForWeek(ref.read(selectedWeekProvider)).rir}',
                          style: TextStyle(color: T.dim, fontSize: 11)),
                      const Spacer(),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                            backgroundColor: _saved ? T.green : T.indigo),
                        onPressed: () => _save(state, date),
                        icon: Icon(_saved ? Icons.check : Icons.save_outlined, size: 16),
                        label: Text(_saved ? 'Saved' : 'Save sets'),
                      ),
                    ],
                  ),
                ] else
                  Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: _saved ? T.green : T.indigo),
                      onPressed: () async {
                        await state.logWorkout(WorkoutLog(
                            date: date,
                            week: ref.read(selectedWeekProvider),
                            day: ref.read(selectedDayProvider),
                            exercise: widget.pe.id,
                            sets: const [WorkoutSet(1, 0, 1)]));
                        setState(() => _saved = true);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text('${widget.pe.name} done'),
                            duration: const Duration(milliseconds: 1000)));
                      },
                      icon: Icon(_saved ? Icons.check : Icons.done_all, size: 16),
                      label: Text(_saved ? 'Done' : 'Mark done'),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KegelCard extends ConsumerWidget {
  final ProgramExercise pe;
  final int month;
  const _KegelCard({required this.pe, required this.month});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: T.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite, color: T.pink),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('Kegels (pelvic floor)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                ),
                Text('3×${pe.repsByMonth[month]}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: T.pink)),
              ],
            ),
            const SizedBox(height: 8),
            Text(kegelGuide['technique']!.join('\n'),
                style: TextStyle(color: T.dim, fontSize: 12, height: 1.5)),
            const SizedBox(height: 6),
            Text('Month ${month + 1}: ${kegelGuide['months']![month]}',
                style: TextStyle(
                    color: T.amber, fontSize: 11.5, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: T.pink),
              onPressed: () => showKegelSheet(context, ref),
              icon: const Icon(Icons.timer_outlined),
              label: const Text('Open guided kegel timer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CuesBlock extends StatelessWidget {
  final String title;
  final List<String> items;
  final Color icon;
  const _CuesBlock(
      {required this.title, required this.items, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: T.surface2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: icon, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          for (final cue in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('•  ',
                      style: TextStyle(color: icon, fontSize: 12, fontWeight: FontWeight.w900)),
                  Expanded(
                      child: Text(cue,
                          style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: T.text.withValues(alpha: 0.9)))),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
