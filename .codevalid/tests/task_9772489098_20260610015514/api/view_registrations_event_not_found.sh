#!/usr/bin/env sh
set -eu

BASE_URL="${BASE_URL:-http://app:6713}"
CASE_SUFFIX="$(date +%s)-$$"
RESPONSE_FILE="/tmp/view_registrations_event_not_found_${CASE_SUFFIX}.json"

cleanup() {
  rm -f "$RESPONSE_FILE"
}
trap cleanup EXIT

# Given — Assume no event exists with id evt-nonexistent in the in-memory dataset.

# When — GET /api/registrations/evt-nonexistent
HTTP_STATUS="$(curl -sS -o "$RESPONSE_FILE" -w '%{http_code}' \
  "$BASE_URL/api/registrations/evt-nonexistent")"

# Then — HTTP 404 with Event not found message.
[ "$HTTP_STATUS" = "404" ]
grep -F '"message":"Event not found."' "$RESPONSE_FILE" >/dev/null

# Cleanup — No side effects to undo for this read-only test.

echo "CODEVALID_TEST_ASSERTION_OK:view_registrations_event_not_found"
