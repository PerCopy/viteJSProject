#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_active_events_success_${CASE_SUFFIX}.json"

# Given — The API is reachable and events can be listed.

# When — Send GET request to /api/events.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 is returned and the response is a JSON array with registrationCount fields.
[ "$HTTP_STATUS" = "200" ]
grep -Eq '^\[' "$RESPONSE_FILE"
grep -F '"registrationCount":' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:get_active_events_success"

# Cleanup — Remove temp files.
rm -f "$RESPONSE_FILE"
