#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
LIST_RESPONSE="/tmp/get_events_empty_state_${CASE_SUFFIX}.json"
LIST_STATUS="/tmp/get_events_empty_state_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$LIST_RESPONSE" "$LIST_STATUS"
}
trap cleanup_files EXIT

# Given — verify the service currently has no events
curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$LIST_STATUS"
[ "$(cat "$LIST_STATUS")" = "200" ]
python - <<'PY' "$LIST_RESPONSE"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    payload = json.load(f)
assert payload == [], payload
PY

# When — send HTTP GET request to /api/events again
curl -sS -o "$LIST_RESPONSE" -w '%{http_code}' \
  "$BASE_URL/api/events" > "$LIST_STATUS"

# Then — verify response status code is 200 and JSON body is an empty array
STATUS="$(cat "$LIST_STATUS")"
[ "$STATUS" = "200" ]
python - <<'PY' "$LIST_RESPONSE"
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    payload = json.load(f)
assert payload == [], payload
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_empty_state"
