#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_sorted_by_date_descending_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Assume seeded in-memory data contains event evt-003 with registrations reg-201, reg-202, and reg-203.

# When — GET /api/registrations/evt-003
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-003")"

# Then — HTTP 200 with registrations sorted reg-202, reg-203, reg-201 by registeredAt descending.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":"reg-202"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"reg-203"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"reg-201"' "$RESPONSE_FILE" >/dev/null
POS_202="$(grep -bo '"id":"reg-202"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
POS_203="$(grep -bo '"id":"reg-203"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
POS_201="$(grep -bo '"id":"reg-201"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
[ "$POS_202" -lt "$POS_203" ]
[ "$POS_203" -lt "$POS_201" ]

# Cleanup — No side effects to undo for this read-only test.

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_sorted_by_date_descending"
