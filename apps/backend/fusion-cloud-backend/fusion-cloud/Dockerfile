# syntax=docker/dockerfile:1

FROM golang:1.24.3-bookworm AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y gcc libc6-dev

ENV CGO_ENABLED=1
ENV GO111MODULE=on

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN mkdir -p /app/db

# Build API binary
RUN go build -o main ./cmd/server

# Build migration binary
RUN go build -o main-migrate ./cmd/migrate

# --- Final Image ---
FROM debian:bookworm-slim

WORKDIR /app

RUN apt-get update && apt-get install -y ca-certificates libc6 && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/main .
COPY --from=builder /app/main-migrate .
COPY --from=builder /app/db /app/db

EXPOSE ${PORT}

CMD ["./main"]
