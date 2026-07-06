#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_events_handles_multiple_same_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/get_events_handles_multiple_same_date_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given
START_DATE="2024-07-01"
END_DATE="2024-07-02"
TITLE_ONE="CV Same Date One ${CASE_SUFFIX}"
TITLE_TWO="CV Same Date Two ${CASE_SUFFIX}"
TITLE_THREE="CV Same Date Three ${CASE_SUFFIX}"

for title in "$TITLE_ONE" "$TITLE_TWO" "$TITLE_THREE"
do
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"${title}\",\"description\":\"same start date\",\"location\":\"Shared Venue\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}")"
  [ "$code" = "201" ]
done

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
python - "$RESPONSE_FILE" "$TITLE_ONE" "$TITLE_TWO" "$TITLE_THREE" "$START_DATE" <<'PY'
import json, sys
path, one, two, three, start_date = sys.argv[1:6]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
lookup = {item['title']: item for item in data}
for title in (one, two, three):
    assert title in lookup, f'missing {title}'
    assert lookup[title]['startDate'] == start_date, lookup[title]
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_handles_multiple_same_date"

# Cleanup
# No cleanup endpoint exists for in-memory events; unique titles provide isolation.
