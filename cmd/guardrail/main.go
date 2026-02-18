package main

import (
"bufio"
"encoding/json"
"fmt"
"io"
"os"
"strings"
"time"

"guardrail-dev/secrets-guard/internal/detector"
"guardrail-dev/secrets-guard/internal/model"
)

func usage() {
fmt.Fprintln(os.Stderr, "Usage:")
fmt.Fprintln(os.Stderr, "  guardrail scan --stdin")
}

func main() {
args := os.Args[1:]
if len(args) == 0 {
usage()
os.Exit(3)
}

if args[0] != "scan" {
usage()
os.Exit(3)
}

useStdin := false
for _, a := range args[1:] {
if a == "--stdin" {
useStdin = true
}
}

if !useStdin {
fmt.Fprintln(os.Stderr, "ERROR: v1 requires --stdin (GitHub Action will provide diff via stdin).")
os.Exit(3)
}

diffText, err := readAll(os.Stdin)
if err != nil {
fmt.Fprintln(os.Stderr, "ERROR: failed to read stdin diff:", err.Error())
os.Exit(3)
}

findings, err := detector.ScanUnifiedDiff(diffText)
if err != nil {
fmt.Fprintln(os.Stderr, "ERROR: scan failed:", err.Error())
os.Exit(3)
}

// Human-readable
if len(findings) == 0 {
fmt.Println("OK: no secrets detected in added lines (diff-only).")
} else {
fmt.Printf("BLOCKED: %d secret finding(s) detected in added lines.\n", len(findings))
for _, f := range findings {
file := f.File
if file == "" {
file = "<unknown>"
}
line := "null"
if f.DiffLine != nil {
line = fmt.Sprintf("%d", *f.DiffLine)
}
fmt.Printf("- [%s] %s rule=%d file=%s line=%s match=%s\n", f.Severity, f.Type, f.RuleID, file, line, f.MaskedMatch)
}
}

// One-line JSON
out := detector.JSONReport{
Tool:          "secrets-guard",
Version:       "v1",
GeneratedUTC:  time.Now().UTC().Format(time.RFC3339),
FindingsCount: len(findings),
Findings:      findings,
}
b, _ := json.Marshal(out)
fmt.Println(string(b))

if len(findings) > 0 {
os.Exit(2)
}
os.Exit(0)
}

// satisfy unused import guard if future refactors happen
var _ = model.Finding{}

func readAll(r io.Reader) (string, error) {
var sb strings.Builder
br := bufio.NewReader(r)
buf := make([]byte, 32*1024)
for {
n, err := br.Read(buf)
if n > 0 {
sb.Write(buf[:n])
}
if err == io.EOF {
break
}
if err != nil {
return "", err
}
}
return sb.String(), nil
}