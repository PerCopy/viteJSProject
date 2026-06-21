#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/create_event_with_minimal_required_data_events_${CASE_SUFFIX}.json"
FIRST_RESPONSE_FILE="/tmp/create_event_with_minimal_required_data_first_${CASE_SUFFIX}.json"
SECOND_RESPONSE_FILE="/tmp/create_event_with_minimal_required_data_second_${CASE_SUFFIX}.json"
TODAY="$(date -u +%F)"
ATTENDEE_NAME="minimal-attendee-${CASE_SUFFIX}"
ATTENDEE_EMAIL="minimal-attendee-${CASE_SUFFIX}@example.com"
ATTENDEE_PHONE="555${CASE_SUFFIX}"

cleanup() {
  rm -f "$EVENTS_FILE" "$FIRST_RESPONSE_FILE" "$SECOND_RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Find an event whose date range includes today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
ACTIVE_EVENT_ID="$(node -e '
const fs = require("fs");
const today = process.argv[1];
const events = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const match = events.find(e => e.startDate <= today && today <= e.endDate);
if (!match) process.exit(1);
process.stdout.write(match.id);
' "$TODAY" "$EVENTS_FILE")"

# When — Register once with valid required fields, then try the same email again.
FIRST_STATUS="$(curl -sS -o "$FIRST_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${ACTIVE_EVENT_ID}\",\"name\":\"${ATTENDEE_NAME}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"${ATTENDEE_PHONE}\"}")"
SECOND_STATUS="$(curl -sS -o "$SECOND_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${ACTIVE_EVENT_ID}\",\"name\":\"${ATTENDEE_NAME}-dup\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"${ATTENDEE_PHONE}\"}")"

# Then — First request succeeds and duplicate email is rejected on the second request.
[ "$FIRST_STATUS" = "201" ]
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$FIRST_RESPONSE_FILE" >/dev/null
[ "$SECOND_STATUS" = "400" ]
grep -F 'This email is already registered for this event.' "$SECOND_RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:create_event_with_minimal_required_data"

# Cleanup — No DELETE endpoint exists; unique test data avoids collisions.
