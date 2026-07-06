#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ONE_TITLE="Tech Conference ${CASE_SUFFIX}"
EVENT_TWO_TITLE="Music Festival ${CASE_SUFFIX}"
RESPONSE_ONE="/tmp/get_events_happy_path_create_one_${CASE_SUFFIX}.json"
STATUS_ONE="/tmp/get_events_happy_path_create_one_${CASE_SUFFIX}.status"
RESPONSE_TWO="/tmp/get_events_happy_path_create_two_${CASE_SUFFIX}.json"
STATUS_TWO="/tmp/get_events_happy_path_create_two_${CASE_SUFFIX}.status"
LIST_RESPONSE="/tmp/get_events_happy_path_list_${CASE_SUFFIX}.json"
LIST_STATUS="/tmp/get_events_happy_path_list_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$RESPONSE_ONE" "$STATUS_ONE" "$RESPONSE_TWO" "$STATUS_TWO" "$LIST_RESPONSE" "$LIST_STATUS"
}
trap cleanup_files EXIT

# Given — create isolated events through the public API so they are available for later access
curl -sS -o "$RESPONSE_ONE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_ONE_TITLE}\",\"description\":\"Annual tech event\",\"location\":\"San Francisco\",\"startDate\":\"2024-06-01\",\"endDate\":\"2024-06-03\"}" > "$STATUS_ONE"
[ "$(cat "$STATUS_ONE")" = "201" ]
grep -F '"title":"'"${EVENT_ONE_TITLE}"'"' "$RESPONSE_ONE" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_ONE" >/dev/null

curl -sS -o "$RESPONSE_TWO" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TWO_TITLE}\",\"description\":\"Summer music festival\",\"location\":\"Los Angeles\",\"startDate\":\"2024-07-15\",\"endDate\":\"2024-07-17\"}" > "$STATUS_TWO"
[ "$(cat "$STATUS_TWO")" = "201" ]
grep -F '"title":"'"${EVENT_TWO_TITLE}"'"' "$RESPONSE_TWO" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_TWO" >/dev/null

# When — retrieve the events list
curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$LIST_STATUS"

# Then — verify the created events are returned, sorted by startDate ascending, and include counts
STATUS="$(cat "$LIST_STATUS")"
[ "$STATUS" = "200" ]
grep -F '"title":"'"${EVENT_ONE_TITLE}"'"' "$LIST_RESPONSE" >/dev/null
grep -F '"title":"'"${EVENT_TWO_TITLE}"'"' "$LIST_RESPONSE" >/dev/null
grep -F '"location":"San Francisco"' "$LIST_RESPONSE" >/dev/null
grep -F '"location":"Los Angeles"' "$LIST_RESPONSE" >/dev/null
grep -F '"startDate":"2024-06-01"' "$LIST_RESPONSE" >/dev/null
grep -F '"startDate":"2024-07-15"' "$LIST_RESPONSE" >/dev/null
grep -F '"registrationCount":0' "$LIST_RESPONSE" >/dev/null

python - <<'PY' "$LIST_RESPONSE" "$EVENT_ONE_TITLE" "$EVENT_TWO_TITLE"
import json, sys
path, title1, title2 = sys.argv[1:4]
with open(path, 'r', encoding='utf-8') as f:
    events = json.load(f)
matching = [e for e in events if e.get('title') in (title1, title2)]
assert len(matching) == 2, matching
assert matching[0]['title'] == title1, matching
assert matching[1]['title'] == title2, matching
assert matching[0]['startDate'] <= matching[1]['startDate'], matching
assert matching[0]['registrationCount'] == 0, matching
assert matching[1]['registrationCount'] == 0, matching
PY

# Cleanup — no API delete exists for events in provided public API; test data remains in in-memory store only for container lifetime

echo "CODEVALID_TEST_ASSERTION_OK:get_events_happy_path"
