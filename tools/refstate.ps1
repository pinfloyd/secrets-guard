$ErrorActionPreference="Stop"

function NormPath([string]$p){
  # normalize to full path, trim trailing slashes, case-insensitive compare later
  $fp = [System.IO.Path]::GetFullPath($p)
  return $fp.TrimEnd('\','/')
}

# === 0) Strict prechecks ===
$TOP = (git rev-parse --show-toplevel).Trim()
if(-not $TOP){ throw "NOT_A_GIT_REPO" }

$here = NormPath (Get-Location).Path
$root = NormPath $TOP

if($here.ToLowerInvariant() -ne $root.ToLowerInvariant()){
  throw "NOT_AT_REPO_ROOT: here=$here root=$root"
}

$st = git status --porcelain
if($st){ throw "WORKTREE_NOT_CLEAN:`n$st" }

# === 1) Facts ===
$ts  = Get-Date -Format "yyyyMMdd_HHmmss"
$iso = Get-Date -Format "s"
$HEAD   = (git rev-parse HEAD).Trim()
$BRANCH = (git rev-parse --abbrev-ref HEAD).Trim()
$remote = (git remote -v | Out-String).TrimEnd()

# === 2) Output dirs ===
$outDir = Join-Path $root "out"
$refDir = Join-Path $root "refstate"
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
New-Item -ItemType Directory -Force -Path $refDir | Out-Null

# === 3) Tree inventories + hashes ===
$invAll = Join-Path $outDir "TREE_ALL_FILES_$ts.txt"
$invGit = Join-Path $outDir "TREE_GIT_TRACKED_$ts.txt"

Get-ChildItem -Force -Recurse -File -Path $root |
  Select-Object FullName, Length, LastWriteTime |
  Sort-Object FullName |
  Out-String | Set-Content -Encoding UTF8 -NoNewline -Path $invAll

git ls-files | Sort-Object | Out-String | Set-Content -Encoding UTF8 -NoNewline -Path $invGit

$hAll = (Get-FileHash -Algorithm SHA256 -Path $invAll).Hash.ToLower()
$hGit = (Get-FileHash -Algorithm SHA256 -Path $invGit).Hash.ToLower()

function ShaRel([string]$rel){
  $full = Join-Path $root $rel
  if(Test-Path $full){ return (Get-FileHash -Algorithm SHA256 -Path $full).Hash.ToLower() }
  return "MISSING"
}

$k = [ordered]@{
  "action.yml"                 = ShaRel "action.yml"
  "entrypoint.sh"              = ShaRel "entrypoint.sh"
  ".github/workflows/ci.yml"   = ShaRel ".github\workflows\ci.yml"
  ".github/workflows/beta.yml" = ShaRel ".github\workflows\beta.yml"
  "cmd/guardrail/main.go"      = ShaRel "cmd\guardrail\main.go"
  "go.mod"                     = ShaRel "go.mod"
  "go.sum"                     = ShaRel "go.sum"
  "Dockerfile"                 = ShaRel "Dockerfile"
  "README.md"                  = ShaRel "README.md"
}

# === 4) Evidence link: locate PR enforcement run (best-effort, still facts-only) ===
$REPO = "pinfloyd/secrets-guard"
$WF   = "ci"

$enfRunId = ""
$enfRunTitle = ""
$enfRunCreated = ""

try {
  $runsJson = gh run list -R $REPO --workflow $WF --event pull_request --limit 20 --json databaseId,displayTitle,createdAt
  $runs = $runsJson | ConvertFrom-Json
  foreach($r in $runs){
    $rid = [string]$r.databaseId
    if(-not $rid){ continue }
    $log = gh run view $rid -R $REPO --log
    if($log -match "BLOCKED:" -and $log -match '"findings_count"\s*:\s*2'){
      $enfRunId = $rid
      $enfRunTitle = [string]$r.displayTitle
      $enfRunCreated = [string]$r.createdAt
      break
    }
  }
} catch {
  $enfRunId = ""
}

# === 5) Write REFSTATE + sha256 ===
$ref = Join-Path $refDir "REFSTATE_$ts.txt"
$refSha = "$ref.sha256"

$lines = New-Object System.Collections.Generic.List[string]
$lines.Add("Secrets-Guard — Reference State (facts)")
$lines.Add("Generated: $iso")
$lines.Add("RepoRoot: $root")
$lines.Add("Branch: $BRANCH")
$lines.Add("HEAD: $HEAD")
$lines.Add("Remote:")
$lines.Add($remote)
$lines.Add("")
$lines.Add("Tree inventories:")
$lines.Add("TREE_ALL_FILES_FILE: $invAll")
$lines.Add("TREE_ALL_FILES_SHA256: $hAll")
$lines.Add("TREE_GIT_TRACKED_FILE: $invGit")
$lines.Add("TREE_GIT_TRACKED_SHA256: $hGit")
$lines.Add("")
$lines.Add("Key file SHA-256:")
foreach($key in $k.Keys){ $lines.Add(("{0}: {1}" -f $key, $k[$key])) }
$lines.Add("")
$lines.Add("Enforcement validation (evidence-linked):")
if($enfRunId){
  $lines.Add("PR_ENFORCEMENT_RUN_ID: $enfRunId")
  $lines.Add("PR_ENFORCEMENT_RUN_TITLE: $enfRunTitle")
  $lines.Add("PR_ENFORCEMENT_RUN_CREATED_AT: $enfRunCreated")
  $lines.Add("PR_ENFORCEMENT_EVIDENCE: log contains 'BLOCKED:' and 'findings_count:2'")
} else {
  $lines.Add("PR_ENFORCEMENT_RUN_ID: NOT_RESOLVED_BY_GH")
}

($lines -join "`n") | Set-Content -Encoding UTF8 -NoNewline -Path $ref

$refHash = (Get-FileHash -Algorithm SHA256 -Path $ref).Hash.ToLower()
Set-Content -Encoding ASCII -NoNewline -Path $refSha -Value ("$refHash  " + (Split-Path -Leaf $ref))

"REFSTATE_FILE = $ref"
"REFSTATE_SHA256 = $refHash"
"TREE_ALL_FILES_SHA256 = $hAll"
"TREE_GIT_TRACKED_SHA256 = $hGit"
if($enfRunId){ "PR_ENFORCEMENT_RUN_ID = $enfRunId" } else { "PR_ENFORCEMENT_RUN_ID = NOT_RESOLVED_BY_GH" }
"REFERENCE_STATE_FIXED = True"