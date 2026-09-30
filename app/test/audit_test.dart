import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ironforge/data/program.dart';
import 'package:ironforge/services/api.dart';
import 'package:ironforge/state/app_state.dart';

void main() {
  AppState state() => AppState(Api(Dio()));

  test('program dates and phase labels reflect the actual state', () {
    final s = state();
    expect(s.currentWeek(), 1);
    s.startDate = '2026-09-21';
    expect(s.programEndDate(), '2026-12-13');
    expect(phaseForWeek(1).name, contains('Learn'));
    expect(phaseForWeek(5).name, contains('Build'));
    expect(phaseForWeek(9).name, contains('Progress'));
  });

  test('heatmap distinguishes kegel-only from all three activities', () {
    final s = state();
    const date = '2026-09-28';
    const other = '2026-09-29';
    s.kegelLogs.add(const KegelEntry(1, date, 1, 3));
    s.kegelLogs.add(const KegelEntry(2, other, 1, 3));
    s.workouts.add(
      WorkoutLog(
        date: date,
        exercise: 'goblet-squat',
        sets: const [WorkoutSet(1, 10, 10)],
      ),
    );
    s.checkins.add(const CheckinEntry(date, 4, 8, 2, null, null));
    expect(s.heatmapCells()[date], 4);
    expect(s.heatmapCells()[other], 1);
  });

  test('one lift or recovery activity is not a completed strength session', () {
    final s = state();
    final monday = DateTime(2026, 9, 28);
    s.workouts.add(
      WorkoutLog(
        date: '2026-09-28',
        exercise: 'recovery-walk',
        sets: const [WorkoutSet(1, 0, 1)],
      ),
    );
    s.workouts.add(
      WorkoutLog(
        date: '2026-09-28',
        exercise: 'goblet-squat',
        sets: const [WorkoutSet(1, 10, 10)],
      ),
    );
    expect(s.strengthSessionCompleted(monday), isFalse);
    for (final id in ['dumbbell-bench-press', 'lat-pulldown']) {
      s.workouts.add(
        WorkoutLog(
          date: '2026-09-28',
          exercise: id,
          sets: const [WorkoutSet(1, 10, 10)],
        ),
      );
    }
    expect(s.strengthSessionCompleted(monday), isTrue);
    expect(s.strengthSessionCompleted(DateTime(2026, 9, 29)), isFalse);
  });

  test('carry time is not included in kg x repetitions volume', () {
    final s = state();
    const date = '2026-09-28';
    s.workouts.add(
      WorkoutLog(
        date: date,
        exercise: 'farmers-walk',
        sets: const [WorkoutSet(1, 20, 30)],
      ),
    );
    s.workouts.add(
      WorkoutLog(
        date: date,
        exercise: 'goblet-squat',
        sets: const [WorkoutSet(1, 10, 8)],
      ),
    );
    expect(s.volumeForDate(date), 80);
  });
}
