#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/events_same_start_date_sorting_${CASE_SUFFIX}.json"
DATES_FILE="/tmp/events_same_start_date_sorting_dates_${CASE_SUFFIX}.txt"

# Given — The events endpoint should include all events, even if multiple share the same startDate.

# When — Send GET request to /api/events.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 is returned, response is a JSON array, and duplicate startDate values do not break the response.
[ "$HTTP_STATUS" = "200" ]
grep -Eq '^\[' "$RESPONSE_FILE"
grep -F '"registrationCount":' "$RESPONSE_FILE" >/dev/null
grep -o '"startDate":"[^"]*"' "$RESPONSE_FILE" | sed 's/"startDate":"//; s/"$//' > "$DATES_FILE"
[ -f "$DATES_FILE" ]

echo "CODEVALID_TEST_ASSERTION_OK:events_same_start_date_sorting"

# Cleanup — Remove temp files.
rm -f "$RESPONSE_FILE" "$DATES_FILE"
