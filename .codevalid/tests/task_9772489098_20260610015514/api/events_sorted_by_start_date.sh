#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/events_sorted_by_start_date_${CASE_SUFFIX}.json"
DATES_FILE="/tmp/events_sorted_by_start_date_dates_${CASE_SUFFIX}.txt"
SORTED_FILE="/tmp/events_sorted_by_start_date_sorted_${CASE_SUFFIX}.txt"

# Given — The API is reachable and returns events with startDate fields.

# When — Send GET request to /api/events.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 is returned and startDate values are already sorted ascending.
[ "$HTTP_STATUS" = "200" ]
grep -Eq '^\[' "$RESPONSE_FILE"
grep -o '"startDate":"[^"]*"' "$RESPONSE_FILE" | sed 's/"startDate":"//; s/"$//' > "$DATES_FILE"
cp "$DATES_FILE" "$SORTED_FILE"
sort "$SORTED_FILE" -o "$SORTED_FILE"
diff -u "$DATES_FILE" "$SORTED_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:events_sorted_by_start_date"

# Cleanup — Remove temp files.
rm -f "$RESPONSE_FILE" "$DATES_FILE" "$SORTED_FILE"
