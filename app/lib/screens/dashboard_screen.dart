import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/program.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../widgets/ember_heatmap.dart';
import '../widgets/kegel_sheet.dart';
import 'home_shell.dart';
import 'workout_screen.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  ProgramDay _todayDay() {
    final wd = DateTime.now().weekday; // 1=Mon..7=Sun
    return coachPlanDays[wd - 1];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final week = state.currentWeek();
    final phase = phaseForWeek(week);
    final today = _todayDay();
    final todayIso = state.todayIso();

    final logsThisWeek = _logsForWeek(state);
    final weekDaysLogged = logsThisWeek.length;
    final requiredSessions = programDays
        .where((d) => !d.restDay && !d.optional)
        .length;
    final weekProgress = (weekDaysLogged / requiredSessions).clamp(0.0, 1.0);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'IronForge',
                    style: TextStyle(
                      color: T.dim,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Week $week of 12 · ${phase.name}',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              _Avatar(),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            phase.rir,
            style: TextStyle(color: T.ember, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            phase.description,
            style: TextStyle(color: T.dim, fontSize: 12.5, height: 1.4),
          ),
          if (state.startDate.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Started ${state.startDate} · Week 1 = that date · '
                'program ends ${state.programEndDate()} (12 weeks). '
                'Wrong start day? Set it in Settings.',
                style: TextStyle(color: T.dim, fontSize: 11, height: 1.4),
              ),
            ),
          const SizedBox(height: 18),

          // Today's session
          if (!today.restDay)
            GestureDetector(
              onTap: () {
                ref.read(navIndexProvider.notifier).state = 1;
                ref.read(selectedDayProvider.notifier).state = today.key;
              },
              child: GradientCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${today.emoji}  TODAY · ${today.title}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 17,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      today.focus,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      today.optional
                          ? (state.dayCompleted(todayIso)
                                ? 'Optional movement logged ✓'
                                : 'Optional easy movement · no pressure')
                          : state.strengthSessionCompleted(DateTime.now())
                          ? 'Strength session completed ✓'
                          : state.dayCompleted(todayIso)
                          ? 'Session in progress · continue when ready'
                          : '${today.items.length} exercises · start with a light set',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Text('😴', style: TextStyle(fontSize: 28)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sunday — REST DAY. Gym closed. Sleep 8h, eat well, '
                        'let the muscles you trained this week grow.',
                        style: TextStyle(color: T.dim, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_missedYesterday(state)) const _MissedNudge(),
          const SizedBox(height: 14),

          // ── The streak IS the art ─────────────────────────────
          StreakHero(
            streakDays: state.streak(),
            bestStreak: state.bestStreak(),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '13-week consistency',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Mon · today',
                        style: TextStyle(color: T.dim, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  EmberHeatmap(cells: state.heatmapCells()),
                  const SizedBox(height: 10),
                  Text(
                    'trained · check-in · kegels',
                    style: TextStyle(color: T.dim, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // stats row
          Row(
            children: [
              _StatCard(
                icon: Icons.local_fire_department,
                value: '${state.streak()}',
                label: 'day streak',
              ),
              _StatCard(
                icon: Icons.monitor_weight_outlined,
                value: state.lastWeight() == null
                    ? '—'
                    : '${state.lastWeight()!.toStringAsFixed(1)} kg',
                label: 'last weight',
              ),
              _StatCard(
                icon: Icons.emoji_events_outlined,
                value: '${state.personalRecords().length}',
                label: 'personal records',
              ),
            ],
          ),
          const SizedBox(height: 14),

          // week progress bar
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'This week',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '$weekDaysLogged / $requiredSessions completed strength sessions',
                        style: TextStyle(color: T.dim, fontSize: 13),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: weekProgress,
                      minHeight: 8,
                      backgroundColor: T.surface2,
                      valueColor: const AlwaysStoppedAnimation(T.ember),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Strength sessions: ${logsThisWeek.join(', ').isEmpty ? 'none yet' : logsThisWeek.join(', ')} · optional cardio is extra',
                    style: TextStyle(color: T.dim, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          _WeightChart(state: state),
          const SizedBox(height: 14),

          _QuickActions(state: state),
          const SizedBox(height: 20),
          Center(
            child: Text(
              'Form rule: film your last heavy set weekly · '
              'sharp joint pain = stop (knowledge/09)',
              textAlign: TextAlign.center,
              style: TextStyle(color: T.dim, fontSize: 11, height: 1.5),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  List<String> _logsForWeek(AppState state) {
    final dates = <String>[];
    final start = DateTime.now().subtract(
      Duration(days: DateTime.now().weekday - 1),
    );
    for (var i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      final day = programDays[d.weekday - 1];
      if (day.restDay || day.optional) continue;
      if (state.strengthSessionCompleted(d)) {
        dates.add(day.title);
      }
    }
    return dates;
  }
}

class _Avatar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: const BoxDecoration(
        gradient: T.gradient,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.person, color: Colors.white, size: 22),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: T.indigo, size: 20),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              Text(label, style: TextStyle(color: T.dim, fontSize: 10.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightChart extends ConsumerWidget {
  final AppState state;
  const _WeightChart({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = state.bodyWeight;
    if (data.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Body weight',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                'Log your weight daily (same time, after waking) and it charts here.',
                style: TextStyle(color: T.dim, fontSize: 12.5),
              ),
            ],
          ),
        ),
      );
    }
    final recent = data.length > 30 ? data.sublist(data.length - 30) : data;
    final spots = [
      for (var i = 0; i < recent.length; i++)
        FlSpot(i.toDouble(), recent[i].kg),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Body weight trend',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  '${recent.first.kg.toStringAsFixed(1)} → ${recent.last.kg.toStringAsFixed(1)} kg',
                  style: TextStyle(color: T.dim, fontSize: 12),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 130,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(),
                    topTitles: AxisTitles(),
                    rightTitles: AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: T.pink,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            T.pink.withValues(alpha: 0.25),
                            T.pink.withValues(alpha: 0.02),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActions extends ConsumerWidget {
  final AppState state;
  const _QuickActions({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> logWeight() async {
      final kgController = TextEditingController(
        text: state.lastWeight()?.toStringAsFixed(1) ?? '',
      );
      final saved = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: T.surface,
          title: const Text('Log body weight'),
          content: TextField(
            controller: kgController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Weight (kg)'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: T.indigo),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (saved == true) {
        final v = double.tryParse(kgController.text.trim());
        if (v == null || v < 20 || v > 400) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Enter a valid weight between 20 and 400 kg.'),
              ),
            );
          }
          return;
        }
        try {
          await state.logWeight(state.todayIso(), v);
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Weight not saved: $e')));
          }
        }
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 380;
        final buttons = [
          OutlinedButton.icon(
            onPressed: logWeight,
            style: OutlinedButton.styleFrom(
              foregroundColor: T.text,
              side: const BorderSide(color: T.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.monitor_weight_outlined, size: 18),
            label: const Text('Log weight'),
          ),
          OutlinedButton.icon(
            onPressed: () => _openKegelQuickLog(context, ref),
            style: OutlinedButton.styleFrom(
              foregroundColor: T.text,
              side: const BorderSide(color: T.border),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            icon: const Icon(Icons.timer_outlined, size: 18),
            label: const Text('Kegel session'),
          ),
        ];
        if (narrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [buttons[0], const SizedBox(height: 8), buttons[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: buttons[0]),
            const SizedBox(width: 10),
            Expanded(child: buttons[1]),
          ],
        );
      },
    );
  }

  Future<void> _openKegelQuickLog(BuildContext context, WidgetRef ref) async {
    await showKegelSheet(context, ref);
  }
}

bool _missedYesterday(AppState state) {
  final y = DateTime.now().subtract(const Duration(days: 1));
  if (y.weekday == DateTime.sunday) return false;
  final day = programDays[y.weekday - 1];
  if (day.optional || day.restDay) return false;
  return !state.strengthSessionCompleted(y);
}

class _MissedNudge extends ConsumerWidget {
  const _MissedNudge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: T.amber.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: T.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.tips_and_updates_outlined, color: T.amber, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Yesterday\'s required session was not logged. No make-up sets needed — '
              'resume with today\'s planned session and keep the weight comfortable.',
              style: const TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
