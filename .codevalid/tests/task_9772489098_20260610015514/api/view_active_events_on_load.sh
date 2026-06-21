#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_active_events_on_load_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The events API is reachable.

# When — Request the events list.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 and event objects are returned with registration counts.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id"' "$RESPONSE_FILE" >/dev/null
grep -F '"title"' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount"' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:view_active_events_on_load"

# Cleanup — No side effects to remove.
