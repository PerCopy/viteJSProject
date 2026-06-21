#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/fetch_registrations_on_event_selection_events_${CASE_SUFFIX}.json"
REGS_ONE_FILE="/tmp/fetch_registrations_on_event_selection_regs1_${CASE_SUFFIX}.json"
REGS_TWO_FILE="/tmp/fetch_registrations_on_event_selection_regs2_${CASE_SUFFIX}.json"
EVENT_ONE=""
EVENT_TWO=""

cleanup() {
  rm -f "$EVENTS_FILE" "$REGS_ONE_FILE" "$REGS_TWO_FILE"
}
trap cleanup EXIT

# Given — Fetch events and identify two distinct event ids.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
EVENT_ONE="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data[0]['id'] if len(data) > 0 else '')
PY
)"
EVENT_TWO="$(python3 - "$EVENTS_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data[1]['id'] if len(data) > 1 else '')
PY
)"
[ -n "$EVENT_ONE" ]
[ -n "$EVENT_TWO" ]
[ "$EVENT_ONE" != "$EVENT_TWO" ]

# When — GET registrations for each event.
STATUS_ONE="$(curl -sS -o "$REGS_ONE_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_ONE}")"
STATUS_TWO="$(curl -sS -o "$REGS_TWO_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/${EVENT_TWO}")"

# Then — both requests succeed and both payloads are arrays.
[ "$STATUS_ONE" = "200" ]
[ "$STATUS_TWO" = "200" ]
python3 - "$REGS_ONE_FILE" "$REGS_TWO_FILE" <<'PY'
import json, sys
for path in sys.argv[1:]:
    with open(path, 'r', encoding='utf-8') as f:
        data = json.load(f)
    assert isinstance(data, list)
PY

echo "CODEVALID_TEST_ASSERTION_OK:fetch_registrations_on_event_selection"

# Cleanup — read-only requests have no side effects.
:
