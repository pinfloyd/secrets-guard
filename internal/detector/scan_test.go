package detector

import "testing"

func TestScanFindsAWSAccessKeyInAddedLines(t *testing.T) {
diff := "" +
"diff --git a/app.env b/app.env\n" +
"index 1111111..2222222 100644\n" +
"--- a/app.env\n" +
"+++ b/app.env\n" +
"@@ -0,0 +1,2 @@\n" +
"+AWS_ACCESS_KEY_ID=AKIA1234567890ABCDEF\n" +
"+hello=world\n"

f, err := ScanUnifiedDiff(diff)
if err != nil {
t.Fatalf("err: %v", err)
}
if len(f) != 1 {
t.Fatalf("expected 1 finding, got %d", len(f))
}
if f[0].Type != "AWS_ACCESS_KEY_ID" || f[0].RuleID != 1 {
t.Fatalf("unexpected finding: %#v", f[0])
}
}

func TestScanIgnoresMarkdownFiles(t *testing.T) {
diff := "" +
"diff --git a/README.md b/README.md\n" +
"index 1111111..2222222 100644\n" +
"--- a/README.md\n" +
"+++ b/README.md\n" +
"@@ -0,0 +1,1 @@\n" +
"+stripe_key=sk_test_abcdefghijklmnopqrstuvwxyz0123456789\n"

f, err := ScanUnifiedDiff(diff)
if err != nil {
t.Fatalf("err: %v", err)
}
if len(f) != 0 {
t.Fatalf("expected 0 findings, got %d", len(f))
}
}