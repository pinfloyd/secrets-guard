#!/bin/sh
set -eu

# Fix Git "dubious ownership" inside container (CVE-2022-24765 hardening)
git config --global --add safe.directory /github/workspace || true

# --- Deterministic workspace guard ---
WS="${GITHUB_WORKSPACE:-/github/workspace}"

if [ -d "$WS" ]; then
  cd "$WS"
fi

if [ ! -d ".git" ]; then
  echo "ERROR: not inside a git repository (pwd=$(pwd))" >&2
  exit 3
fi
# --- End guard ---

# Compute diff (PR vs push compatible)
if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  git fetch origin "${GITHUB_BASE_REF}" --depth=1
  DIFF="$(git diff --unified=0 "origin/${GITHUB_BASE_REF}"...HEAD)"
else
  DIFF="$(git diff --unified=0 HEAD~1 HEAD || true)"
fi

echo "$DIFF" | /usr/local/bin/guardrail scan --stdin