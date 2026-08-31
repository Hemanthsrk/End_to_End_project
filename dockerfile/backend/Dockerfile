
# =========================
# Stage 1: Build Go App
# =========================
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install certificates and git
RUN apk add --no-cache git ca-certificates

# Copy Go dependency files
COPY backend/go.mod backend/go.sum ./

# Download dependencies
RUN go mod download

# Copy backend source
COPY backend/ ./

# Build static binary
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -o server main.go


# =========================
# Stage 2: Runtime
# =========================
FROM alpine:3.22

WORKDIR /app

# Install CA certificates
RUN apk add --no-cache ca-certificates

# Copy compiled binary
COPY --from=builder /app/server .

# Backend port
EXPOSE 8080

# Start application
CMD ["./server"]
