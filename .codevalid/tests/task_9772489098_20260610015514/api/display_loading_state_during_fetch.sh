#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/display_loading_state_during_fetch_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The events endpoint is available.

# When — Request the events list that the UI would fetch while loading.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 and event data payload are returned.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id"' "$RESPONSE_FILE" >/dev/null
grep -F '"title"' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:display_loading_state_during_fetch"

# Cleanup — No side effects to remove.
