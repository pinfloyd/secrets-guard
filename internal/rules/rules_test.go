package rules

import "testing"

func TestRule2_AWSSecret_Positive(t *testing.T) {
line := "AWS_SECRET_ACCESS_KEY=abcdEFGHijklMNOPqrstUVWXyz0123456789ABCD" // 40 chars, allowed alphabet
dl := 1
f := ApplyAll(line, "app/config.env", &dl)

found := false
for _, x := range f {
if x.RuleID == 2 && x.Type == "AWS_SECRET_ACCESS_KEY" && x.Severity == "CRITICAL" {
found = true
break
}
}
if !found {
t.Fatalf("expected Rule 2 finding, got %#v", f)
}
}

func TestRule2_AWSSecret_Negative_No40Value(t *testing.T) {
line := "AWS_SECRET_ACCESS_KEY=too_short_value_123" // not 40 chars, must not match
dl := 1
f := ApplyAll(line, "app/config.env", &dl)

for _, x := range f {
if x.RuleID == 2 {
t.Fatalf("did not expect Rule 2 finding, got %#v", f)
}
}
}

func TestRule3_StripeLive_Positive(t *testing.T) {
line := "stripe=" + "sk_" + "live_" + "abcdefghijklmnopqrstuvwxyz0123456789ABCDEFGH" // >= 24 chars after prefix
dl := 1
f := ApplyAll(line, "app/payments.go", &dl)

found := false
for _, x := range f {
if x.RuleID == 3 && x.Type == "STRIPE_LIVE_SECRET_KEY" && x.Severity == "CRITICAL" {
found = true
break
}
}
if !found {
t.Fatalf("expected Rule 3 finding, got %#v", f)
}
}

func TestRule4_PrivateKeyHeader_Positive(t *testing.T) {
line := "-----BEGIN PRIVATE KEY-----"
dl := 1
f := ApplyAll(line, "keys/id_rsa", &dl)

found := false
for _, x := range f {
if x.RuleID == 4 && x.Type == "PRIVATE_KEY_BLOCK" && x.Severity == "CRITICAL" {
found = true
break
}
}
if !found {
t.Fatalf("expected Rule 4 finding, got %#v", f)
}
}

func TestRule5_HighEntropy_Positive(t *testing.T) {
// Must satisfy:
// - contains '=' or ':'
// - left side contains marker (within last 64 chars): token/api_key/password/etc.
// - right side len >= 32, allowed alphabet, >=3 classes, entropy >= 3.5
line := "api_key=Ab1_Cd2-Ef3+Gh4/Ij5=Kl6Mn7Op8Qr9St0Uv"
dl := 1
f := ApplyAll(line, "app/settings.yml", &dl)

found := false
for _, x := range f {
if x.RuleID == 5 && x.Type == "HIGH_ENTROPY_SECRET" && x.Severity == "HIGH" {
found = true
break
}
}
if !found {
t.Fatalf("expected Rule 5 finding, got %#v", f)
}
}

func TestRule5_HighEntropy_Negative_LowComplexity(t *testing.T) {
// len>=32 but only one class (lower), should not match
line := "password=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
dl := 1
f := ApplyAll(line, "app/settings.yml", &dl)

for _, x := range f {
if x.RuleID == 5 {
t.Fatalf("did not expect Rule 5 finding, got %#v", f)
}
}
}