#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-300"
EMAIL="bob.wilson.${CASE_SUFFIX}@example.com"
RESPONSE_FILE="/tmp/registration_rejected_after_event_end_date_${CASE_SUFFIX}.json"
LIST_FILE="/tmp/registration_rejected_after_event_end_date_list_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$LIST_FILE"
}
trap cleanup EXIT

# Given — Prepare valid attendee data for the seeded event assumed to have already ended.
: > "$RESPONSE_FILE"
: > "$LIST_FILE"

# When — Attempt to register after the event end date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Bob Wilson\",\"email\":\"${EMAIL}\",\"phone\":\"+1-555-456-7890\"}")"

# Then — Expect 400 with closed message and no persisted registration for the email.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration is closed. The event ended on' "$RESPONSE_FILE" >/dev/null

LIST_STATUS="$(curl -sS -o "$LIST_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$LIST_STATUS" = "200" ]
if grep -F "\"email\":\"${EMAIL}\"" "$LIST_FILE" >/dev/null; then
  echo "unexpected registration persisted for ${EMAIL}" >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_after_event_end_date"

# Cleanup — Rejected request should create no server-side state; temp files are removed by trap.
