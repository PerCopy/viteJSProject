#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_RESPONSE="/tmp/get_events_registration_count_accurate_event_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/get_events_registration_count_accurate_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/get_events_registration_count_accurate_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$EVENT_RESPONSE" "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given
TITLE_ONE="CV Count One ${CASE_SUFFIX}"
TITLE_TWO="CV Count Two ${CASE_SUFFIX}"
TITLE_THREE="CV Count Three ${CASE_SUFFIX}"

create_event() {
  title="$1"
  start_date="$2"
  end_date="$3"
  status="$(curl -sS -o "$EVENT_RESPONSE" -w '%{http_code}' -X POST "$BASE_URL/api/events" \
    -H 'Content-Type: application/json' \
    --data "{\"title\":\"${title}\",\"description\":\"count test\",\"location\":\"Count Hall\",\"startDate\":\"${start_date}\",\"endDate\":\"${end_date}\"}")"
  [ "$status" = "201" ]
  python - "$EVENT_RESPONSE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(json.load(f)['id'])
PY
}

EVENT_ID_ONE="$(create_event "$TITLE_ONE" "2024-05-01" "2024-05-02")"
EVENT_ID_TWO="$(create_event "$TITLE_TWO" "2024-05-03" "2024-05-04")"
EVENT_ID_THREE="$(create_event "$TITLE_THREE" "2024-05-05" "2024-05-06")"

register_for_event() {
  event_id="$1"
  idx="$2"
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/registrations" \
    -H 'Content-Type: application/json' \
    --data "{\"eventId\":\"${event_id}\",\"name\":\"Attendee ${idx} ${CASE_SUFFIX}\",\"email\":\"attendee-${idx}-${CASE_SUFFIX}@example.com\",\"phone\":\"555-010-${idx}\"}")"
  [ "$code" = "201" ]
}

register_for_event "$EVENT_ID_ONE" 1
register_for_event "$EVENT_ID_ONE" 2
register_for_event "$EVENT_ID_ONE" 3
register_for_event "$EVENT_ID_ONE" 4
register_for_event "$EVENT_ID_ONE" 5
register_for_event "$EVENT_ID_THREE" 31
register_for_event "$EVENT_ID_THREE" 32
register_for_event "$EVENT_ID_THREE" 33
register_for_event "$EVENT_ID_THREE" 34
register_for_event "$EVENT_ID_THREE" 35
register_for_event "$EVENT_ID_THREE" 36
register_for_event "$EVENT_ID_THREE" 37
register_for_event "$EVENT_ID_THREE" 38
register_for_event "$EVENT_ID_THREE" 39
register_for_event "$EVENT_ID_THREE" 40
register_for_event "$EVENT_ID_THREE" 41
register_for_event "$EVENT_ID_THREE" 42

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
python - "$RESPONSE_FILE" "$TITLE_ONE" "$TITLE_TWO" "$TITLE_THREE" <<'PY'
import json, sys
path, one, two, three = sys.argv[1:5]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
lookup = {item['title']: item for item in data}
assert lookup[one]['registrationCount'] == 5, lookup[one]
assert lookup[two]['registrationCount'] == 0, lookup[two]
assert lookup[three]['registrationCount'] == 12, lookup[three]
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_registration_count_accurate"

# Cleanup
# No cleanup endpoint exists for in-memory events/registrations; unique data provides isolation.
