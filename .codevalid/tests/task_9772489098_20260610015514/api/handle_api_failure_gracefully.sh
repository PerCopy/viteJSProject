#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/handle_api_failure_gracefully_${CASE_SUFFIX}.json"
MISSING_EVENT_ID="evt-missing-${CASE_SUFFIX}"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Use an event id that does not exist.

# When — Submit a registration for the missing event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${MISSING_EVENT_ID}\",\"name\":\"missing-event-${CASE_SUFFIX}\",\"email\":\"missing-event-${CASE_SUFFIX}@example.com\",\"phone\":\"555${CASE_SUFFIX}\"}")"

# Then — HTTP 404 with event-not-found message.
[ "$HTTP_STATUS" = "404" ]
grep -F 'Event not found.' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:handle_api_failure_gracefully"

# Cleanup — No side effects expected because event lookup fails.
