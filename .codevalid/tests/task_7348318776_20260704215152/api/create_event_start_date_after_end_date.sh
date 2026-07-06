#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_TITLE="Invalid Date Order ${CASE_SUFFIX}"
EVENT_DESCRIPTION="Start after end ${CASE_SUFFIX}"
EVENT_LOCATION="Room 200 ${CASE_SUFFIX}"
START_DATE="2025-08-15T09:00:00Z"
END_DATE="2025-08-10T17:00:00Z"
RESPONSE_FILE="/tmp/create_event_start_date_after_end_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_start_date_after_end_date_${CASE_SUFFIX}.status"
trap 'rm -f "$RESPONSE_FILE" "$STATUS_FILE"' EXIT

# Given
: "Prepare an invalid payload where startDate is after endDate"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_TITLE}\",\"description\":\"${EVENT_DESCRIPTION}\",\"location\":\"${EVENT_LOCATION}\",\"startDate\":\"${START_DATE}\",\"endDate\":\"${END_DATE}\"}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Start date must be before or equal to the end date."' "$RESPONSE_FILE" >/dev/null

# Cleanup
: "Rejected request should not create persistent state"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_start_date_after_end_date"
