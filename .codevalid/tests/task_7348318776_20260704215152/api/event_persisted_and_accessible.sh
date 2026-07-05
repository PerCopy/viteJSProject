#!/usr/bin/env sh
set -eu
BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="${CASE_SUFFIX:-$(date +%s)-$$}"
TITLE="Networking Session ${CASE_SUFFIX}"
DESCRIPTION="Professional networking opportunity ${CASE_SUFFIX}"
LOCATION="Downtown Conference Center ${CASE_SUFFIX}"
START_DATE="2024-09-10T17:00:00Z"
END_DATE="2024-09-10T20:00:00Z"
TMP_DIR="$(mktemp -d)"
CREATE_RESPONSE_FILE="$TMP_DIR/event_persisted_and_accessible_create.json"
CREATE_STATUS_FILE="$TMP_DIR/event_persisted_and_accessible_create.status"
LIST_FILE="$TMP_DIR/event_persisted_and_accessible_list.json"
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
curl -sS -o "$CREATE_RESPONSE_FILE" -w '%{http_code}' \
  -X POST "$BASE_URL/api/events" \
  -H 'Content-Type: application/json' \
  --data @"$TMP_DIR/request.json" > "$CREATE_STATUS_FILE"

# Then
STATUS="$(cat "$CREATE_STATUS_FILE")"
[ "$STATUS" = "201" ]
CREATE_RESPONSE_FILE="$CREATE_RESPONSE_FILE" node <<'EOF'
const fs = require('fs');
const body = JSON.parse(fs.readFileSync(process.env.CREATE_RESPONSE_FILE, 'utf8'));
if (!body.id || !body.id.startsWith('event_')) process.exit(1);
fs.writeFileSync(process.env.CREATE_RESPONSE_FILE + '.id', body.id);
EOF
EVENT_ID="$(cat "$CREATE_RESPONSE_FILE.id")"
curl -sS "$BASE_URL/api/events" > "$LIST_FILE"
EVENT_ID="$EVENT_ID" TITLE="$TITLE" DESCRIPTION="$DESCRIPTION" LOCATION="$LOCATION" START_DATE="$START_DATE" END_DATE="$END_DATE" LIST_FILE="$LIST_FILE" node <<'EOF'
const fs = require('fs');
const events = JSON.parse(fs.readFileSync(process.env.LIST_FILE, 'utf8'));
if (!Array.isArray(events)) process.exit(1);
const event = events.find((item) => item.id === process.env.EVENT_ID);
if (!event) process.exit(1);
if (event.id !== process.env.EVENT_ID) process.exit(1);
if (event.title !== process.env.TITLE) process.exit(1);
if (event.description !== process.env.DESCRIPTION) process.exit(1);
if (event.location !== process.env.LOCATION) process.exit(1);
if (event.startDate !== process.env.START_DATE) process.exit(1);
if (event.endDate !== process.env.END_DATE) process.exit(1);
if (event.registrationCount !== 0) process.exit(1);
EOF

# Cleanup
# No cleanup endpoint or database access path is exposed for this in-memory service.

echo "CODEVALID_TEST_ASSERTION_OK:event_persisted_and_accessible"
