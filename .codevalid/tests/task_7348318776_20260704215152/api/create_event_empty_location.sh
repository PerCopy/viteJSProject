#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TITLE="No Location Event ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/create_event_empty_location_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_empty_location_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
: "Event store is accessible"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE}\",\"description\":\"Empty location test ${CASE_SUFFIX}\",\"location\":\"\",\"startDate\":\"2024-10-12\",\"endDate\":\"2024-10-12\"}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "400" ]
grep -F 'Title, start date, end date, and location are required.' "$RESPONSE_FILE" >/dev/null

# Cleanup
: "Stateless negative validation test; no cleanup required"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_empty_location"
