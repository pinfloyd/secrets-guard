# Secrets-Guard

Hard-fail secret detection for pull requests.

Secrets-Guard blocks sensitive credentials before they reach your main branch.
No SaaS. No telemetry. No external scanning.
Runs entirely inside your GitHub Actions pipeline.

---

## What It Does

- Scans only added lines in pull requests
- Detects high-risk credentials (AWS, OpenAI, tokens, private keys)
- Fails CI immediately on violation
- Deterministic rule engine
- Zero external network calls

If a secret is detected, the merge is blocked.

---

## 60-Second Setup

Add this to your GitHub workflow:

name: Secrets Guard
on:
  pull_request:

jobs:
  scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pinfloyd/secrets-guard@v1

---

## Example Failure

OPENAI_API_KEY = "sk-XXXXXXXXXXXXXXXXXXXX"

SECRETS-GUARD: VIOLATION DETECTED
Rule: OPENAI_API_KEY_PATTERN
Status: HARD FAIL

Merge blocked.

---

## Design Principles

- Deterministic execution
- Diff-only scanning
- No telemetry
- No cloud dependency
- No silent bypass

If the rule matches — the build fails.

---

## License

See LICENSE file.