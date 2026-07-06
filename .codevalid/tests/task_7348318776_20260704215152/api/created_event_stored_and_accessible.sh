#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_TITLE="Persistence Test Event ${CASE_SUFFIX}"
EVENT_DESCRIPTION="Testing storage ${CASE_SUFFIX}"
EVENT_LOCATION="Storage Venue ${CASE_SUFFIX}"
START_DATE="2025-11-01T10:00:00Z"
END_DATE="2025-11-02T20:00:00Z"
CREATE_RESPONSE_FILE="/tmp/created_event_stored_and_accessible_create_${CASE_SUFFIX}.json"
CREATE_STATUS_FILE="/tmp/created_event_stored_and_accessible_create_${CASE_SUFFIX}.status"
LIST_RESPONSE_FILE="/tmp/created_event_stored_and_accessible_list_${CASE_SUFFIX}.json"
LIST_STATUS_FILE="/tmp/created_event_stored_and_accessible_list_${CASE_SUFFIX}.status"
EVENT_ID=""
cleanup_files() {
  rm -f "$CREATE_RESPONSE_FILE" "$CREATE_STATUS_FILE" "$LIST_RESPONSE_FILE" "$LIST_STATUS_FILE"
}
cleanup_event() {
  if [ -n "$EVENT_ID" ]; then
    curl -sS -o /dev/null -X DELETE "$BASE_URL/api/events/$EVENT_ID" || true
  fi
}
trap 'cleanup_event; cleanup_files' EXIT

# Given
: "Prepare a unique event payload and ensure assertions use the public events list API"

# When
curl -sS -o "$CREATE_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"${EVENT_DESCRIPTION}\",\"location\":\"${EVENT_LOCATION}\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}" > "$CREATE_STATUS_FILE"
CREATE_STATUS="$(cat "$CREATE_STATUS_FILE")"
[ "$CREATE_STATUS" = "201" ]
EVENT_ID="$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' "$CREATE_RESPONSE_FILE")"
[ -n "$EVENT_ID" ]

curl -sS -o "$LIST_RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$LIST_STATUS_FILE"

# Then
LIST_STATUS="$(cat "$LIST_STATUS_FILE")"
[ "$LIST_STATUS" = "200" ]
grep -F '"id":"'"$EVENT_ID"'"' "$LIST_RESPONSE_FILE" >/dev/null
grep -F '"title":"'"$EVENT_TITLE"'"' "$LIST_RESPONSE_FILE" >/dev/null
grep -F '"description":"'"$EVENT_DESCRIPTION"'"' "$LIST_RESPONSE_FILE" >/dev/null
grep -F '"location":"'"$EVENT_LOCATION"'"' "$LIST_RESPONSE_FILE" >/dev/null
grep -F '"startDate":"'"$START_DATE"'"' "$LIST_RESPONSE_FILE" >/dev/null
grep -F '"endDate":"'"$END_DATE"'"' "$LIST_RESPONSE_FILE" >/dev/null

# Cleanup
: "Best-effort delete of created event if the API supports DELETE /api/events/{id}"

echo "CODEVALID_TEST_ASSERTION_OK:created_event_stored_and_accessible"
