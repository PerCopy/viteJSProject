#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
FIRST_RESPONSE_FILE="/tmp/create_event_generates_unique_id_first_${CASE_SUFFIX}.json"
FIRST_STATUS_FILE="/tmp/create_event_generates_unique_id_first_${CASE_SUFFIX}.status"
SECOND_RESPONSE_FILE="/tmp/create_event_generates_unique_id_second_${CASE_SUFFIX}.json"
SECOND_STATUS_FILE="/tmp/create_event_generates_unique_id_second_${CASE_SUFFIX}.status"
cleanup_files() { rm -f "$FIRST_RESPONSE_FILE" "$FIRST_STATUS_FILE" "$SECOND_RESPONSE_FILE" "$SECOND_STATUS_FILE"; }
trap cleanup_files EXIT

# Given
TITLE_ONE="Event Alpha ${CASE_SUFFIX}"
TITLE_TWO="Event Beta ${CASE_SUFFIX}"
LOCATION="Austin Center ${CASE_SUFFIX}"

# When
curl -sS -o "$FIRST_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_ONE}\",\"location\":\"${LOCATION}\",\"startDate\":\"2024-06-01\",\"endDate\":\"2024-06-01\"}" > "$FIRST_STATUS_FILE"
curl -sS -o "$SECOND_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data "{\"title\":\"${TITLE_TWO}\",\"location\":\"${LOCATION}\",\"startDate\":\"2024-06-02\",\"endDate\":\"2024-06-02\"}" > "$SECOND_STATUS_FILE"

# Then
[ "$(cat "$FIRST_STATUS_FILE")" = "201" ]
[ "$(cat "$SECOND_STATUS_FILE")" = "201" ]
python - <<'PY' "$FIRST_RESPONSE_FILE" "$SECOND_RESPONSE_FILE" "$TITLE_ONE" "$TITLE_TWO"
import json, sys
first_path, second_path, title_one, title_two = sys.argv[1:]
with open(first_path, 'r', encoding='utf-8') as fh:
    first = json.load(fh)
with open(second_path, 'r', encoding='utf-8') as fh:
    second = json.load(fh)
assert first.get('id'), first
assert second.get('id'), second
assert first['id'] != second['id'], (first, second)
assert first.get('title') == title_one, first
assert second.get('title') == title_two, second
PY

# Cleanup
: "No cleanup endpoint exists for the in-memory store; test data is uniquely namespaced"

echo "CODEVALID_TEST_ASSERTION_OK:create_event_generates_unique_id"
