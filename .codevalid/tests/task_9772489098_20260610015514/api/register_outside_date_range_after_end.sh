#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/register_outside_after_events_${CASE_SUFFIX}.json"
RESPONSE_FILE="/tmp/register_outside_after_response_${CASE_SUFFIX}.json"
REGISTRATIONS_FILE="/tmp/register_outside_after_regs_${CASE_SUFFIX}.json"
ATTENDEE_EMAIL="bob.wilson.${CASE_SUFFIX}@example.com"
EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$RESPONSE_FILE" "$REGISTRATIONS_FILE"
}
trap cleanup EXIT

# Given — Fetch events and select one whose end date is before today's UTC date.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
from datetime import datetime, timezone
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    events = json.load(f)
today = datetime.now(timezone.utc).date().isoformat()
for event in events:
    if today > event['endDate']:
        print(event['id'])
        break
PY
)"
[ -n "$EVENT_ID" ]
BEFORE_COUNT="$(curl -sS "$BASE_URL/api/registrations/${EVENT_ID}" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))')"

# When — POST /api/registrations after the event end date.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ID}\",\"name\":\"Bob Wilson\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-222-3333\"}")"

# Then — HTTP 400 with closed message and registrations unchanged.
[ "$HTTP_STATUS" = "400" ]
grep -F 'Registration is closed.' "$RESPONSE_FILE" >/dev/null
AFTER_STATUS="$(curl -sS -o "$REGISTRATIONS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ID}")"
[ "$AFTER_STATUS" = "200" ]
AFTER_COUNT="$(python3 - "$REGISTRATIONS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    print(len(json.load(f)))
PY
)"
[ "$BEFORE_COUNT" = "$AFTER_COUNT" ]
if grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$REGISTRATIONS_FILE" >/dev/null; then
  exit 1
fi

echo "CODEVALID_TEST_ASSERTION_OK:register_outside_date_range_after_end"

# Cleanup — rejected request has no side effects.
:
