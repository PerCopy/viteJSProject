#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENT_ID="evt-200"
EMAIL="jane.smith.${CASE_SUFFIX}@example.com"
RESPONSE_FILE="/tmp/registration_rejected_before_event_start_date_${CASE_SUFFIX}.json"
LIST_FILE="/tmp/registration_rejected_before_event_start_date_list_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE" "$LIST_FILE"
}
trap cleanup EXIT

# Given — Prepare valid attendee data for the seeded event assumed to have a future start date.
: > "$RESPONSE_FILE"
: > "$LIST_FILE"

# When — Attempt to register before the event start date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Jane Smith\",\"email\":\"${EMAIL}\",\"phone\":\"+1-555-987-6543\"}")"

# Then — Expect 400 with not-open message and no persisted registration for the email.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration has not opened yet. Registration opens on' "$RESPONSE_FILE" >/dev/null

LIST_STATUS="$(curl -sS -o "$LIST_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$LIST_STATUS" = "200" ]
if grep -F "\"email\":\"${EMAIL}\"" "$LIST_FILE" >/dev/null; then
  echo "unexpected registration persisted for ${EMAIL}" >&2
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:registration_rejected_before_event_start_date"

# Cleanup — Rejected request should create no server-side state; temp files are removed by trap.
