FROM golang:1.22-alpine AS builder

WORKDIR /app

# Cache dependencies
COPY go.mod go.sum ./
RUN go mod download

# Build
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-s -w" -o /shakemeal ./cmd/server

# ── Final image ──────────────────────────────────────────────────────────────
FROM alpine:3.19

WORKDIR /app

RUN apk --no-cache add ca-certificates tzdata

COPY --from=builder /shakemeal .
COPY --from=builder /app/migrations ./migrations

EXPOSE 8080

ENTRYPOINT ["./shakemeal"]
