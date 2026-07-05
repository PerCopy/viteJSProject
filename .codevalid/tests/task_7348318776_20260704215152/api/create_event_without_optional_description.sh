#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TITLE="Team Meeting ${CASE_SUFFIX}"
LOCATION="Building A, Room 301 ${CASE_SUFFIX}"
START_DATE="2024-02-01T14:00:00Z"
END_DATE="2024-02-01T15:00:00Z"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/create_event_without_optional_description.json"
STATUS_FILE="$TMP_DIR/create_event_without_optional_description.status"
LIST_FILE="$TMP_DIR/create_event_without_optional_description_list.json"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
cat >"$TMP_DIR/request.json" <<EOF
{
  "title": "$TITLE",
  "location": "$LOCATION",
  "startDate": "$START_DATE",
  "endDate": "$END_DATE"
}
EOF

# When
curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$STATUS_FILE"

# Then
STATUS="$(cat "$STATUS_FILE")"
[ "$STATUS" = "201" ]
TITLE="$TITLE" LOCATION="$LOCATION" START_DATE="$START_DATE" END_DATE="$END_DATE" RESPONSE_FILE="$RESPONSE_FILE" node <<'EOF'
const fs = require('fs');
const body = JSON.parse(fs.readFileSync(process.env.RESPONSE_FILE, 'utf8'));
if (!body.id || !body.id.startsWith('event_')) process.exit(1);
if (body.title !== process.env.TITLE) process.exit(1);
if (body.description !== '') process.exit(1);
if (body.location !== process.env.LOCATION) process.exit(1);
if (body.startDate !== process.env.START_DATE) process.exit(1);
if (body.endDate !== process.env.END_DATE) process.exit(1);
if (body.registrationCount !== 0) process.exit(1);
fs.writeFileSync(process.env.RESPONSE_FILE + '.id', body.id);
EOF
EVENT_ID="$(cat "$RESPONSE_FILE.id")"
curl -sS "$BASE_URL/api/events" > "$LIST_FILE"
EVENT_ID="$EVENT_ID" TITLE="$TITLE" LOCATION="$LOCATION" START_DATE="$START_DATE" END_DATE="$END_DATE" LIST_FILE="$LIST_FILE" node <<'EOF'
const fs = require('fs');
const events = JSON.parse(fs.readFileSync(process.env.LIST_FILE, 'utf8'));
if (!Array.isArray(events)) process.exit(1);
const event = events.find((item) => item.id === process.env.EVENT_ID);
if (!event) process.exit(1);
if (event.title !== process.env.TITLE) process.exit(1);
if (event.description !== '') process.exit(1);
if (event.location !== process.env.LOCATION) process.exit(1);
if (event.startDate !== process.env.START_DATE) process.exit(1);
if (event.endDate !== process.env.END_DATE) process.exit(1);
if (event.registrationCount !== 0) process.exit(1);
EOF

# Cleanup
# No cleanup endpoint or database access path is exposed for this in-memory service.

echo "CODEVALID_TEST_ASSERTION_OK:create_event_without_optional_description"
