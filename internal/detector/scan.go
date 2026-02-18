package detector

import (
"path/filepath"
"strings"

"guardrail-dev/secrets-guard/internal/diff"
"guardrail-dev/secrets-guard/internal/model"
"guardrail-dev/secrets-guard/internal/rules"
)

var excludedExt = map[string]bool{
".md":  true,
".txt": true,
}

func isExcludedFile(path string) bool {
if path == "" {
return false
}
base := strings.ToUpper(filepath.Base(path))
if strings.HasPrefix(base, "LICENSE") || strings.HasPrefix(base, "NOTICE") || strings.HasPrefix(base, "CHANGELOG") {
return true
}
ext := strings.ToLower(filepath.Ext(path))
if excludedExt[ext] {
return true
}
return false
}

// ScanUnifiedDiff scans unified diff text, but only added lines ("+"), excluding diff headers.
// It returns all findings in deterministic order: by appearance in diff, and within a line by ascending RuleID.
func ScanUnifiedDiff(unified string) ([]model.Finding, error) {
if unified == "" {
return nil, nil
}

events, err := diff.ParseUnified(unified)
if err != nil {
return nil, err
}

var out []model.Finding
for _, ev := range events {
if ev.Kind == diff.EventFile {
continue
}
if ev.Kind != diff.EventAddedLine {
continue
}
if isExcludedFile(ev.File) {
continue
}

// Line length clamp (bytes). Deterministic.
s := ev.Text
if len(s) > 8192 {
s = s[:8192]
}

finds := rules.ApplyAll(s, ev.File, ev.DiffLine)
if len(finds) > 0 {
out = append(out, finds...)
}
}

// Defensive: ensure no nil findings slice
if out == nil {
return []model.Finding{}, nil
}
return out, nil
}