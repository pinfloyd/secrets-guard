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
  BASE="${GITHUB_BASE_REF:-master}"

  git fetch --prune origin "+refs/heads/*:refs/remotes/origin/*" || true

  if ! git show-ref --verify --quiet "refs/remotes/origin/$BASE"; then
    BASE="main"
  fi

  BASE_SHA="$(git merge-base HEAD origin/$BASE || true)"

  DIFF="$(git diff --unified=0 "$BASE_SHA" HEAD || true)"
else
  DIFF="$(git diff --unified=0 HEAD~1 HEAD || true)"
fi

echo "$DIFF" | /usr/local/bin/guardrail scan --stdin