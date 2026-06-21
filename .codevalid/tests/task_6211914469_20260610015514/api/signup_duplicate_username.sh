#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EXISTING_USERNAME="takenname-${CASE_SUFFIX}"
EXISTING_EMAIL="taken-${CASE_SUFFIX}@test.com"
RESPONSE_FILE_SETUP="/tmp/signup_duplicate_username_setup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signup_duplicate_username_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE_SETUP" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create an existing user with the target username to trigger duplicate-username validation.
SETUP_STATUS="$(curl -sS -o "$RESPONSE_FILE_SETUP" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"${EXISTING_EMAIL}\",\"password\":\"pass456\",\"fullName\":\"Taken User\"}")"
[ "$SETUP_STATUS" = "201" ]

# When — Attempt signup with the same username but different email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${EXISTING_USERNAME}\",\"email\":\"different-${CASE_SUFFIX}@test.com\",\"password\":\"pass456\",\"fullName\":\"New Person\"}")"

# Then — HTTP 400 with duplicate registration message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username or Email already registered."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_duplicate_username"

# Cleanup — No cleanup endpoint exists; temp files removed by trap.
