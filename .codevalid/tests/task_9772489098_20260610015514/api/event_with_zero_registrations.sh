#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
EVENTS_FILE="/tmp/event_with_zero_registrations_events_${CASE_SUFFIX}.json"
REGS_FILE="/tmp/event_with_zero_registrations_regs_${CASE_SUFFIX}.json"
ZERO_IDS_FILE="/tmp/event_with_zero_registrations_ids_${CASE_SUFFIX}.txt"

# Given — Retrieve the events list and discover any event with registrationCount 0.
EVENTS_STATUS="$(curl -sS -o "$EVENTS_FILE" -w '%{http_code}' "$BASE_URL/api/events")"
[ "$EVENTS_STATUS" = "200" ]
tr '{' '\n' < "$EVENTS_FILE" | grep '"registrationCount":0' | sed -n 's/.*"id":"\([^"]*\)".*/\1/p' > "$ZERO_IDS_FILE"

# When — Request registrations for each zero-count event.

# Then — Each discovered zero-count event has an empty registrations array.
if [ -s "$ZERO_IDS_FILE" ]; then
  while IFS= read -r EVENT_ID; do
    [ -n "$EVENT_ID" ] || continue
    REGS_STATUS="$(curl -sS -o "$REGS_FILE" -w '%{http_code}' "$BASE_URL/api/registrations/$EVENT_ID")"
    [ "$REGS_STATUS" = "200" ]
    grep -Eq '^\[\]$' "$REGS_FILE"
  done < "$ZERO_IDS_FILE"
else
  grep -F '"registrationCount":' "$EVENTS_FILE" >/dev/null
fi

echo "CODEVALID_TEST_ASSERTION_OK:event_with_zero_registrations"

# Cleanup — Remove temp files.
rm -f "$EVENTS_FILE" "$REGS_FILE" "$ZERO_IDS_FILE"
