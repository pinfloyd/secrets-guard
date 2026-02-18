package diff

import (
"fmt"
"strings"
)

type EventKind int

const (
EventFile EventKind = iota
EventAddedLine
EventOther
)

type Event struct {
Kind     EventKind
File     string
Text     string
DiffLine *int
}

// ParseUnified extracts current file from "+++ b/<path>" and yields added lines starting with "+".
// It ignores "+++" headers and other diff metadata.
// DiffLine is a best-effort counter of added-line sequence within the file (not absolute file line).
func ParseUnified(unified string) ([]Event, error) {
lines := strings.Split(unified, "\n")
var out []Event

currentFile := ""
addCounter := 0

for _, raw := range lines {
// file header line
if strings.HasPrefix(raw, "+++ ") {
// expected: "+++ b/path"
parts := strings.SplitN(raw, " ", 2)
if len(parts) != 2 {
continue
}
p := strings.TrimSpace(parts[1])
if strings.HasPrefix(p, "b/") {
currentFile = strings.TrimPrefix(p, "b/")
} else if p == "/dev/null" {
currentFile = ""
} else {
currentFile = p
}
addCounter = 0
out = append(out, Event{Kind: EventFile, File: currentFile})
continue
}

// Ignore diff hunk headers, etc.
if strings.HasPrefix(raw, "@@") || strings.HasPrefix(raw, "diff ") || strings.HasPrefix(raw, "--- ") || strings.HasPrefix(raw, "index ") {
continue
}

// added line (but not +++ header, which we handled)
if strings.HasPrefix(raw, "+") {
// ignore "+++" which would have been caught above, but keep safe
if strings.HasPrefix(raw, "+++") {
continue
}
addCounter++
n := addCounter
text := strings.TrimPrefix(raw, "+")
out = append(out, Event{
Kind:     EventAddedLine,
File:     currentFile,
Text:     text,
DiffLine: &n,
})
continue
}

// Everything else ignored
}

// Basic sanity: no parsing error expected
if out == nil {
return nil, fmt.Errorf("parse failed")
}
return out, nil
}