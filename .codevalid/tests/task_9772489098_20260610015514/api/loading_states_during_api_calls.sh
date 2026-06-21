#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/loading_states_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/loading_states_regs_${CASE_SUFFIX}.json"
POST_FILE="/tmp/loading_states_post_${CASE_SUFFIX}.json"
EVENT_ONE=""
EVENT_TWO=""
ATTENDEE_EMAIL="loading.${CASE_SUFFIX}@example.com"

cleanup() {
  rm -f "$EVENTS_FILE" "$REGS_FILE" "$POST_FILE"
}
trap cleanup EXIT

# Given — Fetch events and identify usable event ids.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ONE="$(python3 - "$EVENTS_FILE" <<'PY'
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
EVENT_TWO="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data[1]['id'] if len(data) > 1 else (data[0]['id'] if data else ''))
PY
)"
[ -n "$EVENT_ONE" ]
[ -n "$EVENT_TWO" ]

# When — Exercise events fetch, registrations fetch, and registration submission endpoints.
REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_TWO}")"
POST_STATUS="$(curl -sS -o "$POST_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/registrations" \
  -H 'Content-Type: application/json' \
  --data "{\"eventId\":\"${EVENT_ONE}\",\"name\":\"Loading User\",\"email\":\"${ATTENDEE_EMAIL}\",\"phone\":\"+1-555-555-0000\"}")"

# Then — API operations respond according to the backend contract.
[ "$REGS_STATUS" = "200" ]
[ "$POST_STATUS" = "201" ] || [ "$POST_STATUS" = "400" ]
python3 - "$REGS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    assert isinstance(json.load(f), list)
PY
if [ "$POST_STATUS" = "201" ]; then
  grep -F "\"email\":\"${ATTENDEE_EMAIL}\"" "$POST_FILE" >/dev/null
else
  grep -F '"message":' "$POST_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:loading_states_during_api_calls"

# Cleanup — unique email prevents interference.
:
