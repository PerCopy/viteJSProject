#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
SIGNUP_RESPONSE_FILE="/tmp/signin_valid_credentials_success_signup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signin_valid_credentials_success_${CASE_SUFFIX}.json"
USERNAME="john-doe-${CASE_SUFFIX}"
EMAIL="john.doe.${CASE_SUFFIX}@example.com"
PASSWORD="SecurePass123!"
FULL_NAME="John Doe"
USER_ID=""

cleanup() {
  rm -f "$SIGNUP_RESPONSE_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create a unique user so valid signin credentials exist.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]
grep -F '"token":"simulated-jwt-token-for-' "$SIGNUP_RESPONSE_FILE" >/dev/null
USER_ID="$(grep -o '"id":"[^"]*"' "$SIGNUP_RESPONSE_FILE" | head -1 | cut -d'"' -f4)"

# When — Sign in with the valid email and password.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")"

# Then — HTTP 200 with user object, token, and no password field.
[ "$HTTP_STATUS" = "200" ]
grep -F '"user":{' "$RESPONSE_FILE" >/dev/null
grep -F "\"id\":\"${USER_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field must not be present in signin response' >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signin_valid_credentials_success"
