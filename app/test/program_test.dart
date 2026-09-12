import 'package:flutter_test/flutter_test.dart';
import 'package:ironforge/data/exercises.dart';
import 'package:ironforge/data/program.dart';

void main() {
  test('every program exercise exists in the catalog', () {
    for (final day in programDays) {
      for (final pe in day.items) {
        final special = {'kegels', 'recovery-walk', 'recovery-stretch'};
        if (special.contains(pe.id)) continue;
        expect(exercises.containsKey(pe.id), isTrue,
            reason: 'missing catalog entry for ${pe.id} on ${day.key}');
      }
    }
  });

  test('every weight-based exercise has a catalog entry with media', () {
    for (final id in weightBasedIds) {
      final ex = exercises[id];
      expect(ex, isNotNull, reason: 'missing exercise $id');
      expect(ex!.gif != null || ex.videoId != null, isTrue,
          reason: '$id has neither gif nor video');
    }
  });

  test('all 12 weeks map to 3 months', () {
    expect(monthForWeek(1), 0);
    expect(monthForWeek(4), 0);
    expect(monthForWeek(5), 1);
    expect(monthForWeek(8), 1);
    expect(monthForWeek(9), 2);
    expect(monthForWeek(12), 2);
  });

  test('sets/reps defined for all three months', () {
    for (final day in programDays) {
      for (final pe in day.items) {
        expect(pe.setsByMonth.length, 3, reason: pe.id);
        expect(pe.repsByMonth.length, 3, reason: pe.id);
        for (final s in pe.setsByMonth) {
          expect(s, inInclusiveRange(0, 6), reason: pe.id);
        }
      }
    }
  });

  test('program has rest day on sunday and training mon-sat', () {
    expect(programDays.length, 7);
    expect(programDays[6].restDay, isTrue);
    for (var i = 0; i < 6; i++) {
      expect(programDays[i].restDay, isFalse);
      expect(programDays[i].items, isNotEmpty);
    }
  });
}
