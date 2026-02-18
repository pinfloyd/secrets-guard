#!/bin/sh
set -eu

# Expected env (GitHub Actions typical):
# GITHUB_EVENT_NAME
# GITHUB_BASE_SHA (optional)
# GITHUB_SHA
# GITHUB_WORKSPACE (typically /github/workspace)

# Always run inside the checked-out repo mount.
WS="${GITHUB_WORKSPACE:-/github/workspace}"
if [ ! -d "$WS" ]; then
  echo "ERROR: workspace dir not found: $WS"
  exit 3
fi
cd "$WS"

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

echo "$DIFF_OUTPUT" | /usr/local/bin/guardrail