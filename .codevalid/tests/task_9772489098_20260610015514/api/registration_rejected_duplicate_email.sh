#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-100"
BASE_EMAIL="existing.${CASE_SUFFIX}@example.com"
FIRST_RESPONSE_FILE="/tmp/registration_rejected_duplicate_email_first_${CASE_SUFFIX}.json"
SECOND_RESPONSE_FILE="/tmp/registration_rejected_duplicate_email_second_${CASE_SUFFIX}.json"
THIRD_RESPONSE_FILE="/tmp/registration_rejected_duplicate_email_third_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$FIRST_RESPONSE_FILE" "$SECOND_RESPONSE_FILE" "$THIRD_RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create an initial registration for the event using a unique email.
FIRST_STATUS="$(curl -sS -o "$FIRST_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Existing User\",\"email\":\"${BASE_EMAIL}\",\"phone\":\"+1-555-777-8888\"}")"
[ "$FIRST_STATUS" = "201" ]
grep -F "\"email\":\"${BASE_EMAIL}\"" "$FIRST_RESPONSE_FILE" >/dev/null

# When — Re-submit the same email and then the same email with different casing.
SECOND_STATUS="$(curl -sS -o "$SECOND_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Existing User\",\"email\":\"${BASE_EMAIL}\",\"phone\":\"+1-555-777-8888\"}")"

UPPER_EMAIL="$(printf '%s' "$BASE_EMAIL" | tr '[:lower:]' '[:upper:]')"
THIRD_STATUS="$(curl -sS -o "$THIRD_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Another User\",\"email\":\"${UPPER_EMAIL}\",\"phone\":\"+1-555-999-0000\"}")"

# Then — Both duplicate attempts should return the duplicate-email validation error.
[ "$SECOND_STATUS" = "400" ]
grep -F '"message":"This email is already registered for this event."' "$SECOND_RESPONSE_FILE" >/dev/null
[ "$THIRD_STATUS" = "400" ]
grep -F '"message":"This email is already registered for this event."' "$THIRD_RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_duplicate_email"

# Cleanup — No public delete/reset registration API is exposed; temp files are removed by trap.
