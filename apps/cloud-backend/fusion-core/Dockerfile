# Build stage
FROM golang:1.24.4-alpine AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /workspace

COPY go.mod go.sum ./

RUN go mod download
RUN go install github.com/swaggo/swag/cmd/swag@latest

COPY . .

RUN swag init -g cmd/api/main.go
RUN CGO_ENABLED=0 go build -ldflags='-w -s' -o fusion-web-services cmd/api/main.go

# Runtime stage
FROM alpine:3.19

RUN apk --no-cache add ca-certificates && \
    addgroup -S appgroup && \
    adduser -S appuser -G appgroup

WORKDIR /app

COPY --from=builder --chown=appuser:appgroup /workspace/fusion-web-services .

USER appuser

EXPOSE 8080

ENV GIN_MODE=release

ENTRYPOINT ["./fusion-web-services"]
