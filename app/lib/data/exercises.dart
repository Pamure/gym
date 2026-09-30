/// IronForge exercise catalog — single source of truth derived from
/// knowledge/02 & knowledge/03 (form cues, mistakes, verified media).
library;

class Exercise {
  final String id;
  final String name;
  final List<String> muscles;
  final List<String> cues;
  final List<String> mistakes;
  final String? gif; // bundled asset key (assets/gifs/<key>.gif)
  final String?
  videoId; // YouTube tutorial id (in-app play + external fallback)

  const Exercise({
    required this.id,
    required this.name,
    required this.muscles,
    required this.cues,
    required this.mistakes,
    this.gif,
    this.videoId,
  });

  String get gifAsset => gif == null ? '' : 'assets/gifs/$gif.gif';
  String get youtubeUrl =>
      videoId == null ? '' : 'https://www.youtube.com/watch?v=$videoId';
  String get searchUrl => Uri.encodeFull(
    'https://www.youtube.com/results?search_query=ironforge%20$name%20exercise',
  );
}

const exercises = <String, Exercise>{
  // ---------------- PUSH ----------------
  'bench-press': Exercise(
    id: 'bench-press',
    name: 'Flat Barbell Bench Press',
    muscles: ['Chest', 'Front Delts', 'Triceps'],
    cues: [
      'Pinch shoulder blades together & down before unracking',
      'Feet flat, butt stays on the bench',
      'Lower to nipple line, elbows ~45-70° (not flared 90°)',
      'Press up and slightly back toward your face',
    ],
    mistakes: [
      'Bouncing the bar off your chest',
      'Hips lifting off the bench',
      'Half reps (bar never touches chest)',
      'Elbows flared straight out — shoulder strain',
    ],
    gif: 'bench-press',
    videoId: 'rT7DgCr-3pg',
  ),
  'overhead-press': Exercise(
    id: 'overhead-press',
    name: 'Standing Overhead Press',
    muscles: ['Shoulders', 'Triceps', 'Core'],
    cues: [
      'Squeeze glutes + brace abs BEFORE pressing',
      'Bar on front delts, push head back, press straight up',
      'Lock out overhead, biceps by your ears',
    ],
    mistakes: [
      'Leaning back (standing incline press)',
      'Ribs flaring forward',
      'Not locking out at the top',
    ],
    gif: 'overhead-press',
    videoId: '_RlRDWO2jfg',
  ),
  'incline-dumbbell-press': Exercise(
    id: 'incline-dumbbell-press',
    name: 'Incline Dumbbell Press',
    muscles: ['Upper Chest', 'Front Delts'],
    cues: [
      'Bench at 30-45° (steeper = more shoulder)',
      'Press up and slightly inward',
      'Full stretch at the bottom, 2-3s down',
    ],
    mistakes: [
      'Bench angle too steep — becomes a shoulder press',
      'Bouncing dumbbells at the top',
      'Shallow range of motion',
    ],
    gif: 'incline-dumbbell-press',
    videoId: '8iPEnn-ltC8',
  ),
  'decline-bench-press': Exercise(
    id: 'decline-bench-press',
    name: 'Decline Bench Press',
    muscles: ['Lower Chest', 'Triceps'],
    cues: [
      'Ask the coach to set the bench and spotter arms',
      'Feet planted and shoulder blades gently down',
      'Lower under control; press without bouncing',
    ],
    mistakes: [
      'Using a steep angle',
      'Attempting a heavy set without a spotter',
      'Letting the bar drift toward the neck',
    ],
    videoId: 'rT7DgCr-3pg',
  ),
  'dumbbell-fly': Exercise(
    id: 'dumbbell-fly',
    name: 'Flat Dumbbell Fly',
    muscles: ['Chest'],
    cues: [
      'Use light dumbbells on a flat bench',
      'Keep a soft elbow bend and open only to a comfortable stretch',
      'Bring the hands together without crashing the weights',
    ],
    mistakes: [
      'Using pressing weight',
      'Dropping elbows below a comfortable shoulder range',
      'Bouncing at the bottom',
    ],
    videoId: '8iPEnn-ltC8',
  ),
  'chest-press-machine': Exercise(
    id: 'chest-press-machine',
    name: 'Chest Press Machine',
    muscles: ['Chest', 'Triceps'],
    cues: [
      'Set the seat so handles start around mid-chest',
      'Keep back and head against the pad',
      'Press smoothly and return without letting the stack crash',
    ],
    mistakes: [
      'Seat too low or too high',
      'Shoulders rolling forward',
      'Locking elbows hard',
    ],
    videoId: 'rT7DgCr-3pg',
  ),
  'pec-deck-fly': Exercise(
    id: 'pec-deck-fly',
    name: 'Pec Deck Fly',
    muscles: ['Chest'],
    cues: [
      'Set the seat so handles are around mid-chest',
      'Keep a soft elbow bend',
      'Bring the pads together slowly and return under control',
    ],
    mistakes: [
      'Using momentum',
      'Shoulders shrugging',
      'Stretching beyond a pain-free range',
    ],
    videoId: 'rep-qVOkqgk',
  ),
  'tricep-pushdown': Exercise(
    id: 'tricep-pushdown',
    name: 'Tricep Rope Pushdown',
    muscles: ['Triceps'],
    cues: [
      'Elbows pinned to your sides — only forearms move',
      'Push down, split the rope at the bottom',
      'Squeeze 1 second at full extension',
    ],
    mistakes: [
      'Body swinging to move the weight',
      'Elbows drifting forward',
      'Too heavy — pushing with your back',
    ],
    gif: 'tricep-pushdown',
    videoId: '2-LAMcpzODU',
  ),
  'front-raise': Exercise(
    id: 'front-raise',
    name: 'Dumbbell Front Raise',
    muscles: ['Front Delts'],
    cues: [
      'Use very light dumbbells',
      'Raise to shoulder height with soft elbows',
      'Lower slowly without swinging',
    ],
    mistakes: [
      'Going above a comfortable range',
      'Swinging the torso',
      'Shrugging',
    ],
    videoId: 'OuG1smZTsQQ',
  ),
  'reverse-fly': Exercise(
    id: 'reverse-fly',
    name: 'Reverse Fly',
    muscles: ['Rear Delts', 'Upper Back'],
    cues: [
      'Use a light machine or dumbbells',
      'Keep neck relaxed and chest supported if possible',
      'Move arms out, not by shrugging',
    ],
    mistakes: [
      'Using heavy weights',
      'Jerking the arms',
      'Pinching through shoulder pain',
    ],
    videoId: 'rep-qVOkqgk',
  ),
  'dumbbell-shrug': Exercise(
    id: 'dumbbell-shrug',
    name: 'Dumbbell Shrug',
    muscles: ['Traps'],
    cues: [
      'Stand tall with dumbbells by your sides',
      'Lift shoulders straight up, not forward',
      'Pause briefly and lower slowly',
    ],
    mistakes: [
      'Rolling the shoulders',
      'Bouncing',
      'Using a load that changes posture',
    ],
    videoId: 'Fkzk_RqlYig',
  ),
  'lateral-raise': Exercise(
    id: 'lateral-raise',
    name: 'Dumbbell Lateral Raise',
    muscles: ['Side Delts'],
    cues: [
      'Slight forward lean, soft elbows',
      'Lead with the elbows, raise to shoulder height',
      'Slow 2-3s lowering — growth lives in the negative',
    ],
    mistakes: [
      'Swinging momentum',
      'Shrugging traps up',
      'Too heavy (this exercise punishes ego hardest)',
    ],
    gif: 'lateral-raise',
    videoId: 'OuG1smZTsQQ',
  ),
  'dumbbell-bench-press': Exercise(
    id: 'dumbbell-bench-press',
    name: 'Dumbbell Bench Press',
    muscles: ['Chest', 'Triceps'],
    cues: [
      'Full stretch at the bottom',
      'Dumbbells over mid-chest, slight inward press',
      'Control the descent 2-3s',
    ],
    mistakes: ['Dumbbells drifting apart', 'Clanking at the top to rest'],
    gif: 'dumbbell-bench-press',
    videoId: '8iPEnn-ltC8',
  ),
  'dumbbell-overhead-press': Exercise(
    id: 'dumbbell-overhead-press',
    name: 'Dumbbell Overhead Press',
    muscles: ['Shoulders', 'Triceps'],
    cues: [
      'Brace core and glutes like the barbell version',
      'Press from chin level to full lockout',
    ],
    mistakes: ['Lower back arching', 'Pressing forward instead of up'],
    gif: 'dumbbell-shoulder-press',
    videoId: '_RlRDWO2jfg',
  ),
  // ---------------- LEGS ----------------
  'back-squat': Exercise(
    id: 'back-squat',
    name: 'Barbell Back Squat (high bar)',
    muscles: ['Quads', 'Glutes', 'Core'],
    cues: [
      'Bar on upper traps, elbows down, grip tight',
      'Walk out in 3 steps — no wandering',
      'Big belly breath, brace, sit DOWN and slightly back',
      'Break parallel, drive up, knees track over toes',
    ],
    mistakes: [
      'Knees caving inward',
      'Lower back rounding at the bottom',
      'Heels lifting off the floor',
      'No brace — loose torso',
    ],
    gif: 'back-squat',
    videoId: 'gcNh17Ckjgg',
  ),
  'goblet-squat': Exercise(
    id: 'goblet-squat',
    name: 'Goblet Squat',
    muscles: ['Quads', 'Glutes', 'Core'],
    cues: [
      'Hold dumbbell vertically at your chest',
      'Elbows track inside your knees',
      'Sit DEEP, chest proud',
    ],
    mistakes: ['Leaning forward', 'Shallow depth'],
    gif: 'goblet-squat',
    videoId: 'gcNh17Ckjgg',
  ),
  'front-squat': Exercise(
    id: 'front-squat',
    name: 'Front Squat',
    muscles: ['Quads', 'Core'],
    cues: [
      'Bar on front delts, elbows HIGH (parallel to floor)',
      'Torso upright — front squat punishes leaning',
    ],
    mistakes: ['Elbows dropping (bar rolls forward)', 'Leaning forward'],
    gif: 'front-squat',
    videoId: 'gcNh17Ckjgg',
  ),
  'romanian-deadlift': Exercise(
    id: 'romanian-deadlift',
    name: 'Romanian Deadlift (RDL)',
    muscles: ['Hamstrings', 'Glutes', 'Lower Back'],
    cues: [
      'Soft knees, then LOCKED in that bend',
      'Push hips BACK — hinge, not squat',
      'Bar slides down your thighs',
      'Stop at deep hamstring stretch, squeeze glutes up',
    ],
    mistakes: [
      'Rounding the back',
      'Bending knees more (becomes a squat)',
      'Chasing the floor past your mobility',
    ],
    gif: 'romanian-deadlift',
    videoId: '_oyxCn2iSjU',
  ),
  'leg-press': Exercise(
    id: 'leg-press',
    name: 'Leg Press',
    muscles: ['Quads', 'Glutes'],
    cues: [
      'Feet shoulder-width, mid platform',
      'Lower to 90° knee bend',
      'Push through heels, never lock knees at top',
    ],
    mistakes: [
      'Butt lifting off the pad (lower back risk)',
      'Quarter reps with the whole stack',
    ],
    gif: 'leg-press',
    videoId: 'IZxyjW7MPJQ',
  ),
  'lying-leg-curl': Exercise(
    id: 'lying-leg-curl',
    name: 'Lying Leg Curl',
    muscles: ['Hamstrings'],
    cues: [
      'Pad just above your ankles',
      'Hips glued to the bench',
      'Full curl, slow 2-3s negative',
    ],
    mistakes: ['Hips rising to help', 'Swinging momentum'],
    gif: 'lying-leg-curl',
    videoId: '1Tq3QdYUuHs',
  ),
  'leg-extension': Exercise(
    id: 'leg-extension',
    name: 'Leg Extension Machine',
    muscles: ['Quads'],
    cues: [
      'Align your knee with the machine pivot',
      'Pad rests above the ankle',
      'Extend smoothly and lower under control',
    ],
    mistakes: [
      'Seat misaligned',
      'Kicking the weight',
      'Locking the knee hard',
    ],
    videoId: 'JbyjNymZOt0',
  ),
  'standing-calf-raise': Exercise(
    id: 'standing-calf-raise',
    name: 'Standing Calf Raise (machine)',
    muscles: ['Calves'],
    cues: [
      'Full stretch at bottom, 1s pause',
      'Explode up, 1s squeeze at top',
      'No bouncing',
    ],
    mistakes: ['Bouncing off the bottom', 'Half range of motion'],
    gif: 'standing-calf-raise',
    videoId: 'JbyjNymZOt0',
  ),
  // ---------------- PULL ----------------
  'deadlift': Exercise(
    id: 'deadlift',
    name: 'Conventional Deadlift',
    muscles: ['Back', 'Glutes', 'Hamstrings', 'Traps'],
    cues: [
      'Bar over mid-foot, shins 2-3cm from bar',
      'Hinge down, grip just outside knees',
      'Pull the slack out BEFORE it leaves the floor',
      'Push the floor away, bar drags up your legs',
      'Lock out squeezing glutes — no lean back, no shrug',
    ],
    mistakes: [
      'ROUNDED LOWER BACK (set is over — lower the weight)',
      'Jerking the bar off the floor',
      'Hips shooting up first',
      'Hyperextending at lockout',
    ],
    gif: 'deadlift',
    videoId: 'r4MzxtBKyNE',
  ),
  'bent-over-row': Exercise(
    id: 'bent-over-row',
    name: 'Barbell Bent-Over Row',
    muscles: ['Upper Back', 'Lats', 'Rear Delts'],
    cues: [
      'Hinge to ~45°, brace your core',
      'Pull bar to lower chest / upper abs',
      'Squeeze shoulder blades 1s at the top',
    ],
    mistakes: [
      'Torso bouncing with each rep (too heavy)',
      'Pulling to the neck',
      'Standing too upright',
    ],
    gif: 'bent-over-row',
    videoId: 'FWJR5Ve8bnQ',
  ),
  'lat-pulldown': Exercise(
    id: 'lat-pulldown',
    name: 'Lat Pulldown',
    muscles: ['Lats', 'Biceps'],
    cues: [
      'Slight ~15° lean back',
      'Pull to upper chest — elbows to back pockets',
      'Control the way up, don\'t get yanked',
    ],
    mistakes: [
      'Pulling behind the neck (shoulder risk)',
      'Leaning back 45° — turning it into a row',
      'Ultra-wide grip',
    ],
    gif: 'lat-pulldown',
    videoId: 'SALxEARYS2U',
  ),
  'behind-lat-pulldown': Exercise(
    id: 'behind-lat-pulldown',
    name: 'Front Lat Pulldown (safe replacement)',
    muscles: ['Lats', 'Biceps'],
    cues: [
      'Use the same machine with the bar in front of your face',
      'Pull to the upper chest with elbows down',
      'Ask the coach to adjust the thigh pad',
    ],
    mistakes: [
      'Pulling behind the neck',
      'Forcing a painful shoulder range',
      'Leaning far back',
    ],
    gif: 'lat-pulldown',
    videoId: 'SALxEARYS2U',
  ),
  'seated-cable-row': Exercise(
    id: 'seated-cable-row',
    name: 'Seated Cable Row',
    muscles: ['Upper Back', 'Lats'],
    cues: [
      'Sit tall with knees softly bent',
      'Pull the handle toward your lower ribs',
      'Return slowly without rounding your back',
    ],
    mistakes: [
      'Rocking the whole torso',
      'Shrugging',
      'Pulling behind the neck',
    ],
    videoId: 'FWJR5Ve8bnQ',
  ),
  'close-grip-lat-pulldown': Exercise(
    id: 'close-grip-lat-pulldown',
    name: 'Close-Grip Lat Pulldown',
    muscles: ['Lats', 'Biceps'],
    cues: [
      'Use a neutral or close handle',
      'Pull to the upper chest',
      'Keep the ribs stacked and control the return',
    ],
    mistakes: [
      'Behind-neck pulling',
      'Swinging back',
      'Shrugging into the top',
    ],
    videoId: 'SALxEARYS2U',
  ),
  'back-extension': Exercise(
    id: 'back-extension',
    name: 'Back Extension',
    muscles: ['Glutes', 'Hamstrings', 'Back'],
    cues: [
      'Set the pad below the hip crease',
      'Hinge from the hips with a neutral spine',
      'Stop when the body is straight; squeeze glutes',
    ],
    mistakes: [
      'Overextending at the top',
      'Rounding under load',
      'Using momentum',
    ],
    videoId: '_oyxCn2iSjU',
  ),
  'face-pull': Exercise(
    id: 'face-pull',
    name: 'Cable Face Pull',
    muscles: ['Rear Delts', 'Rotator Cuff'],
    cues: [
      'Cable at face height, rope attachment',
      'Pull toward your forehead, thumbs back',
      'Externally rotate at the end (knuckles up)',
    ],
    mistakes: [
      'Too heavy (you lean back and heave)',
      'Pulling to the chest instead of the face',
    ],
    videoId: 'rep-qVOkqgk', // no bundled gif in dataset — video only
  ),
  'barbell-curl': Exercise(
    id: 'barbell-curl',
    name: 'Barbell Curl',
    muscles: ['Biceps'],
    cues: [
      'Stand tall with elbows close to the ribs',
      'Curl without leaning back',
      'Lower under control',
    ],
    mistakes: [
      'Swinging the bar',
      'Elbows drifting forward',
      'Using a load that causes back lean',
    ],
    videoId: 'kwG2ipFRgFo',
  ),
  'cable-curl': Exercise(
    id: 'cable-curl',
    name: 'Cable Curl',
    muscles: ['Biceps'],
    cues: [
      'Stand close enough to keep cable tension',
      'Keep elbows near your sides',
      'Return slowly to a full comfortable length',
    ],
    mistakes: [
      'Leaning away from the stack',
      'Shrugging',
      'Letting the stack crash',
    ],
    videoId: 'kwG2ipFRgFo',
  ),
  'preacher-curl': Exercise(
    id: 'preacher-curl',
    name: 'Preacher Curl',
    muscles: ['Biceps'],
    cues: [
      'Set the seat so the upper arms rest comfortably on the pad',
      'Start light and avoid locking the elbows hard',
      'Lower slowly',
    ],
    mistakes: [
      'Shoulders lifting off the pad',
      'Dropping into the bottom',
      'Using a heavy load',
    ],
    videoId: 'kwG2ipFRgFo',
  ),
  'hammer-curl': Exercise(
    id: 'hammer-curl',
    name: 'Dumbbell Hammer Curl',
    muscles: ['Biceps', 'Forearms'],
    cues: [
      'Keep palms facing each other',
      'Elbows stay close to your sides',
      'Lower slowly',
    ],
    mistakes: ['Swinging', 'Turning it into a shoulder raise', 'Shrugging'],
    videoId: 'kwG2ipFRgFo',
  ),
  'bicep-curl': Exercise(
    id: 'bicep-curl',
    name: 'Dumbbell Bicep Curl',
    muscles: ['Biceps'],
    cues: [
      'Elbows pinned at your ribs',
      'Rotate palms up as you curl',
      '2-3s controlled negative',
    ],
    mistakes: ['Swinging the body', 'Elbows drifting forward'],
    gif: 'bicep-curl',
    videoId: 'kwG2ipFRgFo',
  ),
  'single-arm-triceps-extension': Exercise(
    id: 'single-arm-triceps-extension',
    name: 'Single-Arm Dumbbell Triceps Extension',
    muscles: ['Triceps'],
    cues: [
      'Use a light dumbbell and brace the upper arm',
      'Move mainly at the elbow',
      'Stop before shoulder or elbow discomfort',
    ],
    mistakes: ['Flaring the elbow', 'Arching the back', 'Forcing the range'],
    videoId: '2-LAMcpzODU',
  ),
  'dumbbell-overhead-triceps-extension': Exercise(
    id: 'dumbbell-overhead-triceps-extension',
    name: 'Two-Hand Dumbbell Overhead Extension',
    muscles: ['Triceps'],
    cues: [
      'Use one light dumbbell held by both hands',
      'Keep ribs down and elbows pointing forward',
      'Lower only as far as shoulders allow',
    ],
    mistakes: [
      'Flared elbows',
      'Lower-back arching',
      'Dropping the weight behind the head',
    ],
    videoId: '2-LAMcpzODU',
  ),
  'dumbbell-skull-crusher': Exercise(
    id: 'dumbbell-skull-crusher',
    name: 'Dumbbell Skull Crusher',
    muscles: ['Triceps'],
    cues: [
      'Lie on a stable bench with light dumbbells',
      'Keep upper arms mostly still',
      'Lower beside the head and extend smoothly',
    ],
    mistakes: [
      'Heavy weight near the face',
      'Elbows drifting wide',
      'Dropping quickly',
    ],
    videoId: '2-LAMcpzODU',
  ),
  'triceps-unclear': Exercise(
    id: 'triceps-unclear',
    name: 'Trainer movement — name needs confirmation',
    muscles: ['Triceps'],
    cues: [
      'Ask the trainer to demonstrate and name this movement',
      'Use a light pushdown only as a temporary placeholder',
      'Do not guess with a heavy dumbbell',
    ],
    mistakes: [
      'Copying a movement without knowing the setup',
      'Using a heavy load',
      'Working through elbow or shoulder pain',
    ],
    videoId: '2-LAMcpzODU',
  ),
  'single-arm-row': Exercise(
    id: 'single-arm-row',
    name: 'Single-Arm Dumbbell Row',
    muscles: ['Lats', 'Upper Back'],
    cues: [
      'Knee + same-side hand on the bench',
      'Pull the dumbbell to your hip',
      'Squeeze shoulder blade at the top',
    ],
    mistakes: ['Torso rotating to cheat the weight', 'Short range of motion'],
    gif: 'single-arm-row',
    videoId: 'FWJR5Ve8bnQ',
  ),
  // ---------------- CORE ----------------
  'plank': Exercise(
    id: 'plank',
    name: 'Front Plank',
    muscles: ['Deep Core', 'Shoulders'],
    cues: [
      'Straight line head → heels',
      'Squeeze glutes, pull elbows toward toes',
      'Breathe steadily — never hold breath',
    ],
    mistakes: ['Hips sagging (lower back strain)', 'Hips piked up'],
    gif: 'plank',
    videoId: 'pSHjTRCQxIw',
  ),
  'dead-bug': Exercise(
    id: 'dead-bug',
    name: 'Dead Bug',
    muscles: ['Deep Core'],
    cues: [
      'Lower back GLUED to the floor',
      'Extend opposite arm + leg slowly',
      'Exhale as you extend',
    ],
    mistakes: [
      'Back arching off the floor — shorten range',
      'Rushing the movement',
    ],
    gif: 'dead-bug',
    videoId: 'pSHjTRCQxIw',
  ),
  'bird-dog': Exercise(
    id: 'bird-dog',
    name: 'Bird Dog',
    muscles: ['Core', 'Lower Back', 'Glutes'],
    cues: [
      'All fours — extend opposite arm + leg level with torso',
      'Hips stay LEVEL (glass of water on your back)',
      '2s hold each rep',
    ],
    mistakes: ['Hips rotating', 'Back arching', 'Speed-repping'],
    videoId: 'pSHjTRCQxIw', // no bundled gif — video + cues
  ),
  // ---------------- CONDITIONING ----------------
  'farmers-walk': Exercise(
    id: 'farmers-walk',
    name: "Farmer's Walk",
    muscles: ['Grip', 'Traps', 'Core', 'Legs'],
    cues: [
      'Heaviest dumbbells you can HOLD with perfect posture',
      'Shoulders down and back, eyes forward',
      'Short controlled steps, keep breathing',
    ],
    mistakes: ['Leaning to one side', 'Shrugging shoulders to ears'],
    gif: 'farmers-walk',
    videoId: 'Fkzk_RqlYig',
  ),
  // ---------------- MOBILITY (Thursday circuit steps) ----------------
  'hip-flexor-lunge': Exercise(
    id: 'hip-flexor-lunge',
    name: 'Hip Flexor Lunge Stretch',
    muscles: ['Hip Flexors', 'Quads'],
    cues: [
      'Knee down, squeeze that glute, push hips forward',
      'Torso tall — feel the front-of-hip stretch',
      '30s each side, breathe',
    ],
    mistakes: [
      'Bouncing',
      'Arching the lower back instead of stretching the hip',
    ],
    gif: 'hip-flexor-stretch',
  ),
  'doorway-chest': Exercise(
    id: 'doorway-chest',
    name: 'Doorway Chest Stretch',
    muscles: ['Chest'],
    cues: [
      'Arm on doorframe at 90°, step through',
      'Feel chest stretch, 30s each side',
    ],
    mistakes: ['Shrugging the shoulder'],
  ),
  'cat-cow': Exercise(
    id: 'cat-cow',
    name: 'Cat-Cow',
    muscles: ['Spine', 'Core'],
    cues: [
      'Round up like a cat (exhale)',
      'Dip down like a cow (inhale)',
      '10 slow reps',
    ],
    mistakes: ['Rushing — move with breath'],
  ),
  'thread-needle': Exercise(
    id: 'thread-needle',
    name: 'Thread the Needle',
    muscles: ['Thoracic Spine'],
    cues: [
      'Reach arm under chest, shoulder to floor',
      '8 reps each side, slow',
    ],
    mistakes: ['Forcing rotation into pain'],
  ),
  'worlds-greatest': Exercise(
    id: 'worlds-greatest',
    name: "World's Greatest Stretch",
    muscles: ['Full Body'],
    cues: [
      'Lunge forward, front elbow to floor inside foot',
      'Rotate open toward ceiling, 5 reps each side',
    ],
    mistakes: ['Rushing'],
  ),
  'neck-tilts': Exercise(
    id: 'neck-tilts',
    name: 'Neck Side Tilts',
    muscles: ['Neck'],
    cues: ['Ear toward shoulder, opposite hand gently helps', '20s each side'],
    mistakes: ['Pulling hard — gentle only'],
  ),
};

/// Exercises referenced by the schedule.
List<Exercise> catalogByIds(List<String> ids) =>
    ids.map((id) => exercises[id]!).toList();
