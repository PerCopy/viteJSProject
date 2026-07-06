#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_TITLE="Event Without Start ${CASE_SUFFIX}"
EVENT_DESCRIPTION="Test ${CASE_SUFFIX}"
EVENT_LOCATION="Room 101 ${CASE_SUFFIX}"
END_DATE="2025-05-01T17:00:00Z"
RESPONSE_FILE="/tmp/create_event_missing_start_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_missing_start_date_${CASE_SUFFIX}.status"
trap 'rm -f "$RESPONSE_FILE" "$STATUS_FILE"' EXIT

# Given
: "Prepare an invalid payload missing the required startDate field"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"${EVENT_DESCRIPTION}\",\"location\":\"${EVENT_LOCATION}\",\"endDate\":\"${END_DATE}\"}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Title, start date, end date, and location are required."' "$RESPONSE_FILE" >/dev/null

# Cleanup
: "Rejected request should not create persistent state"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_missing_start_date"
