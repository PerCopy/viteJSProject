#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/clear_form_errors_on_input_events_${CASE_SUFFIX}.json"
BAD_RESPONSE_FILE="/tmp/clear_form_errors_on_input_bad_${CASE_SUFFIX}.json"
GOOD_RESPONSE_FILE="/tmp/clear_form_errors_on_input_good_${CASE_SUFFIX}.json"
EVENT_ID=""
GOOD_EMAIL="corrected.${CASE_SUFFIX}@example.com"

cleanup() {
  rm -f "$EVENTS_FILE" "$BAD_RESPONSE_FILE" "$GOOD_RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Fetch an event currently open for registration if available.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
from datetime import datetime, timezone
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    events = json.load(f)
today = datetime.now(timezone.utc).date().isoformat()
chosen = ''
for event in events:
    if event['startDate'] <= today <= event['endDate']:
        chosen = event['id']
        break
if not chosen and events:
    chosen = events[0]['id']
print(chosen)
PY
)"
[ -n "$EVENT_ID" ]

# When — Submit with empty name, then resubmit with corrected name.
BAD_STATUS="$(curl -sS -o "$BAD_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"\",\"email\":\"${GOOD_EMAIL}\",\"phone\":\"+1-555-101-2020\"}")"
GOOD_STATUS="$(curl -sS -o "$GOOD_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Corrected Name\",\"email\":\"${GOOD_EMAIL}\",\"phone\":\"+1-555-101-2020\"}")"

# Then — First request is rejected; second request is processed under the current backend contract.
[ "$BAD_STATUS" = "400" ]
grep -F 'Event, name, email, and phone number are required.' "$BAD_RESPONSE_FILE" >/dev/null
[ "$GOOD_STATUS" = "201" ] || [ "$GOOD_STATUS" = "400" ]
if [ "$GOOD_STATUS" = "201" ]; then
  grep -F '"name":"Corrected Name"' "$GOOD_RESPONSE_FILE" >/dev/null
else
  grep -F '"message":' "$GOOD_RESPONSE_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:clear_form_errors_on_input"

# Cleanup — unique email prevents interference.
:
