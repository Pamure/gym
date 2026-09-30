/// Beginner-facing equipment notes. These are deliberately short enough to
/// read beside a machine. If the gym's model differs, ask the coach to set
/// the seat and demonstrate one light repetition before loading it.
library;

class ExerciseGuide {
  final String equipment;
  final String findIt;
  final String setup;
  final List<String> alternatives;
  final List<String> checklist;

  const ExerciseGuide({
    required this.equipment,
    required this.findIt,
    required this.setup,
    required this.alternatives,
    required this.checklist,
  });
}

const exerciseGuides = <String, ExerciseGuide>{
  'goblet-squat': ExerciseGuide(
    equipment: 'One dumbbell or kettlebell',
    findIt: 'Dumbbell rack; no machine needed.',
    setup: 'Hold one dumbbell at your chest. Feet about shoulder width. Sit between your hips and stand tall.',
    alternatives: ['Leg press machine', 'Bodyweight box squat'],
    checklist: [
      'Whole foot stays down',
      'Knees track over toes',
      'Stop depth before your back rounds',
    ],
  ),
  'bench-press': ExerciseGuide(
    equipment: 'Flat bench + barbell rack or Smith machine',
    findIt:
        'Bench inside a rack with safety arms. Ask staff to set the safeties.',
    setup: 'Eyes under the bar, feet flat, shoulder blades gently down and back. Use a spotter for challenging sets.',
    alternatives: ['Dumbbell bench press', 'Chest press machine'],
    checklist: [
      'Bar lowers with control',
      'Butt stays on bench',
      'No solo max attempts',
    ],
  ),
  'dumbbell-bench-press': ExerciseGuide(
    equipment: 'Flat bench + two dumbbells',
    findIt: 'Dumbbell rack and adjustable flat bench.',
    setup: 'Dumbbells start over mid-chest. Lower until comfortable, then press up without crashing them together.',
    alternatives: ['Chest press machine', 'Push-ups with hands on a bench'],
    checklist: [
      'Wrists stacked over elbows',
      'Shoulders stay comfortable',
      'Use a lighter pair if setup is unstable',
    ],
  ),
  'incline-dumbbell-press': ExerciseGuide(
    equipment: 'Adjustable bench + dumbbells',
    findIt: 'Set the bench to about 30 degrees, not upright.',
    setup: 'Back and head supported. Lower dumbbells toward upper chest, then press up and slightly inward.',
    alternatives: [
      'Incline chest press machine',
      'Push-ups with hands elevated',
    ],
    checklist: [
      'Bench is not too steep',
      'No bouncing',
      'Stop if shoulder pinches',
    ],
  ),
  'lat-pulldown': ExerciseGuide(
    equipment: 'Lat-pulldown cable machine',
    findIt: 'Tall cable machine with a thigh pad and a long overhead bar.',
    setup: 'Adjust the thigh pad snugly. Pull the bar to upper chest while leaning only slightly back.',
    alternatives: ['Assisted pull-up machine', 'Resistance-band pulldown'],
    checklist: [
      'Pull elbows toward ribs',
      'Bar stays in front of face',
      'Do not pull behind your neck',
    ],
  ),
  'romanian-deadlift': ExerciseGuide(
    equipment: 'Dumbbells or empty/light barbell',
    findIt:
        'Free-weight area; start with dumbbells if the bar feels intimidating.',
    setup: 'Soft knees, push hips back, keep the weights close to legs, and stand by driving hips forward.',
    alternatives: ['Cable pull-through', 'Light dumbbell hip hinge'],
    checklist: [
      'Back stays neutral',
      'Hips move back, not a deep squat',
      'Stop when hamstrings limit range',
    ],
  ),
  'leg-press': ExerciseGuide(
    equipment: '45-degree or horizontal leg-press machine',
    findIt: 'Large sled or seated machine with a backrest and footplate.',
    setup: 'Back and hips stay against the pad. Feet shoulder width. Unlock only after your feet are placed.',
    alternatives: ['Goblet squat', 'Supported split squat'],
    checklist: [
      'Knees follow toes',
      'Do not lock knees hard',
      'Never let hips curl off the pad',
    ],
  ),
  'lying-leg-curl': ExerciseGuide(
    equipment: 'Lying leg-curl machine',
    findIt: 'Bench facedown with a roller behind the ankles.',
    setup: 'Align knee joint with the machine pivot and set the roller just above your shoes.',
    alternatives: ['Seated leg curl', 'Stability-ball hamstring curl'],
    checklist: [
      'Hips stay down',
      'Curl smoothly',
      'Return fully without dropping the weight',
    ],
  ),
  'single-arm-row': ExerciseGuide(
    equipment: 'Dumbbell + bench',
    findIt: 'Dumbbell rack and a flat bench for support.',
    setup: 'One hand and knee support the bench. Keep spine long and pull elbow toward your hip.',
    alternatives: ['Seated cable row', 'Chest-supported row machine'],
    checklist: [
      'Do not twist',
      'Shoulder stays away from ear',
      'Control the lower',
    ],
  ),
  'dumbbell-overhead-press': ExerciseGuide(
    equipment: 'Two light dumbbells; seated bench optional',
    findIt: 'Dumbbell rack. Sit if standing makes your back arch.',
    setup: 'Brace gently, start at shoulder height, and press up in a smooth path.',
    alternatives: ['Machine shoulder press', 'Landmine press'],
    checklist: [
      'Ribs stay down',
      'No painful range',
      'Do not turn it into a push press',
    ],
  ),
  'decline-bench-press': ExerciseGuide(
    equipment: 'Decline bench + barbell or machine',
    findIt: 'Bench angled slightly down inside a rack. Ask the trainer to set the safety arms and spot you.',
    setup: 'Feet planted, shoulder blades supported, and use a light load while learning the setup.',
    alternatives: ['Dumbbell bench press', 'Hands-elevated push-up'],
    checklist: [
      'No solo heavy attempts',
      'Bar stays controlled',
      'Stop if shoulder or neck feels wrong',
    ],
  ),
  'dumbbell-fly': ExerciseGuide(
    equipment: 'Flat bench + two light dumbbells',
    findIt: 'Use a flat bench in the dumbbell area.',
    setup:
        'Keep a soft elbow bend and open only to a comfortable chest stretch.',
    alternatives: ['Dumbbell squeeze press', 'Incline push-up'],
    checklist: [
      'Very light load',
      'No deep painful stretch',
      'Do not bend the elbows into a press',
    ],
  ),
  'chest-press-machine': ExerciseGuide(
    equipment: 'Seated chest press machine',
    findIt: 'Look for two handles in front of a backrest. Ask the trainer to set the seat.',
    setup:
        'Handles start around mid-chest; keep your head and back on the pad.',
    alternatives: ['Dumbbell bench press', 'Wall or incline push-up'],
    checklist: [
      'Seat pivot lines up with your chest',
      'Smooth return',
      'Do not let the stack slam',
    ],
  ),
  'pec-deck-fly': ExerciseGuide(
    equipment: 'Pec-deck/rear-delt machine',
    findIt: 'Seated machine with arm pads or handles that sweep together.',
    setup: 'Set the seat so the handles are at mid-chest and use a small range first.',
    alternatives: ['Light dumbbell fly', 'Dumbbell squeeze press'],
    checklist: [
      'Light load',
      'Shoulders stay down',
      'Stop before shoulder pinching',
    ],
  ),
  'front-raise': ExerciseGuide(
    equipment: 'One or two very light dumbbells',
    findIt: 'Dumbbell rack; choose lighter than you expect.',
    setup: 'Raise to about shoulder height with soft elbows and a quiet torso.',
    alternatives: [
      'Plate raise with a very light plate',
      'Skip it and focus on the coach-approved press',
    ],
    checklist: ['No swinging', 'No painful shoulder range', 'Breathe normally'],
  ),
  'reverse-fly': ExerciseGuide(
    equipment: 'Reverse-fly machine or two light dumbbells',
    findIt: 'Look for the rear-delt machine; ask if the handles are set for reverse fly.',
    setup: 'Keep the neck relaxed and move from the rear shoulder, not the lower back.',
    alternatives: ['Face pull', 'Band pull-apart'],
    checklist: ['Light load', 'No shrugging', 'Stop if the shoulder pinches'],
  ),
  'dumbbell-shrug': ExerciseGuide(
    equipment: 'Two dumbbells',
    findIt: 'Dumbbell rack and a clear standing space.',
    setup: 'Stand tall and lift shoulders straight up, then lower slowly.',
    alternatives: ['Farmer hold', 'Light farmer walk'],
    checklist: ['Do not roll shoulders', 'No bouncing', 'Keep ribs stacked'],
  ),
  'behind-lat-pulldown': ExerciseGuide(
    equipment: 'Lat-pulldown machine',
    findIt: 'Use the same tall machine with a thigh pad and overhead bar.',
    setup: 'This is a safe front-of-neck replacement: pull to the upper chest, never behind the neck.',
    alternatives: ['Assisted pull-up', 'Single-arm dumbbell row'],
    checklist: [
      'No behind-neck pulling',
      'Elbows move down',
      'Stop for shoulder pain',
    ],
  ),
  'seated-cable-row': ExerciseGuide(
    equipment: 'Seated cable row station',
    findIt: 'Low cable with a foot brace and close/neutral handle.',
    setup: 'Sit tall, brace lightly, pull toward the lower ribs, and return slowly.',
    alternatives: ['Single-arm dumbbell row', 'Chest-supported dumbbell row'],
    checklist: [
      'No torso rocking',
      'Shoulders stay away from ears',
      'Control the cable',
    ],
  ),
  'close-grip-lat-pulldown': ExerciseGuide(
    equipment: 'Lat-pulldown machine + close neutral handle',
    findIt: 'Ask the trainer which close handle is intended.',
    setup: 'Pull the handle to the upper chest with a small lean and controlled return.',
    alternatives: ['Regular front lat pulldown', 'Assisted pull-up'],
    checklist: [
      'Never behind the neck',
      'Do not swing',
      'Use a load you can pause',
    ],
  ),
  'back-extension': ExerciseGuide(
    equipment: '45-degree back-extension bench',
    findIt:
        'Look for the angled Roman chair; ask the trainer to set the hip pad.',
    setup: 'Hinge at the hips and stop when your body is straight; no need to arch back.',
    alternatives: ['Bodyweight bird dog', 'Light Romanian deadlift'],
    checklist: ['Pad below hip crease', 'Neutral back', 'No overextension'],
  ),
  'barbell-curl': ExerciseGuide(
    equipment: 'Light barbell or fixed curl bar',
    findIt: 'Free-weight rack; start with the empty bar or fixed light bar.',
    setup: 'Elbows close to ribs, torso still, and lower the bar slowly.',
    alternatives: ['Dumbbell curl', 'Cable curl'],
    checklist: ['No swinging', 'No back lean', 'Keep wrists comfortable'],
  ),
  'bicep-curl': ExerciseGuide(
    equipment: 'Two light dumbbells',
    findIt: 'Dumbbell rack; choose a pair you can control.',
    setup: 'Keep elbows near ribs, curl smoothly, and lower for two seconds.',
    alternatives: ['Hammer curl', 'Cable curl'],
    checklist: ['No swinging', 'Shoulders relaxed', 'Full comfortable range'],
  ),
  'cable-curl': ExerciseGuide(
    equipment: 'Low cable + straight or EZ attachment',
    findIt: 'Cable station; ask the trainer to set the pin and attachment.',
    setup: 'Stand tall with cable tension at the bottom and curl without leaning back.',
    alternatives: ['Dumbbell curl', 'Barbell curl'],
    checklist: ['No stack slamming', 'Elbows stay close', 'Use a light load'],
  ),
  'preacher-curl': ExerciseGuide(
    equipment: 'Preacher curl bench + light bar or dumbbells',
    findIt: 'Small angled arm pad near the free-weight or machine curl area.',
    setup:
        'Upper arms rest on the pad; use a controlled partial range at first.',
    alternatives: ['Dumbbell curl', 'Cable curl'],
    checklist: [
      'Do not drop into elbow lockout',
      'No shoulder lifting',
      'Light load',
    ],
  ),
  'hammer-curl': ExerciseGuide(
    equipment: 'Two light dumbbells',
    findIt: 'Dumbbell rack; palms face each other throughout.',
    setup: 'Keep elbows close and curl without rotating the wrists.',
    alternatives: ['Dumbbell curl', 'Cable rope curl'],
    checklist: ['No swinging', 'No shrugging', 'Lower slowly'],
  ),
  'single-arm-triceps-extension': ExerciseGuide(
    equipment: 'One light dumbbell',
    findIt: 'Dumbbell rack; perform seated if standing makes you arch.',
    setup: 'Keep the upper arm quiet and move only at the elbow.',
    alternatives: ['Cable pushdown', 'Close-grip incline push-up'],
    checklist: ['Very light at first', 'No elbow pain', 'Ribs stay down'],
  ),
  'dumbbell-overhead-triceps-extension': ExerciseGuide(
    equipment: 'One light dumbbell + optional bench',
    findIt: 'Dumbbell rack; use both hands around one head of the dumbbell.',
    setup: 'Keep elbows pointing forward and lower only through a comfortable range.',
    alternatives: ['Cable pushdown', 'Close-grip incline push-up'],
    checklist: ['No lower-back arch', 'No flared elbows', 'Do not rush'],
  ),
  'dumbbell-skull-crusher': ExerciseGuide(
    equipment: 'Flat bench + two light dumbbells',
    findIt: 'Flat bench in the free-weight area; ask for a spotter if unsure.',
    setup: 'Upper arms stay mostly still while the dumbbells lower beside the head.',
    alternatives: ['Cable pushdown', 'Close-grip incline push-up'],
    checklist: [
      'Light load near the face',
      'No elbow flare',
      'Controlled lowering',
    ],
  ),
  'triceps-unclear': ExerciseGuide(
    equipment: 'Ask the trainer to identify the exact movement; cable station is the temporary safe option',
    findIt: 'The supplied name “Roughf nd toughf” is unclear.',
    setup: 'Until confirmed, use one light set of a normal cable pushdown only if the trainer agrees.',
    alternatives: ['Cable pushdown', 'Close-grip incline push-up'],
    checklist: [
      'Do not guess the machine',
      'Ask for a demonstration',
      'Stop if elbow/shoulder hurts',
    ],
  ),
  'leg-extension': ExerciseGuide(
    equipment: 'Leg-extension machine',
    findIt: 'Seated machine with an ankle roller; ask the trainer to align the pivot.',
    setup: 'Knee lines up with the machine hinge and the pad rests above your ankle.',
    alternatives: ['Sit-to-stand', 'Low step-up'],
    checklist: ['Light load', 'Smooth extension', 'No hard knee lockout'],
  ),
  'face-pull': ExerciseGuide(
    equipment: 'Cable station + rope attachment',
    findIt: 'Cable set around eye or forehead height.',
    setup: 'Take a light weight, pull the rope toward your face, and rotate hands apart without shrugging.',
    alternatives: ['Reverse-fly machine', 'Band pull-apart'],
    checklist: [
      'Light and controlled',
      'Elbows travel wide',
      'Stop before shoulder discomfort',
    ],
  ),
  'farmers-walk': ExerciseGuide(
    equipment: 'Two dumbbells or farmer handles',
    findIt: 'Open lane or turf area; keep clear of other members.',
    setup: 'Stand tall with weights by sides and walk slowly while breathing normally.',
    alternatives: [
      'Suitcase carry with one dumbbell',
      'Standing dumbbell hold (if no clear walking lane)',
    ],
    checklist: ['Shoulders down', 'No leaning', 'Put weights down safely'],
  ),
  'dead-bug': ExerciseGuide(
    equipment: 'Mat or clean open floor',
    findIt: 'A flat floor away from loaded weight stations.',
    setup: 'Lie on your back, ribs down, knees over hips. Slowly lower one arm and the opposite leg, then return.',
    alternatives: ['Bird dog on all fours', 'Short lever dead bug'],
    checklist: [
      'Keep your back comfortable',
      'Move slowly',
      'Exhale as a limb moves away',
    ],
  ),
  'plank': ExerciseGuide(
    equipment: 'Mat or clean floor',
    findIt: 'Choose a floor space where nobody needs to walk.',
    setup: 'Elbows below shoulders, knees or toes on the floor. Hold a comfortable straight line while breathing.',
    alternatives: ['Knee plank', 'Incline plank with hands on a bench'],
    checklist: ['No lower-back sag', 'Breathe', 'Stop before form breaks'],
  ),
  'recovery-walk': ExerciseGuide(
    equipment: 'Treadmill, stationary bike or safe walking route',
    findIt: 'Choose a pace where you can speak in full sentences.',
    setup: 'Start easy for five minutes, then maintain a conversational pace.',
    alternatives: ['Elliptical', 'Easy outdoor walk'],
    checklist: [
      'No breathless intervals',
      'Stop for dizziness or chest pain',
      'Hydrate',
    ],
  ),
  'recovery-stretch': ExerciseGuide(
    equipment: 'Mat or open floor',
    findIt: 'Use a clean area away from lifting lanes.',
    setup: 'Move gently and hold only mild tension; never force a joint.',
    alternatives: ['Short easy walk', 'Mobility taught by your coach'],
    checklist: ['Breathe normally', 'No bouncing', 'Pain is a stop signal'],
  ),
};

ExerciseGuide? guideForExercise(String id) => exerciseGuides[id];
