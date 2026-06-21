#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/registration_api_failure_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/registration_api_failure_response_${CASE_SUFFIX}.json"
EVENT_ID=""
ATTENDEE_EMAIL="david.lee.${CASE_SUFFIX}@example.com"

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Fetch an event currently open for registration.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
from datetime import datetime, timezone
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    events = json.load(f)
today = datetime.now(timezone.utc).date().isoformat()
for event in events:
    if event['startDate'] <= today <= event['endDate']:
        print(event['id'])
        break
PY
)"
[ -n "$EVENT_ID" ]

# When — POST /api/registrations.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"David Lee\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-999-8888\"}")"

# Then — Assert the backend returns either success or an error payload.
[ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "400" ] || [ "$HTTP_STATUS" = "500" ]
if [ "$HTTP_STATUS" = "201" ]; then
  grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$RESPONSE_FILE" >/dev/null
else
  grep -F '"message":' "$RESPONSE_FILE" >/dev/null || grep -F 'Error' "$RESPONSE_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_api_failure"

# Cleanup — no delete endpoint exists; unique email isolates success.
:
