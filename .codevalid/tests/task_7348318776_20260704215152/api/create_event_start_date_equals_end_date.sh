#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TITLE="One Day Seminar ${CASE_SUFFIX}"
DESCRIPTION="Single day event ${CASE_SUFFIX}"
LOCATION="Boston Center ${CASE_SUFFIX}"
DATE_VALUE="2024-08-15"
RESPONSE_FILE="/tmp/create_event_start_date_equals_end_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_start_date_equals_end_date_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
: "Event store is accessible and unique values are used for isolation"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE}\",\"description\":\"${DESCRIPTION}\",\"location\":\"${LOCATION}\",\"startDate\":\"${DATE_VALUE}\",\"endDate\":\"${DATE_VALUE}\"}" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "201" ]
grep -F "\"title\":\"${TITLE}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"startDate\":\"${DATE_VALUE}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"endDate\":\"${DATE_VALUE}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_FILE" >/dev/null

# Cleanup
: "No cleanup endpoint exists for the in-memory store; test data is uniquely namespaced"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_start_date_equals_end_date"
