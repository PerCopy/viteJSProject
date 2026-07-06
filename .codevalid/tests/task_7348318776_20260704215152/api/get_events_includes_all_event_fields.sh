#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
CREATE_RESPONSE="/tmp/get_events_includes_all_event_fields_create_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/get_events_includes_all_event_fields_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/get_events_includes_all_event_fields_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$CREATE_RESPONSE" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given
TITLE="Annual Tech Conference ${CASE_SUFFIX}"
DESCRIPTION="A comprehensive technology conference covering AI, cloud, and security ${CASE_SUFFIX}"
LOCATION="Grand Convention Center, 123 Main St ${CASE_SUFFIX}"
START_DATE="2024-05-15"
END_DATE="2024-05-17"
CREATE_CODE="$(curl -sS -o "$CREATE_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE}\",\"description\":\"${DESCRIPTION}\",\"location\":\"${LOCATION}\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}")"
[ "$CREATE_CODE" = "201" ]

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
python - "$RESPONSE_FILE" "$TITLE" "$DESCRIPTION" "$LOCATION" "$START_DATE" "$END_DATE" <<'PY'
import json, sys
path, title, description, location, start_date, end_date = sys.argv[1:7]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
match = None
for item in data:
    if item.get('title') == title:
        match = item
        break
assert match is not None, 'created event not found'
assert match['description'] == description
assert match['location'] == location
assert match['startDate'] == start_date
assert match['endDate'] == end_date
assert 'registrationCount' in match
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_includes_all_event_fields"

# Cleanup
# No cleanup endpoint exists for in-memory events; unique title provides isolation.
