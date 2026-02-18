# secrets-guard

Deterministic, zero-config, zero-telemetry CI gate that blocks newly added secrets in pull request and push diffs.

## What it does

- Scans only added lines in unified diff
- Blocks merge if a real secret is detected
- No telemetry
- No outbound network calls
- No configuration
- Deterministic output

Exit codes:
- 0 = clean
- 2 = secret detected (blocked)
- 3 = configuration/runtime error

## Usage (GitHub Action)

    name: secrets-guard

    on:
      pull_request:
      push:

    permissions:
      contents: read

    jobs:
      guard:
        runs-on: ubuntu-latest
        steps:
          - uses: actions/checkout@v4
            with:
              fetch-depth: 0

          - name: Run secrets-guard
            uses: guardrail-dev/secrets-guard@v1
            env:
              GITHUB_BASE_SHA: ${{ github.event.pull_request.base.sha }}

### Notes

- For pull_request events, pass:
  GITHUB_BASE_SHA: ${{ github.event.pull_request.base.sha }}

- For push events, the action falls back to:
  HEAD~1..HEAD

- If diff cannot be computed, the action fails with exit code 3.

## Security model

- Diff-only scanning (no historical scan)
- No suppressions
- No allow-lists
- No remote config
- Immutable rule set

This is intentionally opinionated.