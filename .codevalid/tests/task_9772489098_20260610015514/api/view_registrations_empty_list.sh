#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_empty_list_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Assume seeded in-memory data contains event evt-002 and no registrations for that event.

# When — GET /api/registrations/evt-002
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-002")"

# Then — HTTP 200 with an empty JSON array.
[ "$HTTP_STATUS" = "200" ]
BODY_COMPACT="$(tr -d '\n[:space:]' < "$RESPONSE_FILE")"
[ "$BODY_COMPACT" = "[]" ]

# Cleanup — No side effects to undo for this read-only test.

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_empty_list"
