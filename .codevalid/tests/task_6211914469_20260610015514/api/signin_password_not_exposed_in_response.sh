#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
SIGNUP_RESPONSE_FILE="/tmp/signin_password_not_exposed_in_response_signup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signin_password_not_exposed_in_response_${CASE_SUFFIX}.json"
USERNAME="secure-user-${CASE_SUFFIX}"
EMAIL="secure.user.${CASE_SUFFIX}@test.com"
PASSWORD="HiddenPass111"
FULL_NAME="Secure User"
USER_ID=""

cleanup() {
  rm -f "$SIGNUP_RESPONSE_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create a unique user with a known password.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]
USER_ID="$(grep -o '"id":"[^"]*"' "$SIGNUP_RESPONSE_FILE" | head -1 | cut -d'"' -f4)"

# When — Sign in with the valid credentials.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\"}")"

# Then — HTTP 200 with no password field and no plaintext password in the response body.
[ "$HTTP_STATUS" = "200" ]
grep -F "\"id\":\"${USER_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field must not be present in signin response' >&2
  exit 1
fi
if grep -F "${PASSWORD}" "$RESPONSE_FILE" >/dev/null; then
  echo 'plaintext password must not appear anywhere in signin response' >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signin_password_not_exposed_in_response"
