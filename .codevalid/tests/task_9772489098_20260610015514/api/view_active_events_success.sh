#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_active_events_success_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — API base URL is available; use unique temp files for this case.
:

# When — GET /api/events to load the events list.
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events")"

# Then — HTTP 200 and response contains event fields.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":' "$RESPONSE_FILE" >/dev/null
grep -F '"title":' "$RESPONSE_FILE" >/dev/null
grep -F '"startDate":' "$RESPONSE_FILE" >/dev/null
grep -F '"endDate":' "$RESPONSE_FILE" >/dev/null
grep -F '"registrationCount":' "$RESPONSE_FILE" >/dev/null
FIRST_EVENT_ID="$(python3 - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
print(data[0]['id'] if isinstance(data, list) and data else '')
PY
)"
[ -n "$FIRST_EVENT_ID" ]

echo "CODEVALID_TEST_ASSERTION_OK:view_active_events_success"

# Cleanup — no side effects to undo.
:
