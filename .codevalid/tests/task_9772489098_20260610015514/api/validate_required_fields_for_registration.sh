#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/validate_required_fields_for_registration_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — The registrations endpoint is reachable.

# When — Submit a registration payload missing required fields.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data '{"eventId":"","name":"","email":"","phone":""}')"

# Then — HTTP 400 with required-fields validation message.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Event, name, email, and phone number are required.' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:validate_required_fields_for_registration"

# Cleanup — No side effects expected because validation fails.
