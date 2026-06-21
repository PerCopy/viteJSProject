#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/create_event_with_valid_date_range_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/create_event_with_valid_date_range_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/create_event_with_valid_date_range_regs_${CASE_SUFFIX}.json"
TODAY="$(date -u +%F)"
ATTENDEE_NAME="valid-attendee-${CASE_SUFFIX}"
ATTENDEE_EMAIL="valid-attendee-${CASE_SUFFIX}@example.com"
ATTENDEE_PHONE="555${CASE_SUFFIX}"

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — Find an event whose date range includes today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
TARGET_EVENT_ID="$(node -e '
const fs = require("fs");
const today = process.argv[1];
const events = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const match = events.find(e => e.startDate <= today && today <= e.endDate);
if (!match) process.exit(1);
process.stdout.write(match.id);
' "$TODAY" "$EVENTS_FILE")"

# When — Submit a registration for the in-range event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${TARGET_EVENT_ID}\",\"name\":\"${ATTENDEE_NAME}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"${ATTENDEE_PHONE}\"}")"

# Then — HTTP 201, response contains the registration, and the event registrations endpoint shows it.
[ "$HTTP_STATUS" = "201" ]
grep -F "\"eventId\":\"${TARGET_EVENT_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"registeredAt"' "$RESPONSE_FILE" >/dev/null

REGS_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${TARGET_EVENT_ID}")"
[ "$REGS_STATUS" = "200" ]
grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:create_event_with_valid_date_range"

# Cleanup — No DELETE endpoint exists; unique test data avoids collisions.
