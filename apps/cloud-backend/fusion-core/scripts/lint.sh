#!/bin/bash

# Check if golangci-lint is installed, if not use go run
if command -v golangci-lint &> /dev/null; then
    golangci-lint run ./...
else
    echo "golangci-lint not found locally, using go run..."
    go run github.com/golangci/golangci-lint/cmd/golangci-lint@latest run ./...
fi