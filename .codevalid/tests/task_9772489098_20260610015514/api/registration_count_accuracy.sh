#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/registration_count_accuracy_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/registration_count_accuracy_regs_${CASE_SUFFIX}.json"
EVENT_BLOCKS_FILE="/tmp/registration_count_accuracy_blocks_${CASE_SUFFIX}.txt"

# Given — Retrieve the current events list.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]

# When — For each event returned, request its registrations by event id.
tr '{' '\n' < "$EVENTS_FILE" | grep '"id":"' > "$EVENT_BLOCKS_FILE"

# Then — Each event's registrationCount matches the number of registrations returned by /api/registrations/:eventId.
while IFS= read -r BLOCK; do
  EVENT_ID="$(printf '%s' "$BLOCK" | sed -n 's/.*"id":"\([^"]*\)".*/\1/p')"
  EXPECTED_COUNT="$(printf '%s' "$BLOCK" | sed -n 's/.*"registrationCount":\([0-9][0-9]*\).*/\1/p')"
  [ -n "$EVENT_ID" ] || continue
  [ -n "$EXPECTED_COUNT" ] || continue
  REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"
  [ "$REGS_STATUS" = "200" ]
  ACTUAL_COUNT="$(grep -o '"registeredAt":"' "$REGS_FILE" | wc -l | tr -d ' ')"
  [ "$ACTUAL_COUNT" = "$EXPECTED_COUNT" ]
done < "$EVENT_BLOCKS_FILE"

echo "CODEVALID_TEST_ASSERTION_OK:registration_count_accuracy"

# Cleanup — Remove temp files.
rm -f "$EVENTS_FILE" "$REGS_FILE" "$EVENT_BLOCKS_FILE"
