# ---- Build stage ----
FROM golang:1.22-alpine AS builder
WORKDIR /src
COPY go.mod go.sum* ./
RUN go mod download || true
COPY . .
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags="-s -w" -o /out/guardrail ./cmd/guardrail

# ---- Runtime stage ----
FROM alpine:3.20
WORKDIR /work

# git is required to compute diff in CI workspace
RUN apk add --no-cache git ca-certificates

COPY --from=builder /out/guardrail /usr/local/bin/guardrail
COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh /usr/local/bin/guardrail

ENTRYPOINT ["/entrypoint.sh"]