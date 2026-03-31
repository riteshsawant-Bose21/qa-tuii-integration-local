# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOMOD=$(GOCMD) mod
BINARY_NAME=fusion-server
MAIN_PATH=fusion/cmd/fusion
BUILD_DIR=build
BUILD_FLAGS=-tags netgo,osusergo
RELEASE_FLAGS=-trimpath
DEBUG_FLAGS=-gcflags "all=-N -l"
PROTOC ?= protoc
PROTO_SRC_DIR=../../../libs/proto
PROTO_GO_OUT=fusion/internal/gen/proto
PROTO_FILES=$(PROTO_SRC_DIR)/fusion/device_config.proto $(PROTO_SRC_DIR)/fusion/tasks.proto $(PROTO_SRC_DIR)/fusion/snapshots.proto $(PROTO_SRC_DIR)/fusion/devices.proto

# Versioning
VERSION ?= 1.0.0-proto.2
COMMIT := $(shell git rev-parse --short HEAD)
BUILD_TIME := $(shell date -u +%Y-%m-%dT%H:%M:%SZ)

# LDFLAGS to embed version info
BASE_LDFLAGS=-X fusion/internal/version.Version=$(VERSION) -X fusion/internal/version.Commit=$(COMMIT) -X fusion/internal/version.BuildTime=$(BUILD_TIME)
LDFLAGS=-ldflags "$(BASE_LDFLAGS)"
RELEASE_LDFLAGS=-ldflags "$(BASE_LDFLAGS) -s -w"

# Force disable buffering for all commands
SHELL := /bin/bash
.SHELLFLAGS := -ec

all: deps build

build:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux $(GOBUILD) $(BUILD_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME) -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME) fusion-server

debug:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux $(GOBUILD) $(BUILD_FLAGS) $(DEBUG_FLAGS) $(LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)-debug -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)-debug fusion-server

release:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux $(GOBUILD) $(BUILD_FLAGS) $(RELEASE_FLAGS) $(RELEASE_LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)-release -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)-release fusion-server

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

proto:
	mkdir -p $(PROTO_GO_OUT)
	$(PROTOC) \
		-I $(PROTO_SRC_DIR) \
		--go_out=$(PROTO_GO_OUT) \
		--go_opt=paths=source_relative \
		$(PROTO_FILES)

proto-clean:
	rm -f $(PROTO_GO_OUT)/fusion/device_config.pb.go
	rm -f $(PROTO_GO_OUT)/fusion/tasks.pb.go
	rm -f $(PROTO_GO_OUT)/fusion/snapshots.pb.go
	rm -f $(PROTO_GO_OUT)/fusion/devices.pb.go

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

release-linux-amd64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) $(BUILD_FLAGS) $(RELEASE_FLAGS) $(RELEASE_LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_amd64 -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_linux_amd64 fusion-server

release-linux-arm32:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 $(GOBUILD) $(BUILD_FLAGS) $(RELEASE_FLAGS) $(RELEASE_LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_arm32 -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_linux_arm32 fusion-server

release-linux-arm64:
	mkdir -p $(BUILD_DIR)
	cd fusion && CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) $(BUILD_FLAGS) $(RELEASE_FLAGS) $(RELEASE_LDFLAGS) -o ../$(BUILD_DIR)/$(BINARY_NAME)_linux_arm64 -v ./cmd/fusion
	cd $(BUILD_DIR) && ln -sf $(BINARY_NAME)_linux_arm64 fusion-server

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
	@echo " debug - Build an unoptimized Linux binary with debug symbols"
	@echo " release - Build an optimized Linux binary with reduced binary size"
	@echo " clean - Clean build files"
	@echo " run - Build and run locally"
	@echo " deps - Download dependencies"
	@echo " tidy - Tidy go.mod"
	@echo " proto - Generate Go protobuf types from shared proto definitions"
	@echo " proto-clean - Remove generated Go protobuf types"
	@echo " fmt - Format code"
	@echo " vet - Run go vet"
	@echo " lint - Run linter"
	@echo " build-linux-amd64 - Build for Linux amd64"
	@echo " build-linux-arm32 - Build for Linux ARM32"
	@echo " build-linux-arm64 - Build for Linux ARM64"
	@echo " build-darwin-arm64 - Build for macOS ARM64"
	@echo " release-linux-amd64 - Build optimized release binary for Linux amd64"
	@echo " release-linux-arm32 - Build optimized release binary for Linux ARM32"
	@echo " release-linux-arm64 - Build optimized release binary for Linux ARM64"
	@echo " build-all - Build for all platforms"

.PHONY: all build debug release clean run deps tidy fmt vet lint build-linux-amd64 build-linux-arm32 build-linux-arm64 build-darwin-arm64 release-linux-amd64 release-linux-arm32 release-linux-arm64 build-all help
