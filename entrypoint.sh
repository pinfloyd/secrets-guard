#!/bin/sh
set -eu

git config --global --add safe.directory /github/workspace || true

WS="${GITHUB_WORKSPACE:-/github/workspace}"
cd "$WS"

if [ ! -d ".git" ]; then
  echo "ERROR: not inside a git repository"
  exit 3
fi

if [ "${GITHUB_EVENT_NAME:-}" = "pull_request" ]; then
  BASE_SHA="$(jq -r .pull_request.base.sha "$GITHUB_EVENT_PATH")"
  HEAD_SHA="$(jq -r .pull_request.head.sha "$GITHUB_EVENT_PATH")"

  git fetch --prune origin "+refs/heads/*:refs/remotes/origin/*" || true

  DIFF="$(git diff --unified=0 "$BASE_SHA" "$HEAD_SHA" || true)"
else
  DIFF="$(git diff --unified=0 HEAD~1 HEAD || true)"
fi

echo "$DIFF" | /usr/local/bin/guardrail scan --stdin