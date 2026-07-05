#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
EVENT_WITH_REGS_TITLE="Event With Registrations ${CASE_SUFFIX}"
EVENT_NO_REGS_TITLE="Event Without Registrations ${CASE_SUFFIX}"
CREATE1_RESP="/tmp/get_events_registration_count_accurate_create1_${CASE_SUFFIX}.json"
CREATE2_RESP="/tmp/get_events_registration_count_accurate_create2_${CASE_SUFFIX}.json"
REG1_RESP="/tmp/get_events_registration_count_accurate_reg1_${CASE_SUFFIX}.json"
REG2_RESP="/tmp/get_events_registration_count_accurate_reg2_${CASE_SUFFIX}.json"
LIST_RESP="/tmp/get_events_registration_count_accurate_list_${CASE_SUFFIX}.json"
CREATE1_STATUS="/tmp/get_events_registration_count_accurate_create1_${CASE_SUFFIX}.status"
CREATE2_STATUS="/tmp/get_events_registration_count_accurate_create2_${CASE_SUFFIX}.status"
REG1_STATUS="/tmp/get_events_registration_count_accurate_reg1_${CASE_SUFFIX}.status"
REG2_STATUS="/tmp/get_events_registration_count_accurate_reg2_${CASE_SUFFIX}.status"
LIST_STATUS="/tmp/get_events_registration_count_accurate_list_${CASE_SUFFIX}.status"
cleanup_files() {
  rm -f "$CREATE1_RESP" "$CREATE2_RESP" "$REG1_RESP" "$REG2_RESP" "$LIST_RESP" \
    "$CREATE1_STATUS" "$CREATE2_STATUS" "$REG1_STATUS" "$REG2_STATUS" "$LIST_STATUS"
}
trap cleanup_files EXIT

extract_json_field() {
  key="$1"
  file="$2"
  sed -n 's/.*"'"$key"'":"\([^"]*\)".*/\1/p' "$file" | head -n 1
}

# Given
curl -sS -o "$CREATE1_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_WITH_REGS_TITLE}\",\"description\":\"Registration count source\",\"location\":\"Hall A\",\"startDate\":\"2026-07-01\",\"endDate\":\"2099-12-31\"}" > "$CREATE1_STATUS"
[ "$(cat "$CREATE1_STATUS")" = "201" ]
EVENT_WITH_REGS_ID="$(extract_json_field id "$CREATE1_RESP")"
[ -n "$EVENT_WITH_REGS_ID" ]

curl -sS -o "$CREATE2_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${EVENT_NO_REGS_TITLE}\",\"description\":\"Zero registrations expected\",\"location\":\"Hall B\",\"startDate\":\"2026-07-02\",\"endDate\":\"2099-12-31\"}" > "$CREATE2_STATUS"
[ "$(cat "$CREATE2_STATUS")" = "201" ]

curl -sS -o "$REG1_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_WITH_REGS_ID}\",\"name\":\"Alice ${CASE_SUFFIX}\",\"email\":\"alice.${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-0001\"}" > "$REG1_STATUS"
[ "$(cat "$REG1_STATUS")" = "201" ]

curl -sS -o "$REG2_RESP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_WITH_REGS_ID}\",\"name\":\"Bob ${CASE_SUFFIX}\",\"email\":\"bob.${CASE_SUFFIX}@example.com\",\"phone\":\"+1-555-0002\"}" > "$REG2_STATUS"
[ "$(cat "$REG2_STATUS")" = "201" ]

# When
curl -sS -o "$LIST_RESP" -w '%{http_code}' "$BASE_URL/api/events" > "$LIST_STATUS"

# Then
[ "$(cat "$LIST_STATUS")" = "200" ]
grep -F '"title":"'"$EVENT_WITH_REGS_TITLE"'"' "$LIST_RESP" >/dev/null
grep -F '"title":"'"$EVENT_NO_REGS_TITLE"'"' "$LIST_RESP" >/dev/null
grep -F '"title":"'"$EVENT_WITH_REGS_TITLE"'","description":"Registration count source","startDate":"2026-07-01","endDate":"2099-12-31","location":"Hall A","registrationCount":2' "$LIST_RESP" >/dev/null
grep -F '"title":"'"$EVENT_NO_REGS_TITLE"'","description":"Zero registrations expected","startDate":"2026-07-02","endDate":"2099-12-31","location":"Hall B","registrationCount":0' "$LIST_RESP" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:get_events_registration_count_accurate"

# Cleanup
# No cleanup endpoint exists for in-memory events/registrations; test data is uniquely namespaced to avoid collisions.
