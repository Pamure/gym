/// IronForge beginner program: three simple full-body strength sessions plus
/// optional low-intensity movement. The coach's six-day body-part split remains
/// documented in knowledge/01-training-program.md as a comparison, but this is
/// the plan shown to a first-time lifter.
library;

import 'exercises.dart';

class ProgramExercise {
  final String id;
  final List<int> setsByMonth; // [weeks 1-4, 5-8, 9-12]
  final List<String> repsByMonth;
  final String? unit; // '' = reps · 's' = seconds · '/side' etc.
  final int restSeconds;

  /// The wording from the gym trainer's handwritten/list plan, when this
  /// exercise is shown in the coach-plan view.
  final String? coachLabel;
  final String? coachPrescription;
  final String? coachNote;

  const ProgramExercise(
    this.id,
    this.setsByMonth,
    this.repsByMonth, {
    this.unit,
    this.restSeconds = 90,
    this.coachLabel,
    this.coachPrescription,
    this.coachNote,
  });

  String get name => coachLabel ?? exercises[id]?.name ?? id;
}

class ProgramDay {
  final String key;
  final String title;
  final String focus;
  final String emoji;
  final List<ProgramExercise> items;
  final bool restDay;
  final bool optional;

  const ProgramDay(
    this.key,
    this.title,
    this.focus,
    this.emoji,
    this.items, {
    this.restDay = false,
    this.optional = false,
  });
}

class Phase {
  final String name;
  final String rir;
  final String description;

  const Phase(this.name, this.rir, this.description);
}

const phases = [
  Phase(
    'Weeks 1–4 · Learn',
    '3 RIR',
    'Use a light, repeatable weight. Finish every set feeling that about 3 good reps were left.',
  ),
  Phase(
    'Weeks 5–8 · Build',
    '2 RIR',
    'Keep the same movements and add a rep before adding a small amount of weight.',
  ),
  Phase(
    'Weeks 9–12 · Progress',
    '1–2 RIR',
    'Progress only when every rep is controlled. No max attempts and no failure on big lifts.',
  ),
];

int monthForWeek(int week) {
  if (week <= 4) return 0;
  if (week <= 8) return 1;
  return 2;
}

Phase phaseForWeek(int week) => phases[monthForWeek(week.clamp(1, 12))];

const programDays = <ProgramDay>[
  ProgramDay('monday', 'Full Body A', 'Legs · Push · Pull · Core', '🏋️', [
    ProgramExercise(
      'goblet-squat',
      [2, 3, 3],
      ['10–12', '8–12', '8–10'],
      restSeconds: 120,
    ),
    ProgramExercise(
      'dumbbell-bench-press',
      [2, 3, 3],
      ['8–12', '8–12', '6–10'],
      restSeconds: 120,
    ),
    ProgramExercise(
      'lat-pulldown',
      [2, 3, 3],
      ['8–12', '8–12', '8–10'],
      restSeconds: 120,
    ),
    ProgramExercise(
      'romanian-deadlift',
      [2, 3, 3],
      ['8–12', '8–12', '6–10'],
      restSeconds: 120,
    ),
    ProgramExercise(
      'dead-bug',
      [2, 2, 3],
      ['6–10', '8–10', '8–12'],
      unit: '/side',
    ),
  ]),
  ProgramDay(
    'tuesday',
    'Easy Cardio + Mobility',
    'Optional · stamina · recovery',
    '🚶',
    [
      ProgramExercise(
        'recovery-walk',
        [1, 1, 1],
        ['20', '25', '30'],
        unit: ' min',
        restSeconds: 0,
      ),
      ProgramExercise(
        'recovery-stretch',
        [1, 1, 1],
        ['1', '1', '1'],
        unit: ' round',
        restSeconds: 0,
      ),
    ],
    optional: true,
  ),
  ProgramDay(
    'wednesday',
    'Full Body B',
    'Legs · Shoulders · Back · Core',
    '💪',
    [
      ProgramExercise(
        'leg-press',
        [2, 3, 3],
        ['10–12', '8–12', '8–10'],
        restSeconds: 120,
      ),
      ProgramExercise(
        'incline-dumbbell-press',
        [2, 3, 3],
        ['8–12', '8–12', '8–10'],
        restSeconds: 120,
      ),
      ProgramExercise(
        'single-arm-row',
        [2, 3, 3],
        ['8–12', '8–12', '8–10'],
        unit: '/arm',
        restSeconds: 90,
      ),
      ProgramExercise(
        'dumbbell-overhead-press',
        [2, 3, 3],
        ['8–12', '8–12', '6–10'],
        restSeconds: 120,
      ),
      ProgramExercise('lying-leg-curl', [2, 3, 3], ['10–15', '8–12', '8–12']),
      ProgramExercise(
        'plank',
        [2, 2, 3],
        ['20–30', '30–45', '30–60'],
        unit: ' s',
      ),
    ],
  ),
  ProgramDay(
    'thursday',
    'Rest / Easy Walk',
    'Optional · breathe · recover',
    '🌿',
    [
      ProgramExercise(
        'recovery-walk',
        [1, 1, 1],
        ['15', '20', '25'],
        unit: ' min',
        restSeconds: 0,
      ),
      ProgramExercise(
        'recovery-stretch',
        [1, 1, 1],
        ['1', '1', '1'],
        unit: ' round',
        restSeconds: 0,
      ),
    ],
    optional: true,
  ),
  ProgramDay(
    'friday',
    'Full Body C',
    'Squat · press · row · hamstrings · carry',
    '⚡',
    [
      ProgramExercise(
        'goblet-squat',
        [2, 3, 3],
        ['10–12', '8–12', '8–10'],
        restSeconds: 120,
      ),
      ProgramExercise(
        'bench-press',
        [2, 3, 3],
        ['8–12', '8–12', '6–10'],
        restSeconds: 120,
      ),
      ProgramExercise(
        'single-arm-row',
        [2, 3, 3],
        ['8–12', '8–12', '8–10'],
        unit: '/arm',
        restSeconds: 90,
      ),
      ProgramExercise('lying-leg-curl', [2, 3, 3], ['10–15', '8–12', '8–12']),
      ProgramExercise('face-pull', [2, 3, 3], ['12–15', '12–15', '10–15']),
      ProgramExercise(
        'farmers-walk',
        [2, 2, 3],
        ['20–30', '30–40', '30–60'],
        unit: ' s',
      ),
    ],
  ),
  ProgramDay(
    'saturday',
    'Optional Zone 2',
    'Optional · stamina · conversation pace',
    '🚴',
    [
      ProgramExercise(
        'recovery-walk',
        [1, 1, 1],
        ['20', '25', '30'],
        unit: ' min',
        restSeconds: 0,
      ),
      ProgramExercise(
        'recovery-stretch',
        [1, 1, 1],
        ['1', '1', '1'],
        unit: ' round',
        restSeconds: 0,
      ),
    ],
    optional: true,
  ),
  ProgramDay(
    'sunday',
    'REST',
    'Full rest · sleep · eat · recover',
    '😴',
    [],
    restDay: true,
  ),
];

/// The plan the gym trainer gave the athlete. Labels preserve the trainer's
/// wording; IDs point to a safe, teachable implementation in our catalog.
/// The original targets remain visible as `coachPrescription`, while the
/// starting dose is deliberately lighter for a new lifter.
const coachPlanDays = <ProgramDay>[
  ProgramDay('monday', 'Coach plan · Chest', 'Trainer: chest day', '🫀', [
    ProgramExercise(
      'bench-press',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Flat bench',
      coachPrescription: '4 × 12',
    ),
    ProgramExercise(
      'incline-dumbbell-press',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Incline bench',
      coachPrescription: '3 × 12',
      coachNote: 'This app uses dumbbells until the coach confirms the barbell/machine setup.',
    ),
    ProgramExercise(
      'decline-bench-press',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Decline bench',
      coachPrescription: '3 × 12',
    ),
    ProgramExercise(
      'dumbbell-fly',
      [1, 2, 2],
      ['10–12', '10–15', '10–15'],
      restSeconds: 90,
      coachLabel: 'Flat dumbbell fly',
      coachPrescription: '3 × 15',
    ),
    ProgramExercise(
      'chest-press-machine',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Chest press machine',
      coachPrescription: '4 × 10',
    ),
    ProgramExercise(
      'pec-deck-fly',
      [1, 2, 2],
      ['10–12', '10–15', '10–15'],
      restSeconds: 90,
      coachLabel: 'Pec deck fly',
      coachPrescription: '3 × 10',
    ),
  ]),
  ProgramDay(
    'tuesday',
    'Coach plan · Shoulders',
    'Trainer: shoulder day',
    '🏹',
    [
      ProgramExercise(
        'dumbbell-overhead-press',
        [1, 2, 2],
        ['8–10', '8–12', '8–12'],
        restSeconds: 120,
        coachLabel: 'Dumbbell press',
        coachPrescription: '4 × 10',
      ),
      ProgramExercise(
        'lateral-raise',
        [1, 2, 2],
        ['10–12', '10–15', '10–15'],
        restSeconds: 75,
        coachLabel: 'Side raise',
        coachPrescription: '4 × 10',
      ),
      ProgramExercise(
        'front-raise',
        [1, 2, 2],
        ['10–12', '10–15', '10–15'],
        restSeconds: 75,
        coachLabel: 'Front raise',
        coachPrescription: '3 × 10',
      ),
      ProgramExercise(
        'reverse-fly',
        [1, 2, 2],
        ['10–12', '10–15', '10–15'],
        restSeconds: 75,
        coachLabel: '“Revers” — likely reverse fly, confirm',
        coachPrescription: '3 × 12',
        coachNote: 'The trainer spelling is abbreviated. Confirm the exact machine or dumbbell movement first.',
      ),
      ProgramExercise(
        'dumbbell-shrug',
        [1, 2, 2],
        ['10–12', '10–15', '10–15'],
        restSeconds: 90,
        coachLabel: 'Shrugs',
        coachPrescription: '4 × 12',
      ),
    ],
  ),
  ProgramDay('wednesday', 'Coach plan · Back', 'Trainer: back day', '🧭', [
    ProgramExercise(
      'lat-pulldown',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Lat pull',
      coachPrescription: '4 × 10',
    ),
    ProgramExercise(
      'behind-lat-pulldown',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Behind lat pull → front pull',
      coachPrescription: '3 × 10',
      coachNote: 'The trainer wrote behind lat pull. Use the bar to the upper chest, never behind the neck; ask the coach to confirm.',
    ),
    ProgramExercise(
      'single-arm-row',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 90,
      coachLabel: 'One-arm machine / row — confirm',
      coachPrescription: '3 × 10',
      coachNote: 'The list does not identify the machine. Ask the trainer to point it out; use the dumbbell row alternative if unsure.',
    ),
    ProgramExercise(
      'seated-cable-row',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 90,
      coachLabel: 'Seated row — confirm',
      coachPrescription: '4 × 10',
      coachNote: 'The list only says “Seated”. Confirm that the trainer means the seated cable row.',
    ),
    ProgramExercise(
      'close-grip-lat-pulldown',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Close-grip pull — confirm',
      coachPrescription: '3 × 12',
      coachNote: 'Ask whether the close grip is for a pulldown or a row before changing the handle.',
    ),
    ProgramExercise(
      'back-extension',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 90,
      coachLabel: 'Hyperextension',
      coachPrescription: '3 × 10',
    ),
  ]),
  ProgramDay('thursday', 'Coach plan · Biceps', 'Trainer: biceps day', '💪', [
    ProgramExercise(
      'barbell-curl',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 90,
      coachLabel: 'Barbell curl',
      coachPrescription: '4 × 10',
    ),
    ProgramExercise(
      'bicep-curl',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: 'Dumbbell curl',
      coachPrescription: '3 × 10',
    ),
    ProgramExercise(
      'cable-curl',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: 'Cable curl',
      coachPrescription: '3 × 10',
    ),
    ProgramExercise(
      'preacher-curl',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: 'Preacher chair curl',
      coachPrescription: '3 × 10',
    ),
    ProgramExercise(
      'hammer-curl',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: 'Hammer curl',
      coachPrescription: '4 × 12',
    ),
  ]),
  ProgramDay('friday', 'Coach plan · Triceps', 'Trainer: triceps day', '🔧', [
    ProgramExercise(
      'single-arm-triceps-extension',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: 'Single-hand dumbbell',
      coachPrescription: '3 × 10',
    ),
    ProgramExercise(
      'dumbbell-overhead-triceps-extension',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 90,
      coachLabel: 'Double-hand dumbbell',
      coachPrescription: '4 × 10',
    ),
    ProgramExercise(
      'tricep-pushdown',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: 'Pulley pushdown',
      coachPrescription: '4 × 10',
    ),
    ProgramExercise(
      'dumbbell-skull-crusher',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 90,
      coachLabel: 'Dumbbell skull crusher',
      coachPrescription: '3 × 10',
    ),
    ProgramExercise(
      'triceps-unclear',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 75,
      coachLabel: '“Roughf nd toughf” — clarify',
      coachPrescription: '3 × 10',
      coachNote: 'The name is unclear in the supplied list. Ask the trainer to demonstrate it before choosing a movement; this card is a temporary light pushdown placeholder.',
    ),
  ]),
  ProgramDay('saturday', 'Coach plan · Legs', 'Trainer: leg day', '🦵', [
    ProgramExercise(
      'goblet-squat',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Squats → goblet squat first',
      coachPrescription: '4 × 12',
      coachNote: 'Start with a goblet squat until the coach checks your barbell setup.',
    ),
    ProgramExercise(
      'leg-press',
      [1, 2, 2],
      ['8–10', '8–12', '8–12'],
      restSeconds: 120,
      coachLabel: 'Leg press',
      coachPrescription: '3 × 10',
    ),
    ProgramExercise(
      'lying-leg-curl',
      [1, 2, 2],
      ['10–12', '10–15', '10–15'],
      restSeconds: 90,
      coachLabel: 'Prone leg curl',
      coachPrescription: '4 × 10',
    ),
    ProgramExercise(
      'leg-extension',
      [1, 2, 2],
      ['10–12', '10–15', '10–15'],
      restSeconds: 75,
      coachLabel: 'Leg extension',
      coachPrescription: '3 × 12',
    ),
    ProgramExercise(
      'standing-calf-raise',
      [1, 2, 2],
      ['10–12', '12–15', '12–15'],
      restSeconds: 75,
      coachLabel: 'Calves',
      coachPrescription: '3 × 15',
    ),
  ]),
  ProgramDay(
    'sunday',
    'REST',
    'Rest, sleep, eat, recover',
    '😴',
    [],
    restDay: true,
  ),
];

/// Exercises that normally use a load and can be logged as kg.
const weightBasedIds = {
  'bench-press',
  'dumbbell-bench-press',
  'incline-dumbbell-press',
  'dumbbell-overhead-press',
  'goblet-squat',
  'romanian-deadlift',
  'leg-press',
  'lying-leg-curl',
  'lat-pulldown',
  'single-arm-row',
  'face-pull',
  'farmers-walk',
  'decline-bench-press',
  'dumbbell-fly',
  'chest-press-machine',
  'pec-deck-fly',
  'front-raise',
  'reverse-fly',
  'dumbbell-shrug',
  'behind-lat-pulldown',
  'seated-cable-row',
  'close-grip-lat-pulldown',
  'back-extension',
  'barbell-curl',
  'bicep-curl',
  'cable-curl',
  'preacher-curl',
  'hammer-curl',
  'single-arm-triceps-extension',
  'dumbbell-overhead-triceps-extension',
  'dumbbell-skull-crusher',
  'triceps-unclear',
  'leg-extension',
};

/// Kegel sub-guide used by the optional tracker, not a replacement for a
/// clinician. Stop if there is pelvic pain, urgency or worsening symptoms.
const kegelGuide = {
  'setup': [
    'Find the muscle once; never repeatedly stop urine mid-flow.',
    'Start lying or sitting comfortably and breathe normally.',
    'If you cannot isolate it, ask a clinician or pelvic-floor physiotherapist.',
  ],
  'technique': [
    'Squeeze only the pelvic floor; keep abs, glutes and thighs relaxed.',
    'Hold 3 seconds, relax fully for 3 seconds, and do not hold your breath.',
    'Quality matters more than squeezing harder or doing more sets.',
  ],
  'months': [
    'Month 1: 2–3 sets × 8–10 gentle holds; stop before fatigue.',
    'Month 2: 2–3 sets × 8–10 holds of up to 5 seconds.',
    'Month 3: maintain only if symptom-free; rest if tight or sore.',
  ],
  'mistakes': [
    'Using abs/butt/thighs instead of the pelvic floor.',
    'Holding your breath or bearing down.',
    'Overdoing it; pain, urgency or tightness means stop and seek advice.',
  ],
};
