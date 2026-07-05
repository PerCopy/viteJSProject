#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/create_event_missing_end_date.json"
STATUS_FILE="$TMP_DIR/create_event_missing_end_date.status"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
cat >"$TMP_DIR/request.json" <<EOF
{
  "title": "Seminar Series",
  "description": "Educational seminars",
  "location": "University Hall",
  "startDate": "2024-06-01T13:00:00Z"
}
EOF

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "400" ]
grep -F '"message":"Title, start date, end date, and location are required."' "$RESPONSE_FILE" >/dev/null

# Cleanup
# Stateless negative test; no cleanup needed.

echo "CODEVALID_TEST_ASSERTION_OK:create_event_missing_end_date"
