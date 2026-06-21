#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_for_existing_event_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Assume seeded in-memory data contains event evt-001 and two registrations for that event.
# Given — This endpoint is read-only and no setup API or database seam is exposed in the provided call graph.

# When — GET /api/registrations/evt-001
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-001")"

# Then — HTTP 200 with two registrations sorted by registeredAt descending, reg-102 before reg-101.
[ "$HTTP_STATUS" = "200" ]
grep -F '"id":"reg-102"' "$RESPONSE_FILE" >/dev/null
grep -F '"id":"reg-101"' "$RESPONSE_FILE" >/dev/null
grep -F '"eventId":"evt-001"' "$RESPONSE_FILE" >/dev/null
POS_102="$(grep -bo '"id":"reg-102"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
POS_101="$(grep -bo '"id":"reg-101"' "$RESPONSE_FILE" | head -1 | cut -d: -f1)"
[ "$POS_102" -lt "$POS_101" ]

# Cleanup — No side effects to undo for this read-only test.

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_for_existing_event"
