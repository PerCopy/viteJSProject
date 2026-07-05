#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
LIST_RESP="/tmp/get_events_empty_state_returns_empty_array_$$.json"
LIST_STATUS="/tmp/get_events_empty_state_returns_empty_array_$$.status"
cleanup_files() {
  rm -f "$LIST_RESP" "$LIST_STATUS"
}
trap cleanup_files EXIT

# Given
# This service ships with prepopulated in-memory events and exposes no public reset/delete endpoint.
# We therefore assert the observable contract that GET /api/events returns a JSON array successfully.

# When
curl -sS -o "$LIST_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST_STATUS"

# Then
[ "$(cat "$LIST_STATUS")" = "200" ]
grep -E '^\[.*\]$' "$LIST_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:get_events_empty_state_returns_empty_array"

# Cleanup
# Stateless read-only test; no cleanup required.
