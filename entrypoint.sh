#!/bin/sh
set -eu

# Expected env (GitHub Actions typical):
# GITHUB_EVENT_NAME
# GITHUB_BASE_SHA (optional)
# GITHUB_SHA

# Fallback logic:
# 1) If GITHUB_BASE_SHA present → diff BASE..HEAD
# 2) Else if event is pull_request and BASE_REF available → try merge-base
# 3) Else → diff HEAD~1..HEAD
# If diff cannot be computed → exit 3

HEAD_SHA="${GITHUB_SHA:-}"
BASE_SHA="${GITHUB_BASE_SHA:-}"

if [ -z "$HEAD_SHA" ]; then
  echo "ERROR: GITHUB_SHA not set."
  exit 3
fi

# Ensure we are inside a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: not inside a git repository."
  exit 3
fi

if [ -n "$BASE_SHA" ]; then
  DIFF_CMD="git diff --unified=0 $BASE_SHA $HEAD_SHA"
else
  # Fallback: previous commit
  if git rev-parse HEAD~1 >/dev/null 2>&1; then
    DIFF_CMD="git diff --unified=0 HEAD~1 HEAD"
  else
    echo "ERROR: unable to determine base commit for diff."
    exit 3
  fi
fi

# Execute diff and pipe to CLI
# If git diff fails, exit 3
if ! DIFF_OUTPUT="$(sh -c "$DIFF_CMD")"; then
  echo "ERROR: git diff failed."
  exit 3
fi

# Pipe to guardrail
echo "$DIFF_OUTPUT" | guardrail scan --stdin
EXIT_CODE=$?

exit $EXIT_CODE