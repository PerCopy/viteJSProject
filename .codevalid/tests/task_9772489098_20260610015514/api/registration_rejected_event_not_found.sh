#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EMAIL="alice.brown.${CASE_SUFFIX}@example.com"
RESPONSE_FILE="/tmp/registration_rejected_event_not_found_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Use a non-existent event id with otherwise valid attendee data.
: > "$RESPONSE_FILE"

# When — Attempt to register for an event that does not exist.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"evt-nonexistent-${CASE_SUFFIX}\",\"name\":\"Alice Brown\",\"email\":\"${EMAIL}\",\"phone\":\"+1-555-333-4444\"}")"

# Then — Expect 404 with event-not-found message.
[ "$HTTP_STATUS" = "404" ]
grep -F '"message":"Event not found."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_event_not_found"

# Cleanup — Rejected request should create no server-side state; temp files are removed by trap.
