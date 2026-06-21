#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/reject_event_with_end_date_before_start_date_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/reject_event_with_end_date_before_start_date_${CASE_SUFFIX}.json"
TODAY="$(date -u +%F)"
ATTENDEE_EMAIL="closed-event-${CASE_SUFFIX}@example.com"

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Find an event whose endDate is before today.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
PAST_EVENT_ID="$(node -e '
const fs = require("fs");
const today = process.argv[1];
const events = JSON.parse(fs.readFileSync(process.argv[2], "utf8"));
const match = events.find(e => e.endDate < today);
if (!match) process.exit(1);
process.stdout.write(match.id);
' "$TODAY" "$EVENTS_FILE")"

# When — Attempt to register for the ended event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${PAST_EVENT_ID}\",\"name\":\"closed-attempt-${CASE_SUFFIX}\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"555${CASE_SUFFIX}\"}")"

# Then — HTTP 400 and closed-registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration is closed.' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:reject_event_with_end_date_before_start_date"

# Cleanup — No side effects expected because registration should not be recorded.
