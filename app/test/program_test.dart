import 'package:flutter_test/flutter_test.dart';
import 'package:ironforge/data/diet_database.dart';
import 'package:ironforge/data/exercises.dart';
import 'package:ironforge/data/exercise_guides.dart';
import 'package:ironforge/data/program.dart';

void main() {
  test('every displayed plan exercise exists in the catalog', () {
    for (final day in [...programDays, ...coachPlanDays]) {
      for (final pe in day.items) {
        if ({'recovery-walk', 'recovery-stretch', 'kegels'}.contains(pe.id)) {
          continue;
        }
        expect(
          exercises.containsKey(pe.id),
          isTrue,
          reason: 'missing catalog entry for ${pe.id} on ${day.key}',
        );
      }
    }
  });

  test('every program exercise exists in the catalog', () {
    for (final day in programDays) {
      for (final pe in day.items) {
        final special = {'kegels', 'recovery-walk', 'recovery-stretch'};
        if (special.contains(pe.id)) {
          continue;
        }
        expect(
          exercises.containsKey(pe.id),
          isTrue,
          reason: 'missing catalog entry for ${pe.id} on ${day.key}',
        );
      }
    }
  });

  test(
    'every weight-based exercise has a catalog entry with media and a guide',
    () {
      for (final id in weightBasedIds) {
        final ex = exercises[id];
        expect(ex, isNotNull, reason: 'missing exercise $id');
        expect(
          ex!.gif != null || ex.videoId != null,
          isTrue,
          reason: '$id has neither gif nor video',
        );
        expect(
          guideForExercise(id),
          isNotNull,
          reason: '$id has no equipment guide',
        );
      }
    },
  );

  test('all 12 weeks map to 3 months', () {
    expect(monthForWeek(1), 0);
    expect(monthForWeek(4), 0);
    expect(monthForWeek(5), 1);
    expect(monthForWeek(8), 1);
    expect(monthForWeek(9), 2);
    expect(monthForWeek(12), 2);
  });

  test(
    'sets/reps defined for all three months and no zero-set placeholders',
    () {
      for (final day in programDays) {
        for (final pe in day.items) {
          expect(pe.setsByMonth.length, 3, reason: pe.id);
          expect(pe.repsByMonth.length, 3, reason: pe.id);
          for (final s in pe.setsByMonth) {
            expect(s, inInclusiveRange(1, 6), reason: pe.id);
          }
        }
      }
    },
  );

  test('food search and budget calculator are typed Dart data', () {
    expect(searchFood('soy'), isNotEmpty);
    final plan = calculateBudget();
    expect(plan.items, isNotEmpty);
    expect(plan.totalCostInr, lessThanOrEqualTo(plan.targetInr));
    expect(plan.totalProteinGrams, greaterThan(0));
  });

  test(
    'coach plan preserves the trainer split and marks unsafe/unclear names',
    () {
      expect(
        coachPlanDays.map((d) => d.title),
        containsAll(<String>[
          'Coach plan · Chest',
          'Coach plan · Shoulders',
          'Coach plan · Back',
          'Coach plan · Biceps',
          'Coach plan · Triceps',
          'Coach plan · Legs',
        ]),
      );
      final back = coachPlanDays.firstWhere((d) => d.key == 'wednesday');
      expect(
        back.items.any(
          (x) =>
              x.id == 'behind-lat-pulldown' &&
              x.coachNote!.contains('never behind'),
        ),
        isTrue,
      );
      final triceps = coachPlanDays.firstWhere((d) => d.key == 'friday');
      expect(
        triceps.items.any(
          (x) => x.id == 'triceps-unclear' && x.coachLabel!.contains('clarify'),
        ),
        isTrue,
      );
      for (final day in coachPlanDays.take(6)) {
        for (final item in day.items) {
          expect(
            item.setsByMonth.first,
            lessThanOrEqualTo(1),
            reason: item.name,
          );
        }
      }
    },
  );

  test('program has three required strength days and optional movement', () {
    expect(programDays.length, 7);
    expect(programDays[6].restDay, isTrue);
    expect(
      programDays.where((d) => !d.restDay && !d.optional).map((d) => d.key),
      containsAll(<String>['monday', 'wednesday', 'friday']),
    );
    expect(programDays[4].title, 'Full Body C');
    expect(
      programDays[4].items.map((x) => x.id),
      containsAll(<String>['bench-press', 'single-arm-row', 'face-pull']),
    );
    for (final day in programDays.take(6)) {
      expect(day.restDay, isFalse);
      expect(day.items, isNotEmpty);
    }
  });
}
