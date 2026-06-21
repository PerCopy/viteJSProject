#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/signin_invalid_email_returns_401_${CASE_SUFFIX}.json"
INVALID_EMAIL="nonexistent.${CASE_SUFFIX}@unknown.com"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Use a unique email address that should not exist.
:

# When — Attempt signin with a non-existent email.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signin" \
  -H 'Content-Type: application/json' \
  --data "{\"email\":\"${INVALID_EMAIL}\",\"password\":\"anypassword\"}")"

# Then — HTTP 401 with invalid-credentials message.
[ "$HTTP_STATUS" = "401" ]
grep -F '"message":"Invalid email or password."' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:signin_invalid_email_returns_401"
