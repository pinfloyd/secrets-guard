package rules

import "math"

// ShannonEntropy computes Shannon entropy in bits per symbol for the input string.
func ShannonEntropy(s string) float64 {
if s == "" {
return 0
}
freq := make(map[rune]int, len(s))
for _, r := range s {
freq[r]++
}
n := float64(len([]rune(s)))
var ent float64
for _, c := range freq {
p := float64(c) / n
ent -= p * math.Log2(p)
}
return ent
}