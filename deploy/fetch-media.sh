#!/usr/bin/env bash
# IronForge media fetch — downloads CC-BY-SA exercise GIFs from the open
# hasaneyldrm/exercises-dataset (https://github.com/hasaneyldrm/exercises-dataset).
# Usage: ./fetch-media.sh   (run from repo root)
set -euo pipefail
cd "$(dirname "$0")/.."

BASE="https://raw.githubusercontent.com/hasaneyldrm/exercises-dataset/main/videos"
APP_DIR="app/assets/gifs"
WEB_DIR="server/media"
mkdir -p "$APP_DIR" "$WEB_DIR"

# our_key -> dataset file (verified 2026-09-05 against data/exercises.json)
declare -A MAP=(
  [bench-press]="0025-EIeI8Vf.gif"
  [overhead-press]="0091-kTbSH9h.gif"
  [incline-dumbbell-press]="0314-ns0SIbU.gif"
  [tricep-pushdown]="0200-dU605di.gif"
  [lateral-raise]="0334-DsgkuIt.gif"
  [dumbbell-bench-press]="0289-SpYC0Kp.gif"
  [dumbbell-shoulder-press]="0426-A6wtbuL.gif"
  [back-squat]="1436-Gnfo4FM.gif"
  [goblet-squat]="1760-yn8yg1r.gif"
  [front-squat]="0042-zG0zs85.gif"
  [romanian-deadlift]="0085-wQ2c4XD.gif"
  [leg-press]="0739-10Z2DXU.gif"
  [lying-leg-curl]="0586-17lJ1kr.gif"
  [standing-calf-raise]="0605-ykUOVze.gif"
  [deadlift]="0032-ila4NZS.gif"
  [bent-over-row]="0027-eZyBC3j.gif"
  [lat-pulldown]="2330-LEprlgG.gif"
  [bicep-curl]="0416-3s4NnTh.gif"
  [single-arm-row]="0292-C0MA9bC.gif"
  [plank]="0464-CosupLu.gif"
  [dead-bug]="0276-iny3m5y.gif"
  [farmers-walk]="2133-qPEzJjA.gif"
  [hip-flexor-stretch]="1564-tFGKm99.gif"
)

ok=0; fail=0
for key in "${!MAP[@]}"; do
  src="$BASE/${MAP[$key]}"
  for dest in "$APP_DIR/$key.gif" "$WEB_DIR/$key.gif"; do
    curl -sfL --max-time 60 -o "$dest" "$src" || { echo "FAIL $key"; fail=$((fail+1)); continue 2; }
    # verify real GIF and sane size (some upstream files are oddly huge/small)
    if ! file "$dest" | grep -qi "gif image"; then
      echo "NOT-GIF $key"; rm -f "$dest"; fail=$((fail+1)); continue 2
    fi
    sz=$(stat -c%s "$dest")
    if [ "$sz" -lt 20000 ] || [ "$sz" -gt 2000000 ]; then
      echo "BAD-SIZE $key ($sz)"; rm -f "$dest"; fail=$((fail+1)); continue 2
    fi
  done
  echo "OK $key"; ok=$((ok+1))
done

# licenses/attribution
cat > app/assets/gifs/ATTRIBUTION.txt <<'EOF'
Exercise demonstration GIFs bundled in IronForge are from the open
hasaneyldrm/exercises-dataset (https://github.com/hasaneyldrm/exercises-dataset),
licensed CC-BY-SA 3.0 / AGPL-3.0 (dataset). Attribution: exercise visual media
from community open exercise datasets (hasaneyldrm/exercises-dataset).
Personal use only — do not redistribute the media commercially.
EOF
cp app/assets/gifs/ATTRIBUTION.txt "$WEB_DIR/ATTRIBUTION.txt"

echo "DONE ok=$ok fail=$fail"
[ "$fail" -eq 0 ]
