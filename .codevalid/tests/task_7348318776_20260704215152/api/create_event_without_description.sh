#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TITLE="Team Meeting ${CASE_SUFFIX}"
LOCATION="Office Room 101 ${CASE_SUFFIX}"
START_DATE="2024-03-20"
END_DATE="2024-03-20"
RESPONSE_FILE="/tmp/create_event_without_description_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_without_description_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
: "Event store is accessible and unique values are used for isolation"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE}\",\"location\":\"${LOCATION}\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "201" ]
grep -F "\"title\":\"${TITLE}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"description":""' "$RESPONSE_FILE" >/dev/null
grep -F "\"location\":\"${LOCATION}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_FILE" >/dev/null

# Cleanup
: "No cleanup endpoint exists for the in-memory store; test data is uniquely namespaced"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_without_description"
