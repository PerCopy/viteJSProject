#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TITLE_ONE="Morning Standup ${CASE_SUFFIX}"
TITLE_TWO="Morning Meeting ${CASE_SUFFIX}"
CREATE1_RESP="/tmp/get_events_sorted_with_same_start_date_stability_create1_${CASE_SUFFIX}.json"
CREATE2_RESP="/tmp/get_events_sorted_with_same_start_date_stability_create2_${CASE_SUFFIX}.json"
LIST1_RESP="/tmp/get_events_sorted_with_same_start_date_stability_list1_${CASE_SUFFIX}.json"
LIST2_RESP="/tmp/get_events_sorted_with_same_start_date_stability_list2_${CASE_SUFFIX}.json"
CREATE1_STATUS="/tmp/get_events_sorted_with_same_start_date_stability_create1_${CASE_SUFFIX}.status"
CREATE2_STATUS="/tmp/get_events_sorted_with_same_start_date_stability_create2_${CASE_SUFFIX}.status"
LIST1_STATUS="/tmp/get_events_sorted_with_same_start_date_stability_list1_${CASE_SUFFIX}.status"
LIST2_STATUS="/tmp/get_events_sorted_with_same_start_date_stability_list2_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$CREATE1_RESP" "$CREATE2_RESP" "$LIST1_RESP" "$LIST2_RESP" \
    "$CREATE1_STATUS" "$CREATE2_STATUS" "$LIST1_STATUS" "$LIST2_STATUS"
}
trap cleanup_files EXIT

# Given
curl -sS -o "$CREATE1_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_ONE}\",\"description\":\"First same-date event\",\"location\":\"Room A\",\"startDate\":\"2026-05-01T09:00:00Z\",\"endDate\":\"2026-05-01T09:30:00Z\"}" > "$CREATE1_STATUS"
[ "$(cat "$CREATE1_STATUS")" = "201" ]

curl -sS -o "$CREATE2_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_TWO}\",\"description\":\"Second same-date event\",\"location\":\"Room B\",\"startDate\":\"2026-05-01T09:00:00Z\",\"endDate\":\"2026-05-01T10:00:00Z\"}" > "$CREATE2_STATUS"
[ "$(cat "$CREATE2_STATUS")" = "201" ]

# When
curl -sS -o "$LIST1_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST1_STATUS"
curl -sS -o "$LIST2_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST2_STATUS"

# Then
[ "$(cat "$LIST1_STATUS")" = "200" ]
[ "$(cat "$LIST2_STATUS")" = "200" ]
LINE1_A="$(grep -n '"title":"'"$TITLE_ONE"'"' "$LIST1_RESP" | head -n 1 | cut -d: -f1)"
LINE1_B="$(grep -n '"title":"'"$TITLE_TWO"'"' "$LIST1_RESP" | head -n 1 | cut -d: -f1)"
LINE2_A="$(grep -n '"title":"'"$TITLE_ONE"'"' "$LIST2_RESP" | head -n 1 | cut -d: -f1)"
LINE2_B="$(grep -n '"title":"'"$TITLE_TWO"'"' "$LIST2_RESP" | head -n 1 | cut -d: -f1)"
[ -n "$LINE1_A" ]
[ -n "$LINE1_B" ]
[ -n "$LINE2_A" ]
[ -n "$LINE2_B" ]
if [ "$LINE1_A" -lt "$LINE1_B" ]; then
  [ "$LINE2_A" -lt "$LINE2_B" ]
else
  [ "$LINE1_B" -lt "$LINE1_A" ]
  [ "$LINE2_B" -lt "$LINE2_A" ]
fi

echo "CODEVALID_TEST_ASSERTION_OK:get_events_sorted_with_same_start_date_stability"

# Cleanup
# No cleanup endpoint exists for in-memory events; test data is uniquely namespaced to avoid collisions.
