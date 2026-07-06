#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_events_happy_path_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/get_events_happy_path_${CASE_SUFFIX}.status"
CREATE_STATUS_ONE="/tmp/get_events_happy_path_create_one_${CASE_SUFFIX}.status"
CREATE_STATUS_TWO="/tmp/get_events_happy_path_create_two_${CASE_SUFFIX}.status"
CREATE_STATUS_THREE="/tmp/get_events_happy_path_create_three_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE" \
    "$CREATE_STATUS_ONE" "$CREATE_STATUS_TWO" "$CREATE_STATUS_THREE"
}
trap cleanup_files EXIT

# Given
TITLE_EARLY="CV Happy Early ${CASE_SUFFIX}"
TITLE_MID="CV Happy Mid ${CASE_SUFFIX}"
TITLE_LATE="CV Happy Late ${CASE_SUFFIX}"

curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_MID}\",\"description\":\"mid event\",\"location\":\"Venue A\",\"startDate\":\"2024-03-15\",\"endDate\":\"2024-03-16\"}" > "$CREATE_STATUS_ONE"
[ "$(cat "$CREATE_STATUS_ONE")" = "201" ]

curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_EARLY}\",\"description\":\"early event\",\"location\":\"Venue B\",\"startDate\":\"2024-02-10\",\"endDate\":\"2024-02-11\"}" > "$CREATE_STATUS_TWO"
[ "$(cat "$CREATE_STATUS_TWO")" = "201" ]

curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_LATE}\",\"description\":\"late event\",\"location\":\"Venue C\",\"startDate\":\"2024-04-20\",\"endDate\":\"2024-04-21\"}" > "$CREATE_STATUS_THREE"
[ "$(cat "$CREATE_STATUS_THREE")" = "201" ]

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
python - "$RESPONSE_FILE" "$TITLE_EARLY" "$TITLE_MID" "$TITLE_LATE" <<'PY'
import json, sys
path, early, mid, late = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), 'response is not a JSON array'
lookup = {item['title']: item for item in data}
for title in (early, mid, late):
    assert title in lookup, f'missing event {title}'
assert lookup[early]['registrationCount'] == 0
assert lookup[mid]['registrationCount'] == 0
assert lookup[late]['registrationCount'] == 0
positions = {item['title']: idx for idx, item in enumerate(data) if item['title'] in (early, mid, late)}
assert positions[early] < positions[mid] < positions[late], positions
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_happy_path"

# Cleanup
# No cleanup endpoint exists for in-memory events; this test uses unique event titles for isolation.
