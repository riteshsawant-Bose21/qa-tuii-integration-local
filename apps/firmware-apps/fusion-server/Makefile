# Go parameters
GOCMD=go
GOBUILD=$(GOCMD) build
GOCLEAN=$(GOCMD) clean
GOTEST=$(GOCMD) test
GOMOD=$(GOCMD) mod
BINARY_NAME=fusion-gossip

all: deps test build

build:
	$(GOBUILD) -o $(BINARY_NAME) -v

test:
	$(GOTEST) -v ./...

clean:
	$(GOCLEAN)
	rm -f $(BINARY_NAME)

run:
	$(GOBUILD) -o $(BINARY_NAME) -v
	./$(BINARY_NAME)

deps:
	$(GOMOD) download
	$(GOMOD) verify

tidy:
	$(GOMOD) tidy

# Cross compilation
build-linux:
	CGO_ENABLED=0 GOOS=linux GOARCH=amd64 $(GOBUILD) -o $(BINARY_NAME)_linux_amd64 -v

build-linux-arm32:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm GOARM=7 $(GOBUILD) -o $(BINARY_NAME)_linux_arm32 -v

build-linux-arm64:
	CGO_ENABLED=0 GOOS=linux GOARCH=arm64 $(GOBUILD) -o $(BINARY_NAME)_linux_arm64 -v

.PHONY: all build test clean run deps tidy build-linux build-linux-arm32 build-linux-arm64