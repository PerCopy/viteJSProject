#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="testuser-${CASE_SUFFIX}"
EXISTING_EMAIL_LOWER="test-${CASE_SUFFIX}@test.com"
EXISTING_EMAIL_UPPER="TEST-${CASE_SUFFIX}@TEST.COM"
RESPONSE_FILE_SETUP="/tmp/signup_email_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_email_case_insensitive_duplicate_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE_SETUP" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create an existing user with lowercase email.
SETUP_STATUS="$(curl -sS -o "$RESPONSE_FILE_SETUP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL_LOWER}\",\"password\":\"pass789\",\"fullName\":\"Existing Person\"}")"
[ "$SETUP_STATUS" = "201" ]

# When — Attempt signup using the same email with different case.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"newperson-${CASE_SUFFIX}\",\"email\":\"${EXISTING_EMAIL_UPPER}\",\"password\":\"pass789\",\"fullName\":\"New Person\"}")"

# Then — HTTP 400 with duplicate registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_email_case_insensitive_duplicate"

# Cleanup — No cleanup endpoint exists; temp files removed by trap.
