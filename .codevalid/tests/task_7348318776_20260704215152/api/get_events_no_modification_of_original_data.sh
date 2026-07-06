#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE_ONE="/tmp/get_events_no_modification_of_original_data_first_${CASE_SUFFIX}.json"
STATUS_FILE_ONE="/tmp/get_events_no_modification_of_original_data_first_${CASE_SUFFIX}.status"
RESPONSE_FILE_TWO="/tmp/get_events_no_modification_of_original_data_second_${CASE_SUFFIX}.json"
STATUS_FILE_TWO="/tmp/get_events_no_modification_of_original_data_second_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$RESPONSE_FILE_ONE" "$STATUS_FILE_ONE" "$RESPONSE_FILE_TWO" "$STATUS_FILE_TWO"
}
trap cleanup_files EXIT

# Given
TITLE_LATER="CV Original Order Later ${CASE_SUFFIX}"
TITLE_EARLIER="CV Original Order Earlier ${CASE_SUFFIX}"

code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_LATER}\",\"description\":\"later inserted first\",\"location\":\"Orig A\",\"startDate\":\"2024-03-01\",\"endDate\":\"2024-03-02\"}")"
[ "$code" = "201" ]
code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_EARLIER}\",\"description\":\"earlier inserted second\",\"location\":\"Orig B\",\"startDate\":\"2024-01-01\",\"endDate\":\"2024-01-02\"}")"
[ "$code" = "201" ]

# When
curl -sS -o "$RESPONSE_FILE_ONE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE_ONE"
curl -sS -o "$RESPONSE_FILE_TWO" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE_TWO"

# Then
[ "$(cat "$STATUS_FILE_ONE")" = "200" ]
[ "$(cat "$STATUS_FILE_TWO")" = "200" ]
python - "$RESPONSE_FILE_ONE" "$RESPONSE_FILE_TWO" "$TITLE_LATER" "$TITLE_EARLIER" <<'PY'
import json, sys
first_path, second_path, later, earlier = sys.argv[1:5]
with open(first_path, 'r', encoding='utf-8') as f:
    first = json.load(f)
with open(second_path, 'r', encoding='utf-8') as f:
    second = json.load(f)
first_lookup = {item['title']: idx for idx, item in enumerate(first)}
second_lookup = {item['title']: idx for idx, item in enumerate(second)}
assert first_lookup[earlier] < first_lookup[later], first_lookup
assert second_lookup[earlier] < second_lookup[later], second_lookup
assert first_lookup[earlier] == second_lookup[earlier]
assert first_lookup[later] == second_lookup[later]
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_no_modification_of_original_data"

# Cleanup
# No cleanup endpoint exists for in-memory events; unique titles provide isolation.
