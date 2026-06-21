#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/boundary_date_exactly_on_start_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/boundary_date_exactly_on_start_response_${CASE_SUFFIX}.json"
EVENT_ID=""
ATTENDEE_EMAIL="startdate.${CASE_SUFFIX}@example.com"

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Fetch events and select one starting today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
from datetime import datetime, timezone
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    events = json.load(f)
today = datetime.now(timezone.utc).date().isoformat()
for event in events:
    if event['startDate'] == today:
        print(event['id'])
        break
PY
)"
[ -n "$EVENT_ID" ]

# When — POST /api/registrations on the event start date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Start Date User\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-111-0000\"}")"

# Then — HTTP 201 confirms boundary-inclusive start date handling.
[ "$HTTP_STATUS" = "201" ]
grep -F "\"eventId\":\"${EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:boundary_date_exactly_on_start"

# Cleanup — no delete endpoint exists; unique email isolates success.
:
