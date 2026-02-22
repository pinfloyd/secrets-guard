param(
    [Parameter(Mandatory=$true)][string]$AuthorityUrl,
    [Parameter(Mandatory=$true)][string]$IntentJsonPath,
    [Parameter(Mandatory=$true)][string]$OutRecordPath
)

$ErrorActionPreference="Stop"

if(-not (Test-Path $IntentJsonPath)){
    throw "MISSING_INTENT_JSON:$IntentJsonPath"
}

$intent = Get-Content -Raw -Path $IntentJsonPath
if([string]::IsNullOrWhiteSpace($intent)){
    throw "EMPTY_INTENT_JSON:$IntentJsonPath"
}

$resp = & curl.exe -sS -X POST "$AuthorityUrl/admit" `
    -H "Content-Type: application/json" `
    --data-binary "$intent"

if($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($resp)){
    throw "ADMIT_FAILED"
}

Set-Content -Encoding UTF8 -NoNewline -Path $OutRecordPath -Value $resp
$h=(Get-FileHash -Algorithm SHA256 -Path $OutRecordPath).Hash.ToLower()
Set-Content -Encoding ASCII -NoNewline -Path "$OutRecordPath.sha256.txt" -Value "$h  $(Split-Path -Leaf $OutRecordPath)"

try{
    $obj=$resp | ConvertFrom-Json
    $decision=[string]$obj.decision
}catch{
    $decision=""
}

"RECORD_FILE=$OutRecordPath"
"RECORD_SHA256=$h"
"DECISION=$decision"

if($decision -eq "DENY"){ exit 2 }
exit 0