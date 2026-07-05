#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TITLE="Tech Conference 2024 ${CASE_SUFFIX}"
DESCRIPTION="Annual technology summit featuring industry leaders ${CASE_SUFFIX}"
LOCATION="Convention Center, San Francisco ${CASE_SUFFIX}"
START_DATE="2024-03-15T09:00:00Z"
END_DATE="2024-03-15T18:00:00Z"
TMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TMP_DIR/create_event_with_all_fields_success.json"
STATUS_FILE="$TMP_DIR/create_event_with_all_fields_success.status"
LIST_FILE="$TMP_DIR/create_event_with_all_fields_success_list.json"
trap 'rm -rf "$TMP_DIR"' EXIT

# Given
cat >"$TMP_DIR/request.json" <<EOF
{
  "title": "$TITLE",
  "description": "$DESCRIPTION",
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
TITLE="$TITLE" DESCRIPTION="$DESCRIPTION" LOCATION="$LOCATION" START_DATE="$START_DATE" END_DATE="$END_DATE" RESPONSE_FILE="$RESPONSE_FILE" node <<'EOF'
const fs = require('fs');
const body = JSON.parse(fs.readFileSync(process.env.RESPONSE_FILE, 'utf8'));
if (!body.id || !body.id.startsWith('event_')) process.exit(1);
if (body.title !== process.env.TITLE) process.exit(1);
if (body.description !== process.env.DESCRIPTION) process.exit(1);
if (body.location !== process.env.LOCATION) process.exit(1);
if (body.startDate !== process.env.START_DATE) process.exit(1);
if (body.endDate !== process.env.END_DATE) process.exit(1);
if (body.registrationCount !== 0) process.exit(1);
fs.writeFileSync(process.env.RESPONSE_FILE + '.id', body.id);
EOF
EVENT_ID="$(cat "$RESPONSE_FILE.id")"
curl -sS "$BASE_URL/api/events" > "$LIST_FILE"
EVENT_ID="$EVENT_ID" TITLE="$TITLE" DESCRIPTION="$DESCRIPTION" LOCATION="$LOCATION" START_DATE="$START_DATE" END_DATE="$END_DATE" LIST_FILE="$LIST_FILE" node <<'EOF'
const fs = require('fs');
const events = JSON.parse(fs.readFileSync(process.env.LIST_FILE, 'utf8'));
if (!Array.isArray(events)) process.exit(1);
const event = events.find((item) => item.id === process.env.EVENT_ID);
if (!event) process.exit(1);
if (event.title !== process.env.TITLE) process.exit(1);
if (event.description !== process.env.DESCRIPTION) process.exit(1);
if (event.location !== process.env.LOCATION) process.exit(1);
if (event.startDate !== process.env.START_DATE) process.exit(1);
if (event.endDate !== process.env.END_DATE) process.exit(1);
if (event.registrationCount !== 0) process.exit(1);
EOF

# Cleanup
# No cleanup endpoint or database access path is exposed for this in-memory service.

echo "CODEVALID_TEST_ASSERTION_OK:create_event_with_all_fields_success"
