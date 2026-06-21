#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="nonameuser-${CASE_SUFFIX}"
EMAIL="noname-${CASE_SUFFIX}@test.com"
RESPONSE_FILE="/tmp/signup_missing_full_name_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Prepare unique username and email while omitting fullName.
:

# When — POST /api/auth/signup without fullName.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"pass123\"}")"

# Then — HTTP 400 with required-fields validation message.
[ "$HTTP_STATUS" = "400" ]
grep -F '"message":"Username, email, password, and full name are required."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signup_missing_full_name"

# Cleanup — Temp file removed by trap.
