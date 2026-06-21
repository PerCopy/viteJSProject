#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-100"
EMAIL="john.doe.${CASE_SUFFIX}@example.com"
NAME="John Doe"
PHONE="+1-555-123-4567"
RESPONSE_FILE="/tmp/successful_registration_within_date_range_${CASE_SUFFIX}.json"
LIST_FILE="/tmp/successful_registration_within_date_range_list_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$LIST_FILE"
}
trap cleanup EXIT

# Given — Use a unique attendee email for the seeded event assumed to be currently open.
: > "$RESPONSE_FILE"
: > "$LIST_FILE"

# When — Submit a registration for the event.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"${NAME}\",\"email\":\"${EMAIL}\",\"phone\":\"${PHONE}\"}")"

# Then — Expect 201 and the created registration to be retrievable from the event registration list.
[ "$HTTP_STATUS" = "201" ]
grep -F '"eventId":"evt-100"' "$RESPONSE_FILE" >/dev/null
grep -F '"name":"John Doe"' "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"phone":"+1-555-123-4567"' "$RESPONSE_FILE" >/dev/null
grep -E '"id":"reg-[^"]+"' "$RESPONSE_FILE" >/dev/null
grep -E '"registeredAt":"[^"]+"' "$RESPONSE_FILE" >/dev/null

LIST_STATUS="$(curl -sS -o "$LIST_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$LIST_STATUS" = "200" ]
grep -F "\"email\":\"${EMAIL}\"" "$LIST_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:successful_registration_within_date_range"

# Cleanup — No public delete/reset registration API is exposed; temp files are removed by trap.
