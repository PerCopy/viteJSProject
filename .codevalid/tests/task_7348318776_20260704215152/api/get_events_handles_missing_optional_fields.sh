#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_TITLE="Quick Standup ${CASE_SUFFIX}"
CREATE_RESP="/tmp/get_events_handles_missing_optional_fields_create_${CASE_SUFFIX}.json"
LIST_RESP="/tmp/get_events_handles_missing_optional_fields_list_${CASE_SUFFIX}.json"
CREATE_STATUS="/tmp/get_events_handles_missing_optional_fields_create_${CASE_SUFFIX}.status"
LIST_STATUS="/tmp/get_events_handles_missing_optional_fields_list_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$CREATE_RESP" "$LIST_RESP" "$CREATE_STATUS" "$LIST_STATUS"
}
trap cleanup_files EXIT

# Given
# The API requires location and endDate on creation, so a truly missing-location/missing-endDate record
# cannot be created through public endpoints. Create an event with an omitted optional description and
# verify retrieval remains successful with stored fields intact.
curl -sS -o "$CREATE_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"location\":\"Daily Standup Room ${CASE_SUFFIX}\",\"startDate\":\"2026-04-10T08:00:00Z\",\"endDate\":\"2026-04-10T08:15:00Z\"}" > "$CREATE_STATUS"
[ "$(cat "$CREATE_STATUS")" = "201" ]

# When
curl -sS -o "$LIST_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST_STATUS"

# Then
[ "$(cat "$LIST_STATUS")" = "200" ]
grep -F '"title":"'"$EVENT_TITLE"'"' "$LIST_RESP" >/dev/null
grep -F '"startDate":"2026-04-10T08:00:00Z"' "$LIST_RESP" >/dev/null
grep -F '"endDate":"2026-04-10T08:15:00Z"' "$LIST_RESP" >/dev/null
grep -F '"description":""' "$LIST_RESP" >/dev/null
grep -F '"registrationCount":0' "$LIST_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:get_events_handles_missing_optional_fields"

# Cleanup
# No cleanup endpoint exists for in-memory events; test data is uniquely namespaced to avoid collisions.
