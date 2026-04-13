.PHONY: test lint build clean coverage

# Default target
all: lint test build

# Run tests
test:
	@echo "Running all tests..."
	go test ./... -v -timeout=30s

# Run tests with coverage
coverage:
	@echo "Running tests with coverage..."
	go test ./... -v -timeout=30s -coverprofile=coverage.out
	@echo "Coverage report:"
	go tool cover -func=coverage.out | grep total

# Run integration tests
test-integration:
	@echo "Running integration tests..."
	go test ./internal/tests/... -v -timeout=60s

# Run linting
lint:
	@echo "Running linting..."
	golangci-lint run

# Build the application
build:
	@echo "Building application..."
	go build -o fusion-core ./cmd/api

# Clean build artifacts
clean:
	@echo "Cleaning up..."
	rm -f fusion-core coverage.out