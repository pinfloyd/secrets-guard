#!/bin/sh
set -eu

git config --global --add safe.directory /github/workspace || true

WS="${GITHUB_WORKSPACE:-/github/workspace}"
cd "$WS"

if [ ! -d ".git" ]; then
  echo "ERROR: not inside a git repository (pwd=$(pwd))" >&2
  exit 3
fi

# -----------------------------
# Robust diff logic
# -----------------------------
if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  BASE="${GITHUB_BASE_REF:-master}"

  # Fetch full history for correct merge-base
  git fetch --prune origin "+refs/heads/*:refs/remotes/origin/*" || true

  # Fallback if branch doesn't exist
  if ! git show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
    BASE="main"
  fi

  DIFF="$(git diff --unified=0 "origin/$BASE"...HEAD || true)"
else
  DIFF="$(git diff --unified=0 HEAD~1 HEAD || true)"
fi

echo "$DIFF" | /usr/local/bin/guardrail scan --stdin