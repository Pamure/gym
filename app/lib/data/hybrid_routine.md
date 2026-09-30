# IronForge routine note

The canonical routine is in `app/lib/data/program.dart` and
`knowledge/01-training-program.md`. This file is kept as a human-readable
migration note so the original coach instruction is not lost.

## Coach instruction recorded verbatim (spelling preserved)

- Monday: Flate bench 4x12; Incline bench 3x12; Dicline bench 3x12; Flate dumble fly 3x15; Chest press machine 4x10; Pack deck fly 3x10.
- Tuesday: Dumble press 4x10; Side rase 4x10; Frnt rase 3x10; Revers 3x12; Shrugs 4x12.
- Wednesday: Lat pull 4x10; Behind lat pull; One arm machine 3x10; Seated 4x10; Close grip 3x12; Hyper extn 3x10.
- Thursday: Barbell curl 4x10; Dumble curl 3x10; Cable curl 3x10; Pri chaire 3x10; Hammer 4x12.
- Friday: Single hand Dumble 3x10; Double hand Dumble 4x10; Pully push down 4x10; Dumble scul creashur 3x10; Roughf nd toughf 3x10.
- Saturday: Squats 4x12; Leg press 3x10; Pron Leg curl 4x10; Leg extn 3x12; Calves 3x15.

## App migration decision

This list is now available in the app as **Gym trainer plan**. The trainer's
labels and original targets remain visible so the athlete can ask about the
right machine at UFC Okhla. IronForge does not silently guess unclear names:
“Behind lat pull” is shown as a safer front-of-neck pulldown replacement, and
“Roughf nd toughf” is marked for trainer clarification with a light pushdown
placeholder until the trainer demonstrates it.

The default starting dose is deliberately smaller than the written target:
one set in the first month, then build toward two sets only when technique and
recovery are good. **Starter guidance** remains available as the separate
Monday/Wednesday/Friday full-body option, with optional easy movement on
Tuesday/Thursday/Saturday and full rest Sunday. The two modes are labelled so
the user's trainer plan is not confused with IronForge's conservative coaching.

Every main exercise card includes:

- the equipment and where to find it;
- a short setup description;
- GIF plus external tutorial when available;
- form cues and common mistakes;
- same-pattern alternatives when the machine is busy or inaccessible;
- rest guidance and a log for clean sets.

The plan is not a medical prescription. Ask the UFC gym coach to demonstrate
the first light set, especially for the bench, hinge and leg press.
