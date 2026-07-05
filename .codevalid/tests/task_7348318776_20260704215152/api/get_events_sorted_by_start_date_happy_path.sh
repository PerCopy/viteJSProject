#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TITLE_LATE="Launch Party ${CASE_SUFFIX}"
TITLE_EARLY="Workshop ${CASE_SUFFIX}"
RESP1="/tmp/get_events_sorted_by_start_date_happy_path_create1_${CASE_SUFFIX}.json"
RESP2="/tmp/get_events_sorted_by_start_date_happy_path_create2_${CASE_SUFFIX}.json"
LIST_RESP="/tmp/get_events_sorted_by_start_date_happy_path_list_${CASE_SUFFIX}.json"
STATUS1="/tmp/get_events_sorted_by_start_date_happy_path_create1_${CASE_SUFFIX}.status"
STATUS2="/tmp/get_events_sorted_by_start_date_happy_path_create2_${CASE_SUFFIX}.status"
LIST_STATUS="/tmp/get_events_sorted_by_start_date_happy_path_list_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$RESP1" "$RESP2" "$LIST_RESP" "$STATUS1" "$STATUS2" "$LIST_STATUS"
}
trap cleanup_files EXIT

# Given
curl -sS -o "$RESP1" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_LATE}\",\"description\":\"Product launch event\",\"location\":\"Main Stage\",\"startDate\":\"2026-02-01T18:00:00Z\",\"endDate\":\"2026-02-01T20:00:00Z\"}" > "$STATUS1"
[ "$(cat "$STATUS1")" = "201" ]

curl -sS -o "$RESP2" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_EARLY}\",\"description\":\"Hands-on workshop\",\"location\":\"Room 101\",\"startDate\":\"2026-01-15T10:00:00Z\",\"endDate\":\"2026-01-15T12:00:00Z\"}" > "$STATUS2"
[ "$(cat "$STATUS2")" = "201" ]

# When
curl -sS -o "$LIST_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST_STATUS"

# Then
[ "$(cat "$LIST_STATUS")" = "200" ]
grep -F '"title":"'"$TITLE_EARLY"'"' "$LIST_RESP" >/dev/null
grep -F '"title":"'"$TITLE_LATE"'"' "$LIST_RESP" >/dev/null
EARLY_LINE="$(grep -n '"title":"'"$TITLE_EARLY"'"' "$LIST_RESP" | head -n 1 | cut -d: -f1)"
LATE_LINE="$(grep -n '"title":"'"$TITLE_LATE"'"' "$LIST_RESP" | head -n 1 | cut -d: -f1)"
[ -n "$EARLY_LINE" ]
[ -n "$LATE_LINE" ]
[ "$EARLY_LINE" -lt "$LATE_LINE" ]

echo "CODEVALID_TEST_ASSERTION_OK:get_events_sorted_by_start_date_happy_path"

# Cleanup
# No cleanup endpoint exists for in-memory events; test data is uniquely namespaced to avoid collisions.
