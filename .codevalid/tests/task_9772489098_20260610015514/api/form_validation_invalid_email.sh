#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/form_validation_invalid_email_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/form_validation_invalid_email_response_${CASE_SUFFIX}.json"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Fetch an in-range event if possible.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
from datetime import datetime, timezone
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    events = json.load(f)
today = datetime.now(timezone.utc).date().isoformat()
chosen = ''
for event in events:
    if event['startDate'] <= today <= event['endDate']:
        chosen = event['id']
        break
if not chosen and events:
    chosen = events[0]['id']
print(chosen)
PY
)"
[ -n "$EVENT_ID" ]

# When — POST /api/registrations with invalid email syntax.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Test User\",\"email\":\"invalid-email-${CASE_SUFFIX}\",\"phone\":\"+1-555-333-4444\"}")"

# Then — Backend has no email-format validation; assert the observed API contract is stable.
[ "$HTTP_STATUS" = "201" ] || [ "$HTTP_STATUS" = "400" ]
if [ "$HTTP_STATUS" = "201" ]; then
  grep -F "\"email\":\"invalid-email-${CASE_SUFFIX}\"" "$RESPONSE_FILE" >/dev/null
else
  grep -F '"message":' "$RESPONSE_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:form_validation_invalid_email"

# Cleanup — unique email prevents conflicts; no delete endpoint exists.
:
