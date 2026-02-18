package rules

import (
"regexp"
"strings"
"unicode"

"guardrail-dev/secrets-guard/internal/model"
)

// Rule 1
var reAWSAccess = regexp.MustCompile(`\b(AKIA|ASIA)[A-Z0-9]{16}\b`)

// Rule 2 (context marker + 40-char base64-ish)
var reAWSSecretMarker = regexp.MustCompile(`(?i)\b(aws_secret_access_key|AWS_SECRET_ACCESS_KEY|secret_access_key)\b`)
var reAWSSecretValue = regexp.MustCompile(`([A-Za-z0-9/+=]{40})`)

// Rule 3
var reStripeLive = regexp.MustCompile(`\bsk_live_[A-Za-z0-9]{24,200}\b`)

// Rule 4 (explicit headers)
var rePrivKeyHeader = regexp.MustCompile(`-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----`)

// Rule 5 context markers
var reCtxMarker = regexp.MustCompile(`(?i)\b(secret|token|api[_-]?key|apikey|password|passwd|auth|bearer|private|signature)\b`)

func ApplyAll(line string, file string, diffLine *int) []model.Finding {
var out []model.Finding

// Rule 1
for _, m := range reAWSAccess.FindAllString(line, -1) {
out = append(out, mk("AWS_ACCESS_KEY_ID", "HIGH", file, diffLine, Mask(m), 1))
}

// Rule 2 (marker + value on same line)
if reAWSSecretMarker.FindStringIndex(line) != nil {
ms := reAWSSecretValue.FindAllString(line, -1)
for _, m := range ms {
out = append(out, mk("AWS_SECRET_ACCESS_KEY", "CRITICAL", file, diffLine, Mask(m), 2))
}
}

// Rule 3
for _, m := range reStripeLive.FindAllString(line, -1) {
out = append(out, mk("STRIPE_LIVE_SECRET_KEY", "CRITICAL", file, diffLine, Mask(m), 3))
}

// Rule 4
if rePrivKeyHeader.FindStringIndex(line) != nil {
out = append(out, mk("PRIVATE_KEY_BLOCK", "CRITICAL", file, diffLine, Mask("PRIVATE_KEY_HEADER"), 4))
}

// Rule 5
if f := ruleHighEntropy(line, file, diffLine); f != nil {
out = append(out, *f)
}

return out
}

func mk(typ, sev, file string, diffLine *int, masked string, ruleID int) model.Finding {
return model.Finding{
Type:        typ,
Severity:    sev,
File:        file,
DiffLine:    diffLine,
MaskedMatch: masked,
RuleID:      ruleID,
}
}

func ruleHighEntropy(line string, file string, diffLine *int) *model.Finding {
// must look like assignment
eq := strings.Index(line, "=")
col := strings.Index(line, ":")
pos := -1
if eq >= 0 && col >= 0 {
if eq < col {
pos = eq
} else {
pos = col
}
} else if eq >= 0 {
pos = eq
} else if col >= 0 {
pos = col
}
if pos < 0 {
return nil
}

left := line
if pos > 0 {
left = line[:pos]
}
right := ""
if pos+1 < len(line) {
right = line[pos+1:]
}

// context marker within last 64 chars of left side
l := left
if len(l) > 64 {
l = l[len(l)-64:]
}
if reCtxMarker.FindStringIndex(l) == nil {
return nil
}

cands := extractCandidates(right)
for _, c := range cands {
if len(c) < 32 {
continue
}
if !allowedAlphabet(c) {
continue
}
if countClasses(c) < 3 {
continue
}
if ShannonEntropy(c) >= 3.5 {
m := Mask(c)
f := mk("HIGH_ENTROPY_SECRET", "HIGH", file, diffLine, m, 5)
return &f // v1: report first qualifying candidate deterministically
}
}
return nil
}

func extractCandidates(right string) []string {
s := strings.TrimSpace(right)
if s == "" {
return nil
}

// quoted candidates first (deterministic order)
var out []string
if i := strings.IndexAny(s, `"'`); i >= 0 && i < len(s) {
q := s[i]
rest := s[i+1:]
if j := strings.IndexByte(rest, q); j >= 0 {
out = append(out, rest[:j])
}
}

// unquoted token until whitespace or ; , )
token := s
for idx, r := range token {
if unicode.IsSpace(r) || r == ';' || r == ',' || r == ')' {
token = token[:idx]
break
}
}
token = strings.Trim(token, `"'`)
if token != "" {
out = append(out, token)
}

// de-dup deterministic
seen := map[string]bool{}
var dedup []string
for _, c := range out {
if !seen[c] {
seen[c] = true
dedup = append(dedup, c)
}
}
return dedup
}

func allowedAlphabet(s string) bool {
for _, r := range s {
if (r >= 'a' && r <= 'z') ||
(r >= 'A' && r <= 'Z') ||
(r >= '0' && r <= '9') ||
r == '+' || r == '/' || r == '=' || r == '_' || r == '-' {
continue
}
return false
}
return true
}

func countClasses(s string) int {
hasUpper := false
hasLower := false
hasDigit := false
hasSym := false
for _, r := range s {
switch {
case r >= 'A' && r <= 'Z':
hasUpper = true
case r >= 'a' && r <= 'z':
hasLower = true
case r >= '0' && r <= '9':
hasDigit = true
case r == '+' || r == '/' || r == '=' || r == '_' || r == '-':
hasSym = true
}
}
n := 0
if hasUpper {
n++
}
if hasLower {
n++
}
if hasDigit {
n++
}
if hasSym {
n++
}
return n
}