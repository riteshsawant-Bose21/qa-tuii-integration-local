FROM golang:1.24 AS builder

WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 \
    go build -a -installsuffix cgo \
    -ldflags='-s -w' \
    -o lambda-authorizer ./cmd/lambda-authorizer

FROM public.ecr.aws/lambda/go:1

COPY --from=builder /app/lambda-authorizer ${LAMBDA_TASK_ROOT}

CMD ["lambda-authorizer"]