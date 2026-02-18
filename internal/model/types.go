package model

type Finding struct {
Type        string `json:"type"`
Severity    string `json:"severity"`
File        string `json:"file"`
DiffLine    *int   `json:"line"`
MaskedMatch string `json:"match"`
RuleID      int    `json:"rule_id"`
}