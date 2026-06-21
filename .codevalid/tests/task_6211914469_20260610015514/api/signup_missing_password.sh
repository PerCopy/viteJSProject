#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="nopassuser-${CASE_SUFFIX}"
EMAIL="nopass-${CASE_SUFFIX}@test.com"
RESPONSE_FILE="/tmp/signup_missing_password_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Prepare unique username and email while omitting password.
:

# When — POST /api/auth/signup without password.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"fullName\":\"Test User\"}")"

# Then — HTTP 400 with required-fields validation message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username, email, password, and full name are required."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_missing_password"

# Cleanup — Temp file removed by trap.
