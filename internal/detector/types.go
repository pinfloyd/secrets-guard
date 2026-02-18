package detector

import "guardrail-dev/secrets-guard/internal/model"

type JSONReport struct {
Tool          string          `json:"tool"`
Version       string          `json:"version"`
GeneratedUTC  string          `json:"generated_utc"`
FindingsCount int             `json:"findings_count"`
Findings      []model.Finding `json:"findings"`
}