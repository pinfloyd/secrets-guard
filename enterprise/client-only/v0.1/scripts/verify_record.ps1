param(
    [Parameter(Mandatory=$true)][string]$VerifyExePath,
    [Parameter(Mandatory=$true)][string]$PubkeyJsonPath,
    [Parameter(Mandatory=$true)][string]$RecordJsonPath,
    [Parameter(Mandatory=$true)][string]$OutTextPath
)

$ErrorActionPreference="Stop"

if(-not (Test-Path $VerifyExePath)){ throw "MISSING_VERIFY_EXE:$VerifyExePath" }
if(-not (Test-Path $PubkeyJsonPath)){ throw "MISSING_PUBKEY_JSON:$PubkeyJsonPath" }
if(-not (Test-Path $RecordJsonPath)){ throw "MISSING_RECORD_JSON:$RecordJsonPath" }

$out=& "$VerifyExePath" --pubkey "$PubkeyJsonPath" --record "$RecordJsonPath" 2>&1 | Out-String
$code=$LASTEXITCODE

Set-Content -Encoding UTF8 -NoNewline -Path $OutTextPath -Value $out
$h=(Get-FileHash -Algorithm SHA256 -Path $OutTextPath).Hash.ToLower()
Set-Content -Encoding ASCII -NoNewline -Path "$OutTextPath.sha256.txt" -Value "$h  $(Split-Path -Leaf $OutTextPath)"

"VERIFY_OUTPUT_FILE=$OutTextPath"
"VERIFY_OUTPUT_SHA256=$h"
"EXITCODE=$code"

if($code -ne 0 -or $out -notmatch "VERIFICATION_OK"){ exit 3 }
exit 0