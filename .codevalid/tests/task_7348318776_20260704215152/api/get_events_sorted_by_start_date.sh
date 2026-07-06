#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/get_events_sorted_by_start_date_${CASE_SUFFIX}.json"
STATUS_FILE="/tmp/get_events_sorted_by_start_date_${CASE_SUFFIX}.status"

cleanup_files() {
  rm -f "$RESPONSE_FILE" "$STATUS_FILE"
}
trap cleanup_files EXIT

# Given
TITLE_A="CV Sort A ${CASE_SUFFIX}"
TITLE_B="CV Sort B ${CASE_SUFFIX}"
TITLE_C="CV Sort C ${CASE_SUFFIX}"
TITLE_D="CV Sort D ${CASE_SUFFIX}"
TITLE_E="CV Sort E ${CASE_SUFFIX}"

for payload in \
  "{\"title\":\"${TITLE_A}\",\"description\":\"a\",\"location\":\"Loc A\",\"startDate\":\"2024-12-01\",\"endDate\":\"2024-12-02\"}" \
  "{\"title\":\"${TITLE_B}\",\"description\":\"b\",\"location\":\"Loc B\",\"startDate\":\"2024-01-15\",\"endDate\":\"2024-01-16\"}" \
  "{\"title\":\"${TITLE_C}\",\"description\":\"c\",\"location\":\"Loc C\",\"startDate\":\"2024-06-30\",\"endDate\":\"2024-07-01\"}" \
  "{\"title\":\"${TITLE_D}\",\"description\":\"d\",\"location\":\"Loc D\",\"startDate\":\"2024-03-10\",\"endDate\":\"2024-03-11\"}" \
  "{\"title\":\"${TITLE_E}\",\"description\":\"e\",\"location\":\"Loc E\",\"startDate\":\"2024-09-05\",\"endDate\":\"2024-09-06\"}"
do
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "$BASE_URL/api/events" -H 'Content-Type: application/json' --data "$payload")"
  [ "$code" = "201" ]
done

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' "$BASE_URL/api/events" > "$STATUS_FILE"

# Then
[ "$(cat "$STATUS_FILE")" = "200" ]
python - "$RESPONSE_FILE" "$TITLE_A" "$TITLE_B" "$TITLE_C" "$TITLE_D" "$TITLE_E" <<'PY'
import json, sys
path, a, b, c, d, e = sys.argv[1:7]
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
lookup = {item['title']: idx for idx, item in enumerate(data)}
for title in (a, b, c, d, e):
    assert title in lookup, f'missing {title}'
assert lookup[b] < lookup[d] < lookup[c] < lookup[e] < lookup[a], lookup
PY

echo "CODEVALID_TEST_ASSERTION_OK:get_events_sorted_by_start_date"

# Cleanup
# No cleanup endpoint exists for in-memory events; unique titles provide isolation.
