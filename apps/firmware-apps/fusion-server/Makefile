# Go parameters
GOCMD="/c/Program\ Files/Go/bin/go.exe"
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod
BINARY_NAME=fusion-server
MAIN_PATH=fusion/cmd/fusion
BUILD_DIR=build
BUILD_FLAGS=-tags netgo,osusergo
LDFLAGS=-ldflags '-extldflags "-static"'

# Force disable buffering for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

all: deps test build

build:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME) -v ./cmd/fusion
	
clean:
	$(GOCLEAN)
	rm -rf $(BUILD_DIR)

run:
	cd fusion && CGO_ENABLED=0 GOOS=linux $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME) -v ./cmd/fusion
	./$(BUILD_DIR)/$(BINARY_NAME)

deps:
	cd fusion && $(GOMOD) download
	cd fusion && $(GOMOD) verify

tidy:
	cd fusion && $(GOMOD) tidy

# Cross compilation
build-linux-amd64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_amd64 -v ./cmd/fusion

build-linux-arm32:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_arm32 -v ./cmd/fusion

build-linux-arm64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_arm64 -v ./cmd/fusion

build-darwin-arm64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=darwin GOARCH=arm64 $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_darwin_arm64 -v ./cmd/fusion

# Development helpers
fmt:
	cd fusion && go fmt ./...

vet:
	cd fusion && go vet ./...

lint:
	cd fusion && golangci-lint run

# Build all platforms
build-all: build-linux-amd64 build-linux-arm32 build-linux-arm64 build-darwin-arm64

# Show help
help:
	@echo "Make targets:"
	@echo " all - Run deps, test, and build"
	@echo " build - Build for current platform"
	@echo " test - Run tests"
	@echo " test-verbose - Run tests with verbose output and no caching"
	@echo " clean - Clean build files"
	@echo " run - Build and run locally"
	@echo " deps - Download dependencies"
	@echo " tidy - Tidy go.mod"
	@echo " fmt - Format code"
	@echo " vet - Run go vet"
	@echo " lint - Run linter"
	@echo " build-linux-amd64 - Build for Linux amd64"
	@echo " build-linux-arm32 - Build for Linux ARM32"
	@echo " build-linux-arm64 - Build for Linux ARM64"
	@echo " build-darwin-arm64 - Build for macOS ARM64"
	@echo " build-all - Build for all platforms"

.PHONY: all build clean run deps tidy fmt vet lint build-linux-amd64 build-linux-arm32 build-linux-arm64 build-darwin-arm64 build-all help test-verbose
	
