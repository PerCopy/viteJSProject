#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/register_within_date_range_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/register_within_date_range_response_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/register_within_date_range_regs_${CASE_SUFFIX}.json"
ATTENDEE_NAME="John Doe ${CASE_SUFFIX}"
ATTENDEE_EMAIL="john.doe.${CASE_SUFFIX}@example.com"
ATTENDEE_PHONE="+1-555-123-4567"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — Fetch events and select one whose date range includes today's UTC date.
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

# When — POST /api/registrations for the active event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${ATTENDEE_NAME}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"${ATTENDEE_PHONE}\"}")"

# Then — HTTP 201 with persisted registration fields, and registration is listed for the event.
[ "$HTTP_STATUS" = "201" ]
grep -F "\"eventId\":\"${EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"name\":\"${ATTENDEE_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"phone\":\"${ATTENDEE_PHONE}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt":' "$RESPONSE_FILE" >/dev/null
REG_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$REG_STATUS" = "200" ]
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:register_within_date_range"

# Cleanup — no delete endpoint exists; unique email prevents interference.
:
