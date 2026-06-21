#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
SIGNUP_RESPONSE_FILE="/tmp/signin_case_insensitive_email_success_signup_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/signin_case_insensitive_email_success_${CASE_SUFFIX}.json"
USERNAME="admin-user-${CASE_SUFFIX}"
STORED_EMAIL="Admin.${CASE_SUFFIX}@Example.COM"
LOGIN_EMAIL="admin.${CASE_SUFFIX}@example.com"
PASSWORD="AdminPass999"
FULL_NAME="Admin User"
USER_ID=""

cleanup() {
  rm -f "$SIGNUP_RESPONSE_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Create a user with mixed-case email.
SIGNUP_STATUS="$(curl -sS -o "$SIGNUP_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${STORED_EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"
[ "$SIGNUP_STATUS" = "201" ]
USER_ID="$(grep -o '"id":"[^"]*"' "$SIGNUP_RESPONSE_FILE" | head -1 | cut -d'"' -f4)"

# When — Sign in using the lower-cased version of the stored email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${LOGIN_EMAIL}\",\"password\":\"${PASSWORD}\"}")"

# Then — HTTP 200 with the matching user and token.
[ "$HTTP_STATUS" = "200" ]
grep -F "\"id\":\"${USER_ID}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${STORED_EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field must not be present in signin response' >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signin_case_insensitive_email_success"
