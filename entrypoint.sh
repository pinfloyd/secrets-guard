#!/bin/sh
set -eu

echo "SECRETS-GUARD: START"
echo "EVENT=$GITHUB_EVENT_NAME"
echo "REPO=$GITHUB_REPOSITORY"
echo "WORKSPACE=$GITHUB_WORKSPACE"
echo "HEAD_REF=${GITHUB_HEAD_REF:-}"
echo "BASE_REF=${GITHUB_BASE_REF:-}"

if [ ! -d ".git" ]; then
  echo "SECRETS-GUARD: ERROR: .git not found in workspace"
  exit 2
fi

git --version

# Ensure we have full refs available (actions/checkout usually fetches, but be explicit)
git fetch --no-tags --prune --depth=0 origin "+refs/heads/*:refs/remotes/origin/*" || true

# Resolve base/head for PR runs deterministically from refs (no jq, no event JSON parsing)
BASE_SHA=""
HEAD_SHA=""

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ] && [ -n "${GITHUB_BASE_REF:-}" ] && [ -n "${GITHUB_HEAD_REF:-}" ]; then
  BASE_SHA="$(git rev-parse "refs/remotes/origin/${GITHUB_BASE_REF}")"
  HEAD_SHA="$(git rev-parse "refs/remotes/origin/${GITHUB_HEAD_REF}")"
else
  # Fallback: diff last commit vs previous commit on current HEAD
  HEAD_SHA="$(git rev-parse HEAD)"
  BASE_SHA="$(git rev-parse HEAD~1)"
fi

echo "BASE_SHA=$BASE_SHA"
echo "HEAD_SHA=$HEAD_SHA"

TMP_DIR="${RUNNER_TEMP:-/tmp}/secrets_guard"
mkdir -p "$TMP_DIR"
DIFF_FILE="$TMP_DIR/diff.txt"

# Create unified diff between base and head
echo "DIFF_RANGE: ${BASE_SHA} ${HEAD_SHA}"
echo "DIFF_FILE: ${DIFF_FILE}"
git diff "$BASE_SHA" "$HEAD_SHA" > "$DIFF_FILE" || true
echo "DIFF_BYTES: $( (wc -c < "$DIFF_FILE" 2>/dev/null) || echo 0 )"
echo "=== DIFF DEBUG START ==="
( sed -n '1,200p' "$DIFF_FILE" 2>/dev/null ) || true
echo "=== DIFF DEBUG END ==="

DIFF_BYTES="$(wc -c < "$DIFF_FILE" | tr -d ' ')"
echo "DIFF_FILE=$DIFF_FILE"
echo "DIFF_BYTES=$DIFF_BYTES"

# Guard: if diff is empty, we cannot claim clean; fail closed (forces correctness)
if [ "$DIFF_BYTES" -eq 0 ]; then
  echo "SECRETS-GUARD: ERROR: EMPTY_DIFF (cannot validate)"
  exit 3
fi

# Extract ONLY added lines, excluding file headers and '+++'
ADDED_FILE="$TMP_DIR/added_lines.txt"
# Keep lines starting with '+' but not '+++', strip leading '+'
grep -E '^\+' "$DIFF_FILE" | grep -vE '^\+\+\+' | sed 's/^\+//' > "$ADDED_FILE" || true

ADDED_BYTES="$(wc -c < "$ADDED_FILE" | tr -d ' ')"
echo "ADDED_LINES_FILE=$ADDED_FILE"
echo "ADDED_BYTES=$ADDED_BYTES"

# If no added lines, OK
if [ "$ADDED_BYTES" -eq 0 ]; then
  echo "SECRETS-GUARD: OK (no added lines)"
  exit 0
fi

# Run detector on added lines
echo "SECRETS-GUARD: SCAN (added-lines only)"
# guardrail binary is baked into image at /usr/local/bin/guardrail
/usr/local/bin/guardrail scan --stdin < "$ADDED_FILE"

RC=$?
if [ "$RC" -ne 0 ]; then
  echo "SECRETS-GUARD: VIOLATION DETECTED"
  exit 1
fi

echo "SECRETS-GUARD: OK"
exit 0