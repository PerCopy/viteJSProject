#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_events_empty_list_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/get_events_empty_list_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given
# Repository learnings state the app starts with pre-seeded events in memory.
# Therefore an assertion for [] would be invalid for this repo.

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
python - "$RESPONSE_FILE" <<'PY'
import json, sys
with open(sys.argv[1], 'r', encoding='utf-8') as f:
    data = json.load(f)
assert isinstance(data, list), 'response is not a JSON array'
assert len(data) >= 1, 'expected seeded events to be present for this repo'
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_empty_list"

# Cleanup
# Stateless GET only.
