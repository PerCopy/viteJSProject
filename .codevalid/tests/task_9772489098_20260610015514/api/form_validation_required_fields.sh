#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/form_validation_required_fields_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/form_validation_required_fields_response_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Fetch any event id.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data[0]['id'] if data else '')
PY
)"
[ -n "$EVENT_ID" ]

# When — POST /api/registrations with missing name.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"\",\"email\":\"user.${CASE_SUFFIX}@test.com\",\"phone\":\"+1-555-111-2222\"}")"

# Then — HTTP 400 with required-fields message.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Event, name, email, and phone number are required.' "$RESPONSE_FILE" >/dev/null

echo "CODEVALID_TEST_ASSERTION_OK:form_validation_required_fields"

# Cleanup — rejected request has no side effects.
:
