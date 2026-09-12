#!/usr/bin/env bash
# IronForge backend smoke test — boots the server against a throwaway DB and
# exercises every auth + data endpoint. Exit 0 = pass.
set -euo pipefail
cd "$(dirname "$0")/.."

SMOKE_DIR="$(mktemp -d /tmp/ironforge-smoke-XXXXXX)"
export DATA_DIR="$SMOKE_DIR/data"
export PORT="18420"
mkdir -p "$SMOKE_DIR/data"
printf '{"username":"smokeuser","password":"SmokeTest-Pass-123"}' > "$SMOKE_DIR/data/bootstrap.json"

node src/index.js > "$SMOKE_DIR/server.log" 2>&1 &
SRV=$!
trap 'kill $SRV 2>/dev/null || true; rm -rf "$SMOKE_DIR"' EXIT

# wait for boot
for i in $(seq 1 30); do
  curl -sf "http://127.0.0.1:$PORT/api/health" && break || sleep 0.3
done

JAR=$(mktemp /tmp/ironforge-cookies-XXXXXX)
pass=0

check() { # name expected actual
  if [ "$2" = "$3" ]; then pass=$((pass+1)); echo "PASS $1"; else echo "FAIL $1 (want=$2 got=$3)"; exit 1; fi
}

# 1. health
check "health" '{"ok":true}' "$(curl -sf "http://127.0.0.1:$PORT/api/health")"
# 2. unauthenticated state → 401
check "state-unauth" '401' "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$PORT/api/state")"
# 3. wrong password → 401
check "bad-login" '401' "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'content-type: application/json' -d '{"username":"smokeuser","password":"wrong"}' "http://127.0.0.1:$PORT/api/auth/login")"
# 4. good login → 200 + cookie, NO totp fields in response
resp=$(curl -s -c "$JAR" -X POST -H 'content-type: application/json' -d '{"username":"smokeuser","password":"SmokeTest-Pass-123"}' "http://127.0.0.1:$PORT/api/auth/login")
check "good-login" 'true' "$(echo "$resp" | jq -r .ok)"
check "no-totp-field" 'null' "$(echo "$resp" | jq '.needsTotpSetup')"
# 5. /api/me has no totpEnabled
me=$(curl -sf -b "$JAR" "http://127.0.0.1:$PORT/api/me")
check "me" 'smokeuser' "$(echo "$me" | jq -r .username)"
check "me-no-totp" 'null' "$(echo "$me" | jq '.totpEnabled')"
# 6. log workout
check "log-workout" '{"ok":true,"saved":3}' "$(curl -sf -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"2026-09-05","week":1,"day":"monday","exercise":"bench-press","sets":[{"setNumber":1,"weightKg":20,"reps":10},{"setNumber":2,"weightKg":20,"reps":10},{"setNumber":3,"weightKg":20,"reps":9}]}' "http://127.0.0.1:$PORT/api/logs/workout")"
# 7. log weight + measurement + kegel
curl -sf -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"2026-09-05","kg":68}' "http://127.0.0.1:$PORT/api/logs/weight" > /dev/null
curl -sf -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"2026-09-05","waistCm":88,"chestCm":95,"armCm":32}' "http://127.0.0.1:$PORT/api/logs/measurements" > /dev/null
curl -sf -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"2026-09-05","sets":3,"holdSeconds":3}' "http://127.0.0.1:$PORT/api/logs/kegels" > /dev/null
# 8. state grouped + present
st=$(curl -sf -b "$JAR" "http://127.0.0.1:$PORT/api/state")
check "state-workouts" '1' "$(echo "$st" | jq '.workouts | length')"
check "state-sets-grouped" '3' "$(echo "$st" | jq '.workouts[0].sets | length')"
check "state-set1" '20' "$(echo "$st" | jq '.workouts[0].sets[0].weightKg')"
check "state-weight" '68' "$(echo "$st" | jq -r '.bodyWeight[0].kg')"
check "state-waist" '88' "$(echo "$st" | jq -r '.measurements[0].waistCm')"
check "state-kegels" '1' "$(echo "$st" | jq '.kegels | length')"
check "state-kegels-sets" '3' "$(echo "$st" | jq -r '.kegels[0].sets')"
# 9. schema validation: garbage body → 400
check "bad-body" '400' "$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"x","sets":[]}' "http://127.0.0.1:$PORT/api/logs/workout")"
# 10. logout kills session
check "logout" '{"ok":true}' "$(curl -sf -b "$JAR" -c "$JAR" -X POST "http://127.0.0.1:$PORT/api/auth/logout")"
check "state-after-logout" '401' "$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" "http://127.0.0.1:$PORT/api/state")"
# 11. re-login then check-in upsert + delete
curl -sf -c "$JAR" -X POST -H 'content-type: application/json' -d '{"username":"smokeuser","password":"SmokeTest-Pass-123"}' "http://127.0.0.1:$PORT/api/auth/login" > /dev/null
curl -sf -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"2026-09-06","energy":4,"sleepHours":7.5,"waterL":3,"mood":"good"}' "http://127.0.0.1:$PORT/api/checkins" > /dev/null
check "checkin-in-state" '4' "$(curl -sf -b "$JAR" http://127.0.0.1:$PORT/api/state | jq -r '.checkins[0].energy')"
# 12. workout edit = same endpoint upsert (change set 1 to 25kg), then delete exercise
curl -sf -b "$JAR" -X POST -H 'content-type: application/json' -d '{"date":"2026-09-05","week":1,"day":"monday","exercise":"bench-press","sets":[{"setNumber":1,"weightKg":25,"reps":8},{"setNumber":2,"weightKg":20,"reps":10},{"setNumber":3,"weightKg":20,"reps":9}]}' "http://127.0.0.1:$PORT/api/logs/workout" > /dev/null
check "workout-edited" '25' "$(curl -sf -b "$JAR" http://127.0.0.1:$PORT/api/state | jq -r '.workouts[0].sets[0].weightKg')"
check "delete-workout" '{"ok":true,"deleted":3}' "$(curl -sf -b "$JAR" -X DELETE -H 'content-type: application/json' -d '{"date":"2026-09-05","exercise":"bench-press"}' "http://127.0.0.1:$PORT/api/logs/workout")"
# 13. weight + measurements + kegel delete/edit
check "delete-weight" '{"ok":true,"deleted":1}' "$(curl -sf -b "$JAR" -X DELETE -H 'content-type: application/json' -d '{"date":"2026-09-05"}' "http://127.0.0.1:$PORT/api/logs/weight")"
check "delete-measurements" '{"ok":true,"deleted":1}' "$(curl -sf -b "$JAR" -X DELETE -H 'content-type: application/json' -d '{"date":"2026-09-05"}' "http://127.0.0.1:$PORT/api/logs/measurements")"
KGID=$(curl -sf -b "$JAR" http://127.0.0.1:$PORT/api/state | jq -r '.kegels[0].id')
check "kegel-edit" '{"ok":true}' "$(curl -sf -b "$JAR" -X PUT -H 'content-type: application/json' -d "{\"id\":$KGID,\"sets\":5,\"holdSeconds\":8}" "http://127.0.0.1:$PORT/api/logs/kegels")"
check "kegel-delete" '{"ok":true,"deleted":1}' "$(curl -sf -b "$JAR" -X DELETE -H 'content-type: application/json' -d "{\"id\":$KGID}" "http://127.0.0.1:$PORT/api/logs/kegels")"
# 14. AI chat: empty message rejected (400) regardless of key presence
check "ai-empty-rejected" '400' "$(curl -s -o /dev/null -w '%{http_code}' -b "$JAR" -X POST -H 'content-type: application/json' -d '{"message":""}' "http://127.0.0.1:$PORT/api/ai/chat")"
# 15. password change flow (old session invalidated, new password works)
curl -sf -c "$JAR" -X POST -H 'content-type: application/json' -d '{"username":"smokeuser","password":"SmokeTest-Pass-123"}' "http://127.0.0.1:$PORT/api/auth/login" > /dev/null
check "change-password" '{"ok":true}' "$(curl -sf -b "$JAR" -c "$JAR" -X POST -H 'content-type: application/json' -d '{"currentPassword":"SmokeTest-Pass-123","newPassword":"New-Pass-45678"}' "http://127.0.0.1:$PORT/api/auth/password")"
check "old-password-dead" '401' "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'content-type: application/json' -d '{"username":"smokeuser","password":"SmokeTest-Pass-123"}' "http://127.0.0.1:$PORT/api/auth/login")"
check "new-password-works" '200' "$(curl -s -o /dev/null -w '%{http_code}' -X POST -H 'content-type: application/json' -d '{"username":"smokeuser","password":"New-Pass-45678"}' "http://127.0.0.1:$PORT/api/auth/login")"

echo "=== SMOKE PASS ($pass checks) ==="
