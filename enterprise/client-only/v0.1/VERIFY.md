# Verify (Client-Only) — One Shot

## Smoke test (Windows PowerShell)
1) Post sample intent to Authority and save signed record:
   powershell -File "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\scripts\post_intent.ps1" -AuthorityUrl "http://107.172.34.21:8787" -IntentJsonPath "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\proof\sample_intent.json" -OutRecordPath "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\proof\sample_record.json"

2) Verify signed record offline:
   powershell -File "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\scripts\verify_record.ps1" -VerifyExePath "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\bin\verify.exe" -PubkeyJsonPath "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\pubkey\pubkey.json" -RecordJsonPath "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\proof\sample_record.json" -OutTextPath "H:\SG_ENTERPRISE_RUNTIME_v0.1\client-only\proof\verify_output.txt"

Expected:
- verify_output contains VERIFICATION_OK