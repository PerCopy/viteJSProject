#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/event_auto_selection_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/event_auto_selection_regs_${CASE_SUFFIX}.json"
FIRST_EVENT_ID=""

cleanup() {
  rm -f "$EVENTS_FILE" "$REGS_FILE"
}
trap cleanup EXIT

# Given — Events endpoint is available.
:

# When — GET /api/events, then fetch registrations for the first returned event.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
FIRST_EVENT_ID="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data[0]['id'] if len(data) > 0 else '')
PY
)"
[ -n "$FIRST_EVENT_ID" ]
REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${FIRST_EVENT_ID}")"

# Then — First event is usable for registrations lookup and payload is an array.
[ "$REGS_STATUS" = "200" ]
python3 - "$REGS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    assert isinstance(json.load(f), list)
PY

echo "CODEVALID_TEST_ASSERTION_OK:event_auto_selection"

# Cleanup — no side effects.
:
