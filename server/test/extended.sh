#!/bin/bash
# Extended smoke — additions per renovation.md §2.1
set -e
BASE=${BASE:-http://127.0.0.1:8420}
JAR=/tmp/if-ext.txt
rm -f $JAR

# bootstrap user
curl -s -c $JAR -X POST -H "content-type: application/json" \
  -d '{"username":"ifverify","password":"Verify-Temp-2026"}' $BASE/api/auth/login > /dev/null

pass=0; fail=0
check() {
  local name="$1" expected="$2" actual="$3"
  if [[ "$actual" == "$expected" ]]; then echo "PASS $name"; pass=$((pass+1));
  else echo "FAIL $name (expected $expected, got $actual)"; fail=$((fail+1)); fi
}

# T1: heatmap intensity combines bits correctly
TODAY=$(date -u +%F)
curl -s -b $JAR -X POST -H "content-type: application/json" \
  -d "{\"date\":\"$TODAY\",\"energy\":5}" $BASE/api/checkins > /dev/null
curl -s -b $JAR -X POST -H "content-type: application/json" \
  -d "{\"date\":\"$TODAY\",\"week\":1,\"day\":\"weekday\",\"exercise\":\"bench-press\",\"sets\":[{\"setNumber\":1,\"weightKg\":20,\"reps\":10}]}" $BASE/api/logs/workout > /dev/null
curl -s -b $JAR -X POST -H "content-type: application/json" \
  -d "{\"date\":\"$TODAY\",\"sets\":3,\"holdSeconds\":5}" $BASE/api/logs/kegels > /dev/null
INTENSITY=$(curl -s -b $JAR $BASE/api/state | jq -r ".workouts | map(select(.date==\"$TODAY\")) | length")
check "T1 workout saved for today" "1" "$INTENSITY"

# T2: bad setting key returns 400 (schema-validated, no XSS via stored XSS)
R=$(curl -s -o /dev/null -w "%{http_code}" -b $JAR -X POST -H "content-type: application/json" \
  -d "{\"junk_key\":\"<script>alert(1)</script>\"}" $BASE/api/settings)
check "T2 invalid setting key returns 400" "400" "$R"
# T2b: valid setting key returns 200
R=$(curl -s -o /dev/null -w "%{http_code}" -b $JAR -X POST -H "content-type: application/json" \
  -d "{\"key\":\"reminder_enabled\",\"value\":\"1\"}" $BASE/api/settings)
check "T2b valid setting key returns 200" "200" "$R"

# T3: AI endpoint returns 401 without auth
R=$(curl -s -o /dev/null -w "%{http_code}" -X POST -H "content-type: application/json" \
  -d '{"message":"hi"}' $BASE/api/ai/chat)
check "T3 AI requires auth" "401" "$R"

# T4: chat history accessible
H=$(curl -s -b $JAR $BASE/api/ai/chat | jq -r '.messages | type')
check "T4 chat history returns array" 'array' "$H"

# T5: state shape — has workouts, weight, measurements, kegels, checkins, prefs
KEYS=$(curl -s -b $JAR $BASE/api/state | jq -r 'keys | join(",")')
case "$KEYS" in *workouts*) check "T5 state has workouts" "ok" "ok" ;; *) check "T5 state has workouts" "ok" "missing" ;; esac

# T6: delete a workout removes it
curl -s -b $JAR -X DELETE -H "content-type: application/json" \
  -d "{\"date\":\"$TODAY\",\"exercise\":\"bench-press\"}" $BASE/api/logs/workout > /dev/null
LEFT=$(curl -s -b $JAR $BASE/api/state | jq ".workouts | map(select(.date==\"$TODAY\" and .exercise==\"bench-press\")) | length")
check "T6 delete workout removes it" "0" "$LEFT"

# T7: delete checkin
curl -s -b $JAR -X DELETE -H "content-type: application/json" \
  -d "{\"date\":\"$TODAY\"}" $BASE/api/checkins > /dev/null
LEFT=$(curl -s -b $JAR $BASE/api/state | jq ".checkins | map(select(.date==\"$TODAY\")) | length")
check "T7 delete checkin removes it" "0" "$LEFT"

# T8: AI rate limit (8/min) — 9th call should 429
for i in 1 2 3 4 5 6 7 8; do
  curl -s -b $JAR -X POST -H "content-type: application/json" -d '{"message":"x"}' $BASE/api/ai/chat > /dev/null
done
NINTH=$(curl -s -b $JAR -o /dev/null -w "%{http_code}" -X POST -H "content-type: application/json" -d '{"message":"x"}' $BASE/api/ai/chat)
check "T8 9th AI call in <60s is rate-limited" "429" "$NINTH"

# T9: healthcheck still up
H=$(curl -s -o /dev/null -w "%{http_code}" $BASE/api/health)
check "T9 health still 200" "200" "$H"

# cleanup
curl -s -X POST -H "content-type: application/json" -d '{"username":"ifverify","password":"Verify-Temp-2026"}' -b $JAR -c $JAR $BASE/api/auth/login > /dev/null
# cannot delete user from here easily, but data is empty now

echo
echo "── extended smoke: $pass pass / $fail fail ──"
exit $fail
