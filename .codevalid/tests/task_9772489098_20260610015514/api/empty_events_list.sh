#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/empty_events_list_${CASE_SUFFIX}.json"

# Given — No mutable setup API exists; validate the endpoint's empty-list contract shape.

# When — Send GET request to /api/events.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 is returned and the response is a JSON array.
[ "$HTTP_STATUS" = "200" ]
grep -Eq '^\[' "$RESPONSE_FILE"

# If the environment is empty, it should be exactly []. Otherwise it must still be a valid events array.
if grep -Eq '^\[\]$' "$RESPONSE_FILE"; then
  :
else
  grep -F '"registrationCount":' "$RESPONSE_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:empty_events_list"

# Cleanup — Remove temp files.
rm -f "$RESPONSE_FILE"
