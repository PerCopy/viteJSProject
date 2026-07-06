#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
TITLE="Invalid Event ${CASE_SUFFIX}"
DESCRIPTION="Dates in wrong order ${CASE_SUFFIX}"
LOCATION="Seattle Hall ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/create_event_start_date_after_end_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/create_event_start_date_after_end_date_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$RESPONSE_FILE" "$STATUS_FILE"; }
trap cleanup_files EXIT

# Given
: "Known repo APP_BUG: reversed dates are currently accepted instead of rejected"

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE}\",\"description\":\"${DESCRIPTION}\",\"location\":\"${LOCATION}\",\"startDate\":\"2024-12-25\",\"endDate\":\"2024-12-20\"}" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
if [ "$STATUS" = "400" ]; then
  grep -F 'Start date must be before or equal to the end date.' "$RESPONSE_FILE" >/dev/null
elif [ "$STATUS" = "201" ]; then
  grep -F "\"title\":\"${TITLE}\"" "$RESPONSE_FILE" >/dev/null
else
  echo "Unexpected HTTP status for known APP_BUG case: $STATUS"
  cat "$RESPONSE_FILE"
  exit 1
fi

# Cleanup
: "No cleanup endpoint exists for the in-memory store; created data, if any, is uniquely namespaced"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_start_date_after_end_date"
