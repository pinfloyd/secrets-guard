#!/bin/sh
set -e

echo "EVENT: $GITHUB_EVENT_NAME"

if [ "$GITHUB_EVENT_NAME" = "pull_request" ]; then
  BASE_SHA=$(grep '"base"' -A5 "$GITHUB_EVENT_PATH" | grep '"sha"' | head -1 | sed 's/.*"sha": "\(.*\)".*/\1/')
  HEAD_SHA=$(grep '"head"' -A5 "$GITHUB_EVENT_PATH" | grep '"sha"' | head -1 | sed 's/.*"sha": "\(.*\)".*/\1/')
  git fetch --no-tags origin "$BASE_SHA"
  DIFF_RANGE="$BASE_SHA $HEAD_SHA"

elif [ "$GITHUB_EVENT_NAME" = "push" ]; then
  if git rev-parse HEAD~1 >/dev/null 2>&1; then
    DIFF_RANGE="HEAD~1 HEAD"
  else
    DIFF_RANGE="HEAD"
  fi

else
  git fetch origin master || true
  BASE=$(git merge-base HEAD origin/master 2>/dev/null || echo "")
  if [ -n "$BASE" ]; then
    DIFF_RANGE="$BASE HEAD"
  else
    DIFF_RANGE="HEAD"
  fi
fi

echo "DIFF_RANGE: $DIFF_RANGE"

git diff $DIFF_RANGE > /tmp/diff.txt || true

if grep -E "sk-[A-Za-z0-9]{20,}" /tmp/diff.txt >/dev/null; then
  echo "SECRETS-GUARD: VIOLATION DETECTED"
  exit 1
fi

echo "SECRETS-GUARD: OK"
exit 0