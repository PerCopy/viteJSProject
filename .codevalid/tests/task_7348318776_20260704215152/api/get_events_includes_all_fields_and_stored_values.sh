#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_TITLE="Annual Meeting ${CASE_SUFFIX}"
EVENT_DESCRIPTION="Yearly review ${CASE_SUFFIX}"
EVENT_LOCATION="Main Hall ${CASE_SUFFIX}"
CREATE_RESP="/tmp/get_events_includes_all_fields_and_stored_values_create_${CASE_SUFFIX}.json"
LIST_RESP="/tmp/get_events_includes_all_fields_and_stored_values_list_${CASE_SUFFIX}.json"
CREATE_STATUS="/tmp/get_events_includes_all_fields_and_stored_values_create_${CASE_SUFFIX}.status"
LIST_STATUS="/tmp/get_events_includes_all_fields_and_stored_values_list_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$CREATE_RESP" "$LIST_RESP" "$CREATE_STATUS" "$LIST_STATUS"
}
trap cleanup_files EXIT

# Given
curl -sS -o "$CREATE_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"${EVENT_DESCRIPTION}\",\"location\":\"${EVENT_LOCATION}\",\"startDate\":\"2026-03-01T09:00:00Z\",\"endDate\":\"2026-03-01T17:00:00Z\"}" > "$CREATE_STATUS"
[ "$(cat "$CREATE_STATUS")" = "201" ]
grep -F '"title":"'"$EVENT_TITLE"'"' "$CREATE_RESP" >/dev/null

# When
curl -sS -o "$LIST_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST_STATUS"

# Then
[ "$(cat "$LIST_STATUS")" = "200" ]
grep -F '"title":"'"$EVENT_TITLE"'"' "$LIST_RESP" >/dev/null
grep -F '"description":"'"$EVENT_DESCRIPTION"'"' "$LIST_RESP" >/dev/null
grep -F '"location":"'"$EVENT_LOCATION"'"' "$LIST_RESP" >/dev/null
grep -F '"startDate":"2026-03-01T09:00:00Z"' "$LIST_RESP" >/dev/null
grep -F '"endDate":"2026-03-01T17:00:00Z"' "$LIST_RESP" >/dev/null
grep -F '"registrationCount":0' "$LIST_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:get_events_includes_all_fields_and_stored_values"

# Cleanup
# No cleanup endpoint exists for in-memory events; test data is uniquely namespaced to avoid collisions.
