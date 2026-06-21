#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="secureuser-${CASE_SUFFIX}"
EMAIL="secure-${CASE_SUFFIX}@test.com"
PASSWORD="MySecretPassword123"
FULL_NAME="Security Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_password_excluded_from_response_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Prepare unique credentials for successful signup.
:

# When — POST /api/auth/signup with valid required fields.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"

# Then — HTTP 201, core user fields present, and password absent from response body.
[ "$HTTP_STATUS" = "201" ]
grep -F "\"username\":\"${USERNAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"email\":\"${EMAIL}\"" "$RESPONSE_FILE" >/dev/null
grep -F "\"fullName\":\"${FULL_NAME}\"" "$RESPONSE_FILE" >/dev/null
grep -F '"id":' "$RESPONSE_FILE" >/dev/null
if grep -F '"password":' "$RESPONSE_FILE" >/dev/null; then
  echo 'password field unexpectedly present in signup response'
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:signup_password_excluded_from_response"

# Cleanup — No cleanup endpoint exists; temp file removed by trap.
