# Stage 1 Builder
################

FROM golang:1.24-alpine AS builder

RUN apk add --no-cache ca-certificates

WORKDIR /app

COPY . .

RUN go mod download

RUN CGO_ENABLED=0 GOOS=linux GOARCH=arm64 go build -tags lambda.norpc -ldflags="-s -w" -trimpath -o bootstrap ./cmd/sync/main.go

# Stage 2: Runtime
##################
FROM --platform=linux/arm64 public.ecr.aws/lambda/provided:al2023-arm64

COPY --from=builder /app/bootstrap ${LAMBDA_RUNTIME_DIR}/bootstrap
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

CMD ["bootstrap"]