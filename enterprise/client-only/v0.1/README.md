# Secrets-Guard Enterprise v0.1 — Client-Only Runtime

This package does NOT deploy Authority locally.
It is a client layer that posts intents to a remote Authority and verifies signed records offline.

## Fixed facts (v0.1)
- AUTHORITY_URL=http://107.172.34.21:8787
- verify.exe is copied from frozen Anchor:
  - VERIFY_EXE_SHA256=5a7eab12a1981668de44faf3c5fb5d4a171c18103dbd4680bf4c478e290a802b
- pubkey is fetched from AUTHORITY (/pubkey) and fixed by SHA256 in this package.

## What this is
- Client-only runtime wiring (asynchronous, zero-support).
- Intended for GitHub Actions runner context (diff-only intents).
- Offline verification using verify.exe + pubkey + record.

## What this is NOT
- Not a local Authority deployment.
- Not SaaS / multi-tenant.
- Not full-repo scanning.