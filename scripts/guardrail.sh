#!/usr/bin/env bash
set -euo pipefail

echo "guardrail runner-side diff mode"

if [ ! -d .git ]; then
  echo "ERROR: not a git repo"
  exit 3
fi

BASE="${GITHUB_BASE_SHA:-}"
HEAD="${GITHUB_SHA:-}"

if [ -z "$BASE" ] || [ -z "$HEAD" ]; then
  echo "ERROR: missing SHAs"
  exit 3
fi

git diff --unified=0 "$BASE" "$HEAD"