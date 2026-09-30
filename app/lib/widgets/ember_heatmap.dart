import 'package:flutter/material.dart';

import '../theme.dart';

/// GitHub-style consistency heatmap, single-hue ember ramp.
///
/// One cell per day, 7 rows (Mon..Sun) × N weeks, oldest → newest left→right.
/// Intensity is INFORMATION, not decoration: 0 = nothing, up to 4 = trained +
/// checked in + kegels. This replaces the fragile "streak resets to zero"
/// shame-loop with an honest history (research: habit-heatmap best practice).
class EmberHeatmap extends StatelessWidget {
  /// Map of 'YYYY-MM-DD' → intensity 0..4. Days missing = 0.
  final Map<String, int> cells;

  /// Weeks of history to show (default 13 = one full program).
  final int weeks;

  const EmberHeatmap({super.key, required this.cells, this.weeks = 13});

  static String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    // Build the grid: columns = weeks, rows = Mon..Sun.
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    // Start on the Monday `weeks-1` weeks before this week's Monday.
    final thisMonday = todayOnly.subtract(
      Duration(days: todayOnly.weekday - 1),
    );
    final start = thisMonday.subtract(Duration(days: 7 * (weeks - 1)));

    return LayoutBuilder(
      builder: (context, c) {
        const rows = 7;
        const gap = 3.0;
        final cell = ((c.maxWidth - gap * (weeks - 1)) / weeks).floorToDouble();
        final size = cell.clamp(6.0, 18.0);
        return SizedBox(
          height: rows * size + gap * (rows - 1),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(weeks, (w) {
              final colStart = start.add(Duration(days: w * 7));
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(rows, (r) {
                  final day = colStart.add(Duration(days: r));
                  final future = day.isAfter(todayOnly);
                  final v = future ? -1 : (cells[_iso(day)] ?? 0);
                  final isToday = day == todayOnly;
                  return Container(
                    width: size,
                    height: size,
                    margin: EdgeInsets.only(
                      bottom: r == rows - 1 ? 0 : gap,
                      right: w == weeks - 1 ? 0 : gap,
                    ),
                    decoration: BoxDecoration(
                      color: future
                          ? Colors.transparent
                          : T.streakRamp[v.clamp(0, 4)],
                      borderRadius: BorderRadius.circular(size * 0.22),
                      border: isToday
                          ? Border.all(color: T.ember, width: 1.2)
                          : future
                          ? Border.all(
                              color: T.border.withValues(alpha: 0.4),
                              width: 0.5,
                            )
                          : null,
                    ),
                  );
                }),
              );
            }),
          ),
        );
      },
    );
  }
}

/// The streak hero — big glanceable numeral + flame, gym-floor readable.
/// No gradients-as-decoration; a radial ember glow behind the numeral is the
/// only "art", and it IS the streak: the hotter the streak, the hotter the glow.
class StreakHero extends StatelessWidget {
  final int streakDays;
  final int bestStreak;
  const StreakHero({
    super.key,
    required this.streakDays,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
    final active = streakDays > 0;
    // Glow scales with streak (caps at 30 days) — the streak IS the art.
    final heat = (streakDays / 30).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: T.border, width: 1),
      ),
      child: Row(
        children: [
          // Ember glow + numeral
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: active
                    ? [
                        T.ember.withValues(alpha: 0.35 + heat * 0.45),
                        T.emberDeep.withValues(alpha: 0.15),
                        Colors.transparent,
                      ]
                    : [T.surface3.withValues(alpha: 0.5), Colors.transparent],
                stops: active ? const [0.0, 0.55, 1.0] : const [0.0, 1.0],
              ),
            ),
            child: Center(
              child: Text(
                '$streakDays',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  height: 1,
                  color: active ? T.ember : T.faint,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  active ? 'strength-session streak' : 'no streak yet',
                  style: TextStyle(
                    color: active ? T.text : T.dim,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  active
                      ? 'Required sessions in a row. Best: $bestStreak sessions.'
                      : 'Log a full strength session to start a streak.',
                  style: const TextStyle(
                    color: T.dim,
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
