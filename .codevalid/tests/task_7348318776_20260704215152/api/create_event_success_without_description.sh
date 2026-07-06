#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_TITLE="Team Meeting ${CASE_SUFFIX}"
EVENT_LOCATION="Office Room 301 ${CASE_SUFFIX}"
START_DATE="2025-02-01T10:00:00Z"
END_DATE="2025-02-01T12:00:00Z"
RESPONSE_FILE="/tmp/create_event_success_without_description_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_success_without_description_${CASE_SUFFIX}.status"
EVENT_ID=""
cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
cleanup_event() {
  if [ -n "$EVENT_ID" ]; then
    curl -sS -o /dev/null -X DELETE "$BASE_URL/api/events/$EVENT_ID" || true
  fi
}
trap 'cleanup_event; cleanup_files' EXIT

# Given
: "Prepare a unique event payload without the optional description field"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"location\":\"${EVENT_LOCATION}\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
grep -F '"title":"'"$EVENT_TITLE"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"description":""' "$RESPONSE_FILE" >/dev/null
grep -F '"location":"'"$EVENT_LOCATION"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"startDate":"'"$START_DATE"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"endDate":"'"$END_DATE"'"' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":0' "$RESPONSE_FILE" >/dev/null
EVENT_ID="$(sed -n 's/.*"id":"\([^"]*\)".*/\1/p' "$RESPONSE_FILE")"
[ -n "$EVENT_ID" ]

# Cleanup
: "Best-effort delete of created event if the API supports DELETE /api/events/{id}"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_success_without_description"
