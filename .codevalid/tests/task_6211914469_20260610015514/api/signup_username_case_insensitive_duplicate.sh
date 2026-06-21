#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME_LOWER="johnsmith-${CASE_SUFFIX}"
EXISTING_USERNAME_UPPER="JOHNSMITH-${CASE_SUFFIX}"
EXISTING_EMAIL="john-${CASE_SUFFIX}@test.com"
RESPONSE_FILE_SETUP="/tmp/signup_username_case_insensitive_duplicate_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_username_case_insensitive_duplicate_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE_SETUP" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create an existing user with lowercase username.
SETUP_STATUS="$(curl -sS -o "$RESPONSE_FILE_SETUP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME_LOWER}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"pass111\",\"fullName\":\"John Smith\"}")"
[ "$SETUP_STATUS" = "201" ]

# When — Attempt signup using the same username with different case.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME_UPPER}\",\"email\":\"different-${CASE_SUFFIX}@email.com\",\"password\":\"pass111\",\"fullName\":\"John Smith 2\"}")"

# Then — HTTP 400 with duplicate registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_username_case_insensitive_duplicate"

# Cleanup — No cleanup endpoint exists; temp files removed by trap.
