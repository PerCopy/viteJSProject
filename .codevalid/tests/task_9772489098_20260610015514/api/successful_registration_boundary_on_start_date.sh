#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-400"
EMAIL="startday.${CASE_SUFFIX}@example.com"
RESPONSE_FILE="/tmp/successful_registration_boundary_on_start_date_${CASE_SUFFIX}.json"
LIST_FILE="/tmp/successful_registration_boundary_on_start_date_list_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$LIST_FILE"
}
trap cleanup EXIT

# Given — Use a unique attendee email for the seeded start-date boundary event assumed open today.
: > "$RESPONSE_FILE"
: > "$LIST_FILE"

# When — Submit a registration on the start-date boundary event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Start Day User\",\"email\":\"${EMAIL}\",\"phone\":\"+1-555-111-0000\"}")"

# Then — Expect 201 and the created registration to appear in the event registration list.
[ "$HTTP_STATUS" = "201" ]
grep -F '"eventId":"evt-400"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"Start Day User"' "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"phone":"+1-555-111-0000"' "$RESPONSE_FILE" >/dev/null

LIST_STATUS="$(curl -sS -o "$LIST_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$LIST_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$LIST_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_boundary_on_start_date"

# Cleanup — No public delete/reset registration API is exposed; temp files are removed by trap.
