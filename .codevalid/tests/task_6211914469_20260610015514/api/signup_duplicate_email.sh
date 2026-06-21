#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="existinguser-${CASE_SUFFIX}"
EXISTING_EMAIL="existing-${CASE_SUFFIX}@test.com"
RESPONSE_FILE_SETUP="/tmp/signup_duplicate_email_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_duplicate_email_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE_SETUP" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create an existing user with the target email to trigger duplicate-email validation.
SETUP_STATUS="$(curl -sS -o "$RESPONSE_FILE_SETUP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"existingpass123\",\"fullName\":\"Existing User\"}")"
[ "$SETUP_STATUS" = "201" ]

# When — Attempt signup with a different username but the same email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"newdifferent-${CASE_SUFFIX}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"newpass123\",\"fullName\":\"Another User\"}")"

# Then — HTTP 400 with duplicate registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_email"

# Cleanup — No cleanup endpoint exists; temp files removed by trap.
