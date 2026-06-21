#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE_ONE="/tmp/registration_rejected_missing_required_fields_one_${CASE_SUFFIX}.json"
RESPONSE_FILE_TWO="/tmp/registration_rejected_missing_required_fields_two_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE_ONE" "$RESPONSE_FILE_TWO"
}
trap cleanup EXIT

# Given — Prepare two invalid payloads missing required fields.
: > "$RESPONSE_FILE_ONE"
: > "$RESPONSE_FILE_TWO"

# When — Submit registration requests with missing email/phone and then missing eventId.
HTTP_STATUS_ONE="$(curl -sS -o "$RESPONSE_FILE_ONE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"eventId":"evt-100","name":"Test User"}')"

HTTP_STATUS_TWO="$(curl -sS -o "$RESPONSE_FILE_TWO" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"name":"Test User","email":"test@example.com","phone":"+1-555-111-2222"}')"

# Then — Both requests should fail with the required-fields validation message.
[ "$HTTP_STATUS_ONE" = "400" ]
grep -F '"message":"Event, name, email, and phone number are required."' "$RESPONSE_FILE_ONE" >/dev/null
[ "$HTTP_STATUS_TWO" = "400" ]
grep -F '"message":"Event, name, email, and phone number are required."' "$RESPONSE_FILE_TWO" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_missing_required_fields"

# Cleanup — Validation failures should create no server-side state; temp files are removed by trap.
