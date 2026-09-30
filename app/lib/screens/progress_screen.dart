import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/exercises.dart';
import '../main.dart';
import '../state/app_state.dart';
import '../theme.dart';

class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              const Text(
                'Progress',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              if (state.pendingOps > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: T.amber.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${state.pendingOps} waiting to sync…',
                    style: TextStyle(
                      color: T.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              else
                Icon(Icons.cloud_done_outlined, color: T.green, size: 20),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Every log below is saved on YOUR server. Wrong entry? Edit or delete it.',
            style: TextStyle(color: T.dim, fontSize: 12.5),
          ),
          const SizedBox(height: 14),
          const _CheckinCard(),
          const SizedBox(height: 14),
          const _StreakCalendarCard(),
          const SizedBox(height: 14),
          const _BadgesCard(),
          const SizedBox(height: 14),
          _LogBodyDialog(),
          const SizedBox(height: 14),
          _WeightChartCard(state: state),
          const SizedBox(height: 14),
          _WeeklyVolumeCard(state: state),
          const SizedBox(height: 14),
          const _HistoryCard(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ================= CHECK-IN =================
class _CheckinCard extends ConsumerStatefulWidget {
  const _CheckinCard();

  @override
  ConsumerState<_CheckinCard> createState() => _CheckinCardState();
}

class _CheckinCardState extends ConsumerState<_CheckinCard> {
  int _energy = 0;
  int _sleep = 0; // hours slider
  double _water = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appStateProvider);
    final today = state.todayIso();
    CheckinEntry? done;
    for (final c in state.checkins) {
      if (c.date == today) done = c;
    }
    if (done != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const Icon(Icons.fact_check_outlined, color: T.green),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today\'s check-in done · energy ${done.energy ?? '?'}/5 · '
                  'sleep ${done.sleepHours?.toStringAsFixed(1) ?? '?'}h · water ${done.waterL?.toStringAsFixed(1) ?? '?'}L',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              IconButton(
                tooltip: 'Remove today\'s check-in',
                icon: const Icon(Icons.delete_outline, color: T.red, size: 20),
                onPressed: () => state.deleteCheckinLog(today),
              ),
            ],
          ),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Daily check-in (30 sec)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                Text(
                  'builds discipline',
                  style: TextStyle(color: T.dim, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('Energy today', style: TextStyle(color: T.dim, fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 1; i <= 5; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text('$i'),
                        selected: _energy == i,
                        onSelected: (_) => setState(() => _energy = i),
                        selectedColor: T.indigo,
                        labelStyle: TextStyle(
                          color: _energy == i ? T.bg : T.dim,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sleep: ${_sleep == 0 ? '—' : '$_sleep h'}',
                    style: TextStyle(color: T.dim, fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    'Water: ${_water == 0 ? '—' : '${_water.toStringAsFixed(1)} L'}',
                    style: TextStyle(color: T.dim, fontSize: 12),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: _sleep.toDouble().clamp(0, 12),
                    max: 12,
                    divisions: 12,
                    label: '$_sleep h',
                    onChanged: (v) => setState(() => _sleep = v.round()),
                  ),
                ),
                Expanded(
                  child: Slider(
                    value: _water.clamp(0, 5),
                    max: 5,
                    divisions: 10,
                    label: _water.toStringAsFixed(1),
                    onChanged: (v) => setState(() => _water = v),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: T.green),
                onPressed: _energy == 0 && _sleep == 0 && _water == 0
                    ? null
                    : () async {
                        try {
                          await state.saveCheckin(
                            CheckinEntry(
                              today,
                              _energy == 0 ? null : _energy,
                              _sleep == 0 ? null : _sleep.toDouble(),
                              _water == 0 ? null : _water,
                              null,
                              null,
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Check-in not saved: $e')),
                            );
                          }
                        }
                      },
                icon: const Icon(Icons.check),
                label: const Text('Save today\'s check-in'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= STREAK CALENDAR =================
class _StreakCalendarCard extends ConsumerWidget {
  const _StreakCalendarCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1=Mon
    final cells = <String>{};
    final logs = state.workouts.map((w) => w.date).toSet();
    final checks = state.checkins.map((c) => c.date).toSet();
    // month cell dates
    for (var d = 1; d <= daysInMonth; d++) {
      final day = DateTime(now.year, now.month, d);
      cells.add(
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}',
      );
    }
    final today = state.todayIso();
    final trainedCount = cells.where(logs.contains).length;
    final checkedCount = cells.where(checks.contains).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_monthName(now.month)} ${now.year} — your consistency grid',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _legend(Icons.circle, T.green, 'trained'),
                const SizedBox(width: 12),
                _legend(Icons.circle, T.indigo, 'check-in'),
                const Spacer(),
                Text(
                  'streak: ${state.streak()} day${state.streak() == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: T.pink,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: daysInMonth + firstWeekday - 1,
              itemBuilder: (context, i) {
                if (i < firstWeekday - 1) return const SizedBox.shrink();
                final d = i - firstWeekday + 2;
                final date =
                    '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${d.toString().padLeft(2, '0')}';
                final trained = logs.contains(date);
                final checked = checks.contains(date);
                final isToday = date == today;
                Color bg = T.surface2;
                if (trained) {
                  bg = T.green;
                } else if (checked) {
                  bg = T.indigo;
                }
                if (isToday) bg = T.pink;
                return Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$d',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: (trained || checked || isToday) ? T.bg : T.dim,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 6),
            Text(
              'Trained $trainedCount day${trainedCount == 1 ? '' : 's'} this month · '
              'check-ins $checkedCount — fill the grid, that\'s the habit.',
              style: TextStyle(color: T.dim, fontSize: 11.5),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int m) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m - 1];

  Widget _legend(IconData icon, Color c, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 10, color: c),
      const SizedBox(width: 3),
      Text(label, style: TextStyle(color: T.dim, fontSize: 11)),
    ],
  );
}

// ================= BADGES =================
class _BadgesCard extends ConsumerWidget {
  const _BadgesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final trainedDates = state.workouts.map((w) => w.date).toSet();
    final totalSessions = trainedDates.length;
    final kegelDays = state.kegelLogs.map((k) => k.date).toSet().length;
    final prCount = state.personalRecords().length;

    final badges = <(IconData, Color, String, bool)>[
      (Icons.emoji_events, T.amber, 'First session', totalSessions >= 1),
      (Icons.calendar_month, T.green, '5 sessions', totalSessions >= 5),
      (Icons.workspace_premium, T.indigo, '10 sessions', totalSessions >= 10),
      (Icons.trending_up, T.pink, 'First PR', prCount >= 1),
      (Icons.favorite, T.red, 'Kegel 7-day', kegelDays >= 7),
      (
        Icons.local_fire_department,
        T.amber,
        '3-day streak',
        state.streak() >= 3,
      ),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Milestones',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final b in badges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: b.$4 ? b.$2.withValues(alpha: 0.15) : T.surface2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(b.$1, size: 14, color: b.$4 ? b.$2 : T.dim),
                        const SizedBox(width: 5),
                        Text(
                          b.$3,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: b.$4 ? b.$2 : T.dim,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ================= LOG BODY DIALOG =================
class _LogBodyDialog extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future<void> open() async {
      final st = ref.read(appStateProvider);
      final w = TextEditingController(
        text: st.lastWeight()?.toStringAsFixed(1) ?? '',
      );
      final wa = TextEditingController();
      final ch = TextEditingController();
      final ar = TextEditingController();
      final lastM = st.measurements.isEmpty ? null : st.measurements.last;
      if (lastM != null) {
        wa.text = lastM.waistCm?.toStringAsFixed(1) ?? '';
        ch.text = lastM.chestCm?.toStringAsFixed(1) ?? '';
        ar.text = lastM.armCm?.toStringAsFixed(1) ?? '';
      }
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: T.surface,
          title: const Text('Log body metrics'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: w,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: wa,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Waist (cm)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ch,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Chest (cm)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: ar,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Arm (cm)'),
              ),
              const SizedBox(height: 8),
              Text(
                'Measure weekly, same tape position, relaxed. '
                'If your tape shows inches, multiply by 2.54 to get cm.',
                style: TextStyle(color: T.dim, fontSize: 11),
              ),
            ],
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
      if (ok == true) {
        final date = st.todayIso();
        final kg = double.tryParse(w.text.trim());
        final waist = double.tryParse(wa.text.trim());
        final chest = double.tryParse(ch.text.trim());
        final arm = double.tryParse(ar.text.trim());
        if (kg == null && waist == null && chest == null && arm == null) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Enter at least one measurement.')),
            );
          }
          return;
        }
        try {
          if (kg != null) await st.logWeight(date, kg);
          if (waist != null || chest != null || arm != null) {
            await st.logMeasurements(MeasurementEntry(date, waist, chest, arm));
          }
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  st.pendingCount > 0
                      ? 'Saved locally · ${st.pendingCount} changes waiting to sync'
                      : 'Saved successfully',
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Not saved: $e')));
          }
        }
      }
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: open,
        style: FilledButton.styleFrom(
          backgroundColor: T.surface2,
          foregroundColor: T.text,
          side: const BorderSide(color: T.border),
        ),
        icon: const Icon(Icons.straighten, size: 18),
        label: const Text('Log weight + measurements'),
      ),
    );
  }
}

class _WeightChartCard extends StatelessWidget {
  final AppState state;
  const _WeightChartCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final data = state.bodyWeight;
    if (data.length < 2) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Body weight trend appears after 2+ entries (log daily, same time, after waking).',
            style: TextStyle(color: T.dim),
          ),
        ),
      );
    }
    final recent = data.length > 40 ? data.sublist(data.length - 40) : data;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Body weight (kg)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY:
                      (recent.map((e) => e.kg).reduce((a, b) => a < b ? a : b) -
                              2)
                          .floorToDouble(),
                  maxY:
                      (recent.map((e) => e.kg).reduce((a, b) => a > b ? a : b) +
                              2)
                          .ceilToDouble(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: T.border, strokeWidth: 0.6),
                  ),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                      ),
                    ),
                    topTitles: AxisTitles(),
                    rightTitles: AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (var i = 0; i < recent.length; i++)
                          FlSpot(i.toDouble(), recent[i].kg),
                      ],
                      color: T.indigo,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          colors: [
                            T.indigo.withValues(alpha: 0.25),
                            T.indigo.withValues(alpha: 0.02),
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

class _WeeklyVolumeCard extends StatelessWidget {
  final AppState state;
  const _WeeklyVolumeCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final perWeek = List<double>.filled(12, 0);
    for (final l in state.workouts) {
      final w = l.week;
      if (w == null || w < 1 || w > 12) continue;
      var v = 0.0;
      if (l.exercise == 'farmers-walk') continue; // seconds are not repetitions
      for (final s in l.sets) {
        v += s.weightKg * s.reps;
      }
      perWeek[w - 1] += v;
    }
    if (perWeek.every((v) => v == 0)) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Volume chart appears when you log weight-based lifts (kg × reps per set).',
            style: TextStyle(color: T.dim),
          ),
        ),
      );
    }
    final maxV = perWeek.reduce((a, b) => a > b ? a : b);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Lifting volume per week (kg × reps; excludes timed carries)',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 150,
              child: BarChart(
                BarChartData(
                  maxY: maxV * 1.15,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: const FlTitlesData(
                    leftTitles: AxisTitles(),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 20,
                        interval: 1,
                      ),
                    ),
                    topTitles: AxisTitles(),
                    rightTitles: AxisTitles(),
                  ),
                  barGroups: [
                    for (var i = 0; i < 12; i++)
                      BarChartGroupData(
                        x: i + 1,
                        barRods: [
                          BarChartRodData(
                            toY: perWeek[i],
                            width: 7,
                            color: perWeek[i] == maxV && maxV > 0
                                ? T.pink
                                : T.indigo,
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(3),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Volume is one signal, not a weekly target. Recovery and good form come first.',
              style: TextStyle(color: T.dim, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

// ================= HISTORY (edit / delete) =================
class _HistoryCard extends ConsumerWidget {
  const _HistoryCard();

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String what,
    Future<void> Function() del,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text('Delete $what?'),
        content: const Text(
          'This removes it from your server database. '
          'You can log it again later if it was a mistake.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: T.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      try {
        await del();
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Removed: $what')));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appStateProvider);
    final workouts = [...state.workouts]
      ..sort((a, b) => b.date.compareTo(a.date));
    final weights = [...state.bodyWeight.reversed];
    final kegels = state.kegelLogs.take(20).toList();
    if (workouts.isEmpty && weights.isEmpty && kegels.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Nothing logged yet. Workout history with edit/delete appears here '
            'the moment you save your first sets.',
            style: TextStyle(color: T.dim),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Your log book (server copy)',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => state.refreshState(),
                  icon: const Icon(Icons.refresh, size: 16),
                  label: const Text('Refresh'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Delete a logged entry below. To change today\'s sets, save them again in Workout.',
              style: TextStyle(color: T.dim, fontSize: 11.5),
            ),
            const SizedBox(height: 8),
            for (final w in workouts.take(12))
              _WorkoutRow(
                w: w,
                onDelete: () => _confirmDelete(
                  context,
                  ref,
                  '${w.exercise} (${w.date})',
                  () => state.deleteWorkoutLog(w.date, w.exercise),
                ),
              ),
            for (final wt in weights.take(7))
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.monitor_weight_outlined,
                  color: T.indigo,
                  size: 18,
                ),
                title: Text(
                  '${wt.date}  ·  ${wt.kg.toStringAsFixed(1)} kg',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: T.red,
                    size: 18,
                  ),
                  onPressed: () => _confirmDelete(
                    context,
                    ref,
                    'weight ${wt.date}',
                    () => state.deleteWeightLog(wt.date),
                  ),
                ),
              ),
            for (final k in kegels)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.favorite_outline,
                  color: T.pink,
                  size: 18,
                ),
                title: Text(
                  '${k.date}  ·  ${k.sets} recorded holds/sets × ${k.holdSeconds}s',
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: T.amber,
                        size: 18,
                      ),
                      tooltip: 'Edit',
                      onPressed: () => _editKegel(context, ref, k),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: T.red,
                        size: 18,
                      ),
                      onPressed: () => _confirmDelete(
                        context,
                        ref,
                        'kegel log',
                        () => state.deleteKegelLog(k.id),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editKegel(
    BuildContext context,
    WidgetRef ref,
    KegelEntry k,
  ) async {
    final st = ref.read(appStateProvider);
    final sets = TextEditingController(text: '${k.sets}');
    final hold = TextEditingController(text: '${k.holdSeconds}');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: T.surface,
        title: Text('Edit kegel log (${k.date})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: sets,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Recorded holds/sets',
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: hold,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Hold seconds'),
            ),
          ],
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
    if (ok == true) {
      final sv = int.tryParse(sets.text.trim());
      final hv = int.tryParse(hold.text.trim());
      if (sv != null && hv != null) {
        try {
          await st.editKegelLog(k.id, sv, hv);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Pelvic-floor log updated')),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text('Update failed: $e')));
          }
        }
      }
    }
  }
}

class _WorkoutRow extends StatelessWidget {
  final WorkoutLog w;
  final VoidCallback onDelete;
  const _WorkoutRow({required this.w, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final ex = exercises[w.exercise];
    final total = w.sets.fold<int>(0, (a, s) => a + s.reps);
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        ex?.gif != null || ex != null
            ? Icons.fitness_center
            : Icons.self_improvement,
        color: T.indigo,
        size: 18,
      ),
      title: Text(
        '${w.date} · ${ex?.name ?? w.exercise}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        w.sets.isEmpty
            ? 'marked done'
            : w.sets
                  .map(
                    (s) => w.exercise == 'farmers-walk'
                        ? '${s.weightKg.toStringAsFixed(0)}kg × ${s.reps}s'
                        : '${s.weightKg.toStringAsFixed(0)}kg × ${s.reps} reps',
                  )
                  .join('  '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: T.dim, fontSize: 11),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            w.exercise == 'farmers-walk' ? '$total sec' : '$total reps',
            style: TextStyle(color: T.dim, fontSize: 11),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: T.red, size: 18),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
