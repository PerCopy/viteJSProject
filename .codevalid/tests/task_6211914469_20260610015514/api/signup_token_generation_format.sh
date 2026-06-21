#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
USERNAME="tokenuser-${CASE_SUFFIX}"
EMAIL="token-${CASE_SUFFIX}@test.com"
PASSWORD="tokenpass"
FULL_NAME="Token Test ${CASE_SUFFIX}"
RESPONSE_FILE="/tmp/signup_token_generation_format_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Prepare unique signup fields for successful user creation.
:

# When — POST /api/auth/signup and capture the created user and token.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/auth/signup" \
  -H 'Content-Type: application/json' \
  --data "{\"username\":\"${USERNAME}\",\"email\":\"${EMAIL}\",\"password\":\"${PASSWORD}\",\"fullName\":\"${FULL_NAME}\"}")"

# Then — HTTP 201 and token format includes the returned user.id.
[ "$HTTP_STATUS" = "201" ]
grep -F '"token":"simulated-jwt-token-for-' "$RESPONSE_FILE" >/dev/null
USER_ID="$(python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data['user']['id'])
PY
)"
TOKEN="$(python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data['token'])
PY
)"
[ "$TOKEN" = "simulated-jwt-token-for-$USER_ID" ]

echo "CODEVALID_TEST_ASSERTION_OK:signup_token_generation_format"

# Cleanup — No cleanup endpoint exists; temp file removed by trap.
