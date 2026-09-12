/// IronForge 12-week program — derived from knowledge/01-training-program.md.
library;

import 'exercises.dart';

class ProgramExercise {
  final String id; // key into exercises catalog
  final List<int> setsByMonth; // [M1, M2, M3]
  final List<String> repsByMonth; // ["10", "8", "6"] (reps per set)
  final String? unit; // '' = reps · 's' = seconds · '/side' etc.

  const ProgramExercise(this.id, this.setsByMonth, this.repsByMonth, {this.unit});

  String get name => exercises[id]?.name ?? id;
}

class ProgramDay {
  final String key; // monday..sunday
  final String title;
  final String focus;
  final String emoji;
  final List<ProgramExercise> items;
  final bool restDay;

  const ProgramDay(this.key, this.title, this.focus, this.emoji, this.items,
      {this.restDay = false});
}

class Phase {
  final String name;
  final String rir;
  final String description;

  const Phase(this.name, this.rir, this.description);
}

const phases = [
  Phase('Month 1 · Foundation', '3 RIR',
      'Learn perfect form with light weights. Stop with 3 good reps left in the tank.'),
  Phase('Month 2 · Development', '2 RIR',
      'Progressive overload: add reps or small weight. Stop with 2 good reps left.'),
  Phase('Month 3 · Push', '1 RIR',
      'Heaviest 6-8 rep work. Last set of small exercises may reach failure.'),
];

int monthForWeek(int week) {
  if (week <= 4) return 0;
  if (week <= 8) return 1;
  return 2;
}

Phase phaseForWeek(int week) => phases[monthForWeek(week)];

const programDays = <ProgramDay>[
  ProgramDay('monday', 'Upper Push', 'Chest · Shoulders · Triceps', '🔺', [
    ProgramExercise('bench-press', [3, 3, 4], ['10', '8', '6']),
    ProgramExercise('overhead-press', [3, 3, 4], ['10', '8', '6']),
    ProgramExercise('incline-dumbbell-press', [3, 3, 3], ['12', '10', '8']),
    ProgramExercise('tricep-pushdown', [3, 3, 3], ['15', '12', '10']),
    ProgramExercise('lateral-raise', [3, 3, 3], ['15', '12', '12']),
  ]),
  ProgramDay('tuesday', 'Lower Body', 'Quads · Hamstrings · Glutes · Calves', '🦵', [
    ProgramExercise('back-squat', [3, 3, 4], ['10', '8', '6']),
    ProgramExercise('romanian-deadlift', [3, 3, 3], ['10', '8', '8']),
    ProgramExercise('leg-press', [3, 3, 3], ['12', '10', '8']),
    ProgramExercise('lying-leg-curl', [3, 3, 3], ['12', '10', '10']),
    ProgramExercise('standing-calf-raise', [3, 3, 4], ['15', '15', '12']),
  ]),
  ProgramDay('wednesday', 'Pull / Back', 'Back · Biceps · Rear Delts (posture day)', '🏋️', [
    ProgramExercise('deadlift', [3, 3, 4], ['8', '6', '5']),
    ProgramExercise('bent-over-row', [3, 3, 3], ['10', '8', '8']),
    ProgramExercise('lat-pulldown', [3, 3, 3], ['12', '10', '8']),
    ProgramExercise('face-pull', [3, 3, 3], ['15', '15', '12']),
    ProgramExercise('bicep-curl', [3, 3, 3], ['12', '10', '10']),
  ]),
  ProgramDay('thursday', 'Core + Mobility + Kegels', 'Stability · Posture · Flexibility', '🧘', [
    ProgramExercise('plank', [3, 3, 3], ['20', '30', '45'], unit: 's'),
    ProgramExercise('dead-bug', [3, 3, 3], ['8', '10', '12'], unit: '/side'),
    ProgramExercise('bird-dog', [3, 3, 3], ['8', '10', '12'], unit: '/side'),
    ProgramExercise('kegels', [3, 3, 3], ['10', '10', '12'], unit: 'holds'),
    ProgramExercise('hip-flexor-lunge', [1, 1, 2], ['30s', '30s', '30s'], unit: '/side'),
    ProgramExercise('doorway-chest', [1, 1, 2], ['30s', '30s', '30s'], unit: '/side'),
    ProgramExercise('cat-cow', [1, 1, 2], ['10', '10', '10'], unit: 'reps'),
    ProgramExercise('thread-needle', [1, 1, 2], ['8', '8', '8'], unit: '/side'),
    ProgramExercise('worlds-greatest', [1, 1, 2], ['5', '5', '5'], unit: '/side'),
    ProgramExercise('neck-tilts', [1, 1, 2], ['20s', '20s', '20s'], unit: '/side'),
  ]),
  ProgramDay('friday', 'Full Body Compounds', 'Squat · Press · Row · Carry', '⚡', [
    ProgramExercise('goblet-squat', [3, 0, 0], ['12', '8', '6']), // M1 goblet
    ProgramExercise('front-squat', [0, 3, 4], ['8', '8', '6']), // M2-3 front squat
    ProgramExercise('dumbbell-bench-press', [3, 3, 3], ['12', '10', '8']),
    ProgramExercise('single-arm-row', [3, 3, 3], ['10', '8', '8'], unit: '/arm'),
    ProgramExercise('dumbbell-overhead-press', [3, 3, 3], ['10', '8', '8']),
    ProgramExercise('farmers-walk', [3, 3, 3], ['30', '40', '50'], unit: 's'),
  ]),
  ProgramDay('saturday', 'Active Recovery', 'Light cardio · Stretch · Foam roll', '🌿', [
    ProgramExercise('recovery-walk', [1, 1, 1], ['20', '20', '20'], unit: 'min'),
    ProgramExercise('recovery-stretch', [1, 1, 1], ['1', '1', '1'], unit: 'round'),
  ]),
  ProgramDay('sunday', 'REST', 'Gym closed — sleep, eat, recover', '😴', const [],
      restDay: true),
];

/// Exercises marked with a loggable kg weight vs. time/bodyweight only.
const weightBasedIds = {
  'bench-press', 'overhead-press', 'incline-dumbbell-press', 'tricep-pushdown',
  'lateral-raise', 'dumbbell-bench-press', 'dumbbell-overhead-press',
  'back-squat', 'goblet-squat', 'front-squat', 'romanian-deadlift', 'leg-press',
  'lying-leg-curl', 'standing-calf-raise', 'deadlift', 'bent-over-row',
  'lat-pulldown', 'face-pull', 'bicep-curl', 'single-arm-row', 'farmers-walk',
};

/// Kegel sub-guide used by Thursday + the kegel tracker screen.
const kegelGuide = {
  'setup': [
    'Empty your bladder first',
    'Lie down initially — easiest position',
    'Find the muscle: next time you pee, stop the flow ONCE. That is it.',
  ],
  'technique': [
    'Squeeze ONLY the pelvic floor — abs, glutes, thighs stay relaxed',
    'Hold 3-5s, then FULLY relax 3-5s (relaxation is half the exercise)',
    'Breathe normally the whole time',
  ],
  'months': [
    'Month 1: 3 sets x 10 · 3s holds · 3s relax (3x/day: morning/noon/night)',
    'Month 2: 3 sets x 10 · 5s holds · 5s relax',
    'Month 3: 3 sets x 12 · 8s holds · 8s relax',
  ],
  'mistakes': [
    'Squeezing abs/butt/thighs instead — hand on belly, it must stay soft',
    'Holding your breath',
    'Overdoing it — pelvic pain/urgency means 2-3 days off and reduce',
    'Expecting instant results — 6-8 weeks minimum',
  ],
};
