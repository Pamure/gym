import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercises.dart';
import '../data/exercise_guides.dart';
import '../data/program.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/kegel_sheet.dart';
import '../widgets/youtube_sheet.dart';

enum WorkoutPlanMode { coach, starter }

final selectedWeekProvider = StateProvider<int>((ref) => 1);
final selectedDayProvider = StateProvider<String>((ref) => 'monday');
final workoutPlanModeProvider = StateProvider<WorkoutPlanMode>(
  (ref) => WorkoutPlanMode.coach,
);

List<ProgramDay> _daysForMode(WorkoutPlanMode mode) =>
    mode == WorkoutPlanMode.coach ? coachPlanDays : programDays;

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
    final mode = ref.watch(workoutPlanModeProvider);
    final days = _daysForMode(mode);
    final day = days.firstWhere((d) => d.key == dayKey);
    final todayKey = programDays[DateTime.now().weekday - 1].key;
    final loggedToday = state
        .logsOn(state.todayIso())
        .map((l) => l.exercise)
        .toSet();

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Workout',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      'Week $week · ${phase.name.split(' · ').first}',
                      style: TextStyle(color: T.dim, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  mode == WorkoutPlanMode.coach
                      ? 'Your gym trainer plan · lighter starting dose'
                      : 'IronForge beginner guidance · three full-body days',
                  style: TextStyle(
                    color: T.teal,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  mode == WorkoutPlanMode.coach
                      ? 'The labels below preserve what your trainer wrote. Start with the smaller dose, ask for a machine demonstration, and use the alternative if a station feels intimidating.'
                      : phase.description,
                  style: TextStyle(color: T.dim, fontSize: 13, height: 1.35),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      selected: mode == WorkoutPlanMode.coach,
                      label: const Text('Gym trainer plan'),
                      onSelected: (_) =>
                          ref.read(workoutPlanModeProvider.notifier).state =
                              WorkoutPlanMode.coach,
                      selectedColor: T.coral,
                      labelStyle: TextStyle(
                        color: mode == WorkoutPlanMode.coach ? T.bg : T.dim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    ChoiceChip(
                      selected: mode == WorkoutPlanMode.starter,
                      label: const Text('Starter guidance'),
                      onSelected: (_) =>
                          ref.read(workoutPlanModeProvider.notifier).state =
                              WorkoutPlanMode.starter,
                      selectedColor: T.teal,
                      labelStyle: TextStyle(
                        color: mode == WorkoutPlanMode.starter ? T.bg : T.dim,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Card(
                  color: T.surface2,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: week,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Program week',
                              isDense: true,
                            ),
                            items: [
                              for (var w = 1; w <= 12; w++)
                                DropdownMenuItem(
                                  value: w,
                                  child: Text('Week $w'),
                                ),
                            ],
                            onChanged: (w) {
                              if (w == null) return;
                              _userTouchedWeek = true;
                              ref.read(selectedWeekProvider.notifier).state = w;
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: dayKey,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Day',
                              isDense: true,
                            ),
                            items: [
                              for (final d in days)
                                DropdownMenuItem(
                                  value: d.key,
                                  child: Text('${d.emoji} ${_shortDay(d.key)}'),
                                ),
                            ],
                            onChanged: (key) {
                              if (key == null) return;
                              _userTouchedDay = true;
                              ref.read(selectedDayProvider.notifier).state =
                                  key;
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Expanded(
            child: day.restDay
                ? const _RestView()
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    children: [
                      _BeginnerFlowCard(day: day),
                      if (week != state.currentWeek() || dayKey != todayKey)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'Preview only · select today and the current week to save.',
                            style: TextStyle(
                              color: T.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${day.emoji} ${day.title}',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            day.focus,
                            style: TextStyle(color: T.dim, fontSize: 12),
                          ),
                          Text(
                            phase.rir,
                            style: TextStyle(
                              color: T.amber,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rest is shown on each exercise. Log only clean sets; '
                        'if form breaks, lower the weight or use the alternative.',
                        style: TextStyle(color: T.dim, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      for (final pe in day.items)
                        _ExerciseCard(
                          key: ValueKey('$dayKey-${pe.id}-$month'),
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
                                style: TextStyle(color: T.dim, fontSize: 12),
                              ),
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

class _BeginnerFlowCard extends StatelessWidget {
  final ProgramDay day;
  const _BeginnerFlowCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final intro = day.optional
        ? 'Optional movement — it should leave you feeling better, not exhausted.'
        : 'Your first month is practice, not a test. Ask the coach to check your first set.';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: T.indigo.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: T.indigo.withValues(alpha: 0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.flag_outlined, color: T.indigo, size: 19),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  day.optional ? 'OPTIONAL TODAY' : 'TODAY\'S SIMPLE FLOW',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            intro,
            style: TextStyle(color: T.dim, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            '1. 5–8 min easy warm-up   2. Exercises top to bottom   '
            '3. Rest fully   4. Walk 3–5 min and leave with energy',
            style: TextStyle(
              color: T.text.withValues(alpha: 0.9),
              fontSize: 11.5,
              height: 1.4,
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
              const Text(
                'Sunday — REST DAY',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Your gym is closed and that is a gift: muscles grow on rest days.\n'
                '• Sleep enough to feel recovered\n'
                '• Eat regular meals with a protein source\n'
                '• Drink water and take an easy walk if you want\n'
                '• Optional gentle mobility; no make-up workout',
                textAlign: TextAlign.center,
                style: TextStyle(color: T.dim, height: 1.7, fontSize: 13),
              ),
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
  const _ExerciseCard({
    super.key,
    required this.pe,
    required this.month,
    required this.doneToday,
  });

  @override
  ConsumerState<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends ConsumerState<_ExerciseCard> {
  late final bool _isWeight = weightBasedIds.contains(widget.pe.id);
  final List<TextEditingController> _kg = [];
  final List<TextEditingController> _reps = [];
  bool _expanded = false;
  bool _saved = false;
  int _restRemaining = 0;
  Timer? _restTimer;

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
    for (final c in _kg) {
      c.dispose();
    }
    for (final c in _reps) {
      c.dispose();
    }
    _restTimer?.cancel();
    super.dispose();
  }

  void _ensureControllers(AppState state) {
    if (_kg.isNotEmpty) return;
    final setsN = widget.pe.setsByMonth[widget.month];
    // prefill from most recent log of this exercise
    WorkoutLog? last;
    for (final l in state.workouts) {
      if (l.exercise == widget.pe.id &&
          (last == null || l.date.compareTo(last.date) > 0)) {
        last = l;
      }
    }
    for (var i = 1; i <= setsN; i++) {
      final s = last != null && i <= last.sets.length ? last.sets[i - 1] : null;
      _kg.add(
        TextEditingController(
          text: (s?.weightKg ?? 0) > 0 ? '${s!.weightKg}' : '',
        ),
      );
      _reps.add(TextEditingController(text: s != null ? '${s.reps}' : ''));
    }
  }

  void _startRestTimer() {
    if (widget.pe.restSeconds <= 0) return;
    _restTimer?.cancel();
    setState(() => _restRemaining = widget.pe.restSeconds);
    _restTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_restRemaining <= 1) {
        timer.cancel();
        setState(() => _restRemaining = 0);
      } else {
        setState(() => _restRemaining--);
      }
    });
  }

  String get _restCountdown {
    final minutes = _restRemaining ~/ 60;
    final seconds = _restRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  Future<void> _save(AppState state, String date) async {
    final sets = <WorkoutSet>[];
    for (var i = 0; i < _kg.length; i++) {
      final kg = double.tryParse(_kg[i].text.trim());
      final reps = int.tryParse(_reps[i].text.trim());
      if (kg == null || kg < 0 || reps == null || reps <= 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Enter a weight (0 is okay for an unloaded movement) and reps for every set.',
              ),
            ),
          );
        }
        return;
      }
      sets.add(WorkoutSet(i + 1, kg, reps));
    }
    try {
      await state.logWorkout(
        WorkoutLog(
          date: date,
          week: state.currentWeek(),
          day: programDays[DateTime.now().weekday - 1].key,
          exercise: widget.pe.id,
          sets: sets,
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Not saved: $e')));
      }
      return;
    }
    if (mounted) {
      setState(() => _saved = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.pe.name} logged'),
          duration: const Duration(milliseconds: 1200),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final ex = _ex;
    final guide = guideForExercise(widget.pe.id);
    final date = state.todayIso();
    final previewOnly =
        ref.watch(selectedWeekProvider) != state.currentWeek() ||
        ref.watch(selectedDayProvider) !=
            programDays[DateTime.now().weekday - 1].key;
    final setsN = widget.pe.setsByMonth[widget.month];
    final repsTarget = widget.pe.repsByMonth[widget.month];
    final isKegel = widget.pe.id == 'kegels';
    final measureLabel = widget.pe.unit?.trim() == 's' ? 'seconds' : 'reps';

    // kegels / recovery special cards
    if (isKegel) return _KegelCard(pe: widget.pe, month: widget.month);
    if (ex == null) {
      final special = {
        'recovery-walk':
            'Easy walk, cycle or treadmill at conversational pace for $repsTarget minutes. Stop if dizzy or breathless.',
        'recovery-stretch': 'One gentle mobility round. Hold only comfortable ranges; no need to force a stretch.',
      };
      return Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🌿', style: TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      special[widget.pe.id] ?? widget.pe.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
              if (guide != null) ...[
                const SizedBox(height: 8),
                _EquipmentBlock(guide: guide),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _saved ? T.green : T.indigo,
                  ),
                  onPressed: (_saved || previewOnly)
                      ? null
                      : () async {
                          try {
                            await state.logWorkout(
                              WorkoutLog(
                                date: date,
                                week: state.currentWeek(),
                                day:
                                    programDays[DateTime.now().weekday - 1].key,
                                exercise: widget.pe.id,
                                sets: const [WorkoutSet(1, 0, 1)],
                              ),
                            );
                            if (mounted) setState(() => _saved = true);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Not saved: $e')),
                              );
                            }
                          }
                        },
                  icon: Icon(_saved ? Icons.check : Icons.done_all, size: 16),
                  label: Text(
                    _saved
                        ? 'Optional activity logged'
                        : 'Mark optional complete',
                  ),
                ),
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
                      child: Image.asset(
                        ex.gifAsset,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        gaplessPlayback: true,
                      ),
                    )
                  else
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: T.surface2,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.sports_gymnastics,
                        color: T.indigo,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.pe.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5,
                            height: 1.25,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            for (final m in ex.muscles.take(3))
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: T.indigo.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  m,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFFB9BCFF),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.pe.coachPrescription == null
                          ? 'Start: $setsN sets · $repsTarget${widget.pe.unit ?? ''}'
                          : 'Coach wrote ${widget.pe.coachPrescription} · Start here: $setsN × $repsTarget${widget.pe.unit ?? ''}',
                      style: const TextStyle(
                        color: T.coral,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _saved
                      ? const Icon(Icons.check_circle, color: T.green, size: 20)
                      : const Icon(Icons.unfold_more, color: T.dim, size: 20),
                ],
              ),
              if (widget.pe.coachNote != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (widget.pe.id == 'triceps-unclear' ||
                        (widget.pe.coachLabel?.contains('confirm') ?? false))
                      _StatusPill(label: 'ASK TRAINER', color: T.amber),
                    if (widget.pe.id == 'behind-lat-pulldown')
                      _StatusPill(label: 'SAFER REPLACEMENT', color: T.teal),
                    Text(
                      widget.pe.coachNote!,
                      style: TextStyle(
                        color: T.amber,
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ],
              if (_expanded) ...[
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 10),
                // Keep the media and primary tutorial action stacked on small
                // screens; the old side-by-side row pushed controls off-screen.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final narrow = constraints.maxWidth < 430;
                    final media = ex.gif == null
                        ? const SizedBox.shrink()
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              ex.gifAsset,
                              width: narrow ? double.infinity : 150,
                              height: narrow ? 170 : 150,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          );
                    final tutorial = ex.videoId == null
                        ? Text(
                            'Follow the cues below — every rep controlled.',
                            style: TextStyle(
                              color: T.dim,
                              fontSize: 13,
                              height: 1.35,
                            ),
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: T.coral,
                                    foregroundColor: T.bg,
                                  ),
                                  onPressed: () => showVideoSheet(
                                    context,
                                    widget.pe.name,
                                    ex.videoId!,
                                  ),
                                  icon: const Icon(Icons.play_arrow),
                                  label: const Text('Open tutorial'),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Use the cues below and ask your coach to check your first set.',
                                style: TextStyle(
                                  color: T.dim,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          );
                    if (narrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (ex.gif != null) media,
                          if (ex.gif != null) const SizedBox(height: 10),
                          tutorial,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        if (ex.gif != null) ...[
                          SizedBox(width: 150, child: media),
                          const SizedBox(width: 14),
                        ],
                        Expanded(child: tutorial),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                if (guide != null) ...[
                  _EquipmentBlock(guide: guide),
                  const SizedBox(height: 10),
                ],
                _CuesBlock(
                  title: '✅ Correct form',
                  items: ex.cues,
                  icon: T.green,
                ),
                const SizedBox(height: 8),
                _CuesBlock(
                  title: '⚠️ Never do this',
                  items: ex.mistakes,
                  icon: T.red,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      _restRemaining > 0
                          ? 'Rest $_restCountdown · breathe and reset.'
                          : 'Rest ${_restLabel(widget.pe.restSeconds)} before next set.',
                      style: TextStyle(
                        color: _restRemaining > 0 ? T.teal : T.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.pe.restSeconds > 0)
                      OutlinedButton.icon(
                        onPressed: _startRestTimer,
                        icon: Icon(
                          _restRemaining > 0
                              ? Icons.replay
                              : Icons.timer_outlined,
                          size: 15,
                        ),
                        label: Text(
                          _restRemaining > 0 ? 'Restart' : 'Start rest',
                        ),
                      ),
                  ],
                ),
                // logging area
                const SizedBox(height: 12),
                if (_isWeight) ...[
                  Text(
                    'Log today ($date)',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var i = 0; i < _kg.length; i++) ...[
                    Row(
                      children: [
                        SizedBox(
                          width: 48,
                          child: Text(
                            'Set ${i + 1}',
                            style: TextStyle(color: T.dim, fontSize: 12),
                          ),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _kg[i],
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: const InputDecoration(
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              hintText: 'kg',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _reps[i],
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              hintText: measureLabel,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Start with $setsN sets · ~$repsTarget${widget.pe.unit ?? ''} · ${phaseForWeek(ref.read(selectedWeekProvider)).rir}',
                        style: TextStyle(
                          color: T.dim,
                          fontSize: 12,
                          height: 1.3,
                        ),
                      ),
                      if (widget.pe.coachPrescription != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Trainer target: ${widget.pe.coachPrescription} — do not rush to this volume.',
                          style: TextStyle(
                            color: T.amber,
                            fontSize: 12,
                            height: 1.3,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: _saved ? T.green : T.indigo,
                          ),
                          onPressed: previewOnly
                              ? null
                              : () => _save(state, date),
                          icon: Icon(
                            _saved ? Icons.check : Icons.save_outlined,
                            size: 18,
                          ),
                          label: Text(
                            _saved ? 'Saved for today' : 'Save today\'s sets',
                          ),
                        ),
                      ),
                    ],
                  ),
                ] else
                  Center(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: _saved ? T.green : T.indigo,
                      ),
                      onPressed: previewOnly
                          ? null
                          : () async {
                              try {
                                await state.logWorkout(
                                  WorkoutLog(
                                    date: date,
                                    week: state.currentWeek(),
                                    day: programDays[DateTime.now().weekday - 1]
                                        .key,
                                    exercise: widget.pe.id,
                                    sets: const [WorkoutSet(1, 0, 1)],
                                  ),
                                );
                                if (!context.mounted) return;
                                setState(() => _saved = true);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${widget.pe.name} done'),
                                  ),
                                );
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Not saved: $e')),
                                  );
                                }
                              }
                            },
                      icon: Icon(
                        _saved ? Icons.check : Icons.done_all,
                        size: 16,
                      ),
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

String _shortDay(String key) {
  if (key.length <= 3) return key;
  return key.substring(0, 1).toUpperCase() + key.substring(1, 3);
}

String _restLabel(int seconds) {
  if (seconds <= 0) return 'as needed';
  if (seconds % 60 == 0) return '${seconds ~/ 60} min';
  return '${seconds}s';
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _EquipmentBlock extends StatelessWidget {
  final ExerciseGuide guide;
  const _EquipmentBlock({required this.guide});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: T.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: T.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '🧭 FIND IT + SET IT UP',
            style: TextStyle(
              color: T.indigo,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            guide.equipment,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
          ),
          const SizedBox(height: 3),
          Text(
            guide.findIt,
            style: TextStyle(color: T.dim, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 5),
          Text(
            guide.setup,
            style: TextStyle(
              color: T.text.withValues(alpha: 0.9),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'If busy: ${guide.alternatives.join('  ·  ')}',
            style: TextStyle(color: T.amber, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 6),
          for (final item in guide.checklist)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '• $item',
                style: TextStyle(color: T.dim, fontSize: 11.5),
              ),
            ),
        ],
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
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: T.pink.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.favorite, color: T.pink),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Kegels (pelvic floor)',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
                Text(
                  '3×${pe.repsByMonth[month]}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: T.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              kegelGuide['technique']!.join('\n'),
              style: TextStyle(color: T.dim, fontSize: 12, height: 1.5),
            ),
            const SizedBox(height: 6),
            Text(
              'Month ${month + 1}: ${kegelGuide['months']![month]}',
              style: TextStyle(
                color: T.amber,
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
              ),
            ),
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
  const _CuesBlock({
    required this.title,
    required this.items,
    required this.icon,
  });

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
          Text(
            title,
            style: TextStyle(
              color: icon,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          for (final cue in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '•  ',
                    style: TextStyle(
                      color: icon,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      cue,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: T.text.withValues(alpha: 0.9),
                      ),
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
