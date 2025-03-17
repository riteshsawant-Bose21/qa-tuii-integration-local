# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOMOD=$(GOCMD) mod
BINARY_NAME=fusion-server
MAIN_PATH=fusion/cmd/fusion
BUILD_DIR=build
BUILD_FLAGS=-tags netgo,osusergo
DEBUG_FLAGS=-gcflags "all=-N -l"

# Versioning
VERSION ?= 1.0.0-alpha.2
COMMIT := $(shell git rev-parse --short HEAD)
BUILD_TIME := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

# LDFLAGS to embed version info
LDFLAGS=-ldflags "-X main.Version=$(VERSION) -X main.Commit=$(COMMIT) -X main.BuildTime=$(BUILD_TIME)"

# Force disable buffering for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

all: deps build

build:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME) -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME) fusion-server

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
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_linux_amd64 fusion-server

build-linux-arm32:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_arm32 -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_linux_arm32 fusion-server

build-linux-arm64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_arm64 -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_linux_arm64 fusion-server

build-darwin-arm64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 $(GOBUILD) $(BUILD_FLAGS) $(DEBUG_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_darwin_arm64 -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_darwin_arm64 fusion-server

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
	@echo " all - Run deps and build"
	@echo " build - Build for current platform"
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

.PHONY: all build clean run deps tidy fmt vet lint build-linux-amd64 build-linux-arm32 build-linux-arm64 build-darwin-arm64 build-all help
