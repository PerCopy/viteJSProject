#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TITLE="Networking Mixer 2024 ${CASE_SUFFIX}"
DESCRIPTION="Professional networking event ${CASE_SUFFIX}"
LOCATION="Miami Beach Hotel ${CASE_SUFFIX}"
START_DATE="2024-05-30"
END_DATE="2024-05-30"
CREATE_RESPONSE_FILE="/tmp/created_event_available_for_later_access_create_${CASE_SUFFIX}.json"
CREATE_STATUS_FILE="/tmp/created_event_available_for_later_access_create_${CASE_SUFFIX}.status"
LIST_RESPONSE_FILE="/tmp/created_event_available_for_later_access_list_${CASE_SUFFIX}.json"
LIST_STATUS_FILE="/tmp/created_event_available_for_later_access_list_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$CREATE_RESPONSE_FILE" "$CREATE_STATUS_FILE" "$LIST_RESPONSE_FILE" "$LIST_STATUS_FILE"; }
trap cleanup_files EXIT

# Given
: "Event store is accessible and the test uses a unique event title for retrieval isolation"

# When
curl -sS -o "$CREATE_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE}\",\"description\":\"${DESCRIPTION}\",\"location\":\"${LOCATION}\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}" > "$CREATE_STATUS_FILE"
[ "$(cat "$CREATE_STATUS_FILE")" = "201" ]
EVENT_ID="$(python - <<'PY' "$CREATE_RESPONSE_FILE"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    data = json.load(fh)
print(data['id'])
PY
)"
curl -sS -o "$LIST_RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST_STATUS_FILE"

# Then
[ "$(cat "$LIST_STATUS_FILE")" = "200" ]
python - <<'PY' "$LIST_RESPONSE_FILE" "$EVENT_ID" "$TITLE" "$DESCRIPTION" "$LOCATION" "$START_DATE" "$END_DATE"
import json, sys
path, event_id, title, description, location, start_date, end_date = sys.argv[1:]
with open(path, 'r', encoding='utf-8') as fh:
    events = json.load(fh)
match = None
for event in events:
    if event.get('id') == event_id:
        match = event
        break
assert match is not None, f'event {event_id} not found in GET /api/events response'
assert match.get('title') == title, match
assert match.get('description') == description, match
assert match.get('location') == location, match
assert match.get('startDate') == start_date, match
assert match.get('endDate') == end_date, match
assert match.get('registrationCount') == 0, match
PY

# Cleanup
: "No cleanup endpoint exists for the in-memory store; test data is uniquely namespaced"

echo "CODEVALID_TEST_ASSERTION_OK:created_event_available_for_later_access"
