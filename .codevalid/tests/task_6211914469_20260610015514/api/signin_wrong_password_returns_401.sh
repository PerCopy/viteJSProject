#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
SIGNUP_RESPONSE_FILE="/tmp/signin_wrong_password_returns_401_signup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signin_wrong_password_returns_401_${CASE_SUFFIX}.json"
USERNAME="jane-smith-${CASE_SUFFIX}"
EMAIL="jane.smith.${CASE_SUFFIX}@example.com"
CORRECT_PASSWORD="CorrectPass456"
WRONG_PASSWORD="WrongPassword789"
FULL_NAME="Jane Smith"

cleanup() {
  rm -f "$SIGNUP_RESPONSE_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create a unique user with a known correct password.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${CORRECT_PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]

# When — Attempt signin with the valid email but wrong password.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${WRONG_PASSWORD}\"}")"

# Then — HTTP 401 with invalid-credentials message.
[ "$HTTP_STATUS" = "401" ]
grep -F '"message":"Invalid email or password."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signin_wrong_password_returns_401"
