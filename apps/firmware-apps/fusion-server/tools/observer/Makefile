# Detect operating system
UNAME_S := $(shell uname -s)

# ================================
# Compiler settings
# ================================
CXX            := g++
CXX_CLANG      := clang++
CXX_X86        := g++
CXX_ARM        := aarch64-linux-gnu-g++

# Common compiler flags
CXXFLAGS := -std=c++17 -Wall -Wextra -pthread

# Build type (debug/release)
BUILD_TYPE ?= release
ifeq ($(BUILD_TYPE),debug)
    CXXFLAGS += -g -O0 -DDEBUG
else
    CXXFLAGS += -O2 -DNDEBUG
endif

# ================================
# macOS (Apple Silicon only)
# ================================
ifeq ($(UNAME_S),Darwin)
    # Single-arch macOS (arm64 only)
    CXX            := $(CXX_CLANG)
    OSX_ARM_FLAGS  := -target arm64-apple-darwin

    # Homebrew (arm64) paths
    OSX_ARM_INCLUDES  := -I/opt/homebrew/include
    OSX_ARM_LIB_PATHS := -L/opt/homebrew/lib

	# Homebrew googletest paths (used for tests)
	OSX_ARM_GTEST_PREFIX  := /opt/homebrew/opt/googletest
	OSX_ARM_GTEST_CFLAGS  := -I$(OSX_ARM_GTEST_PREFIX)/include
	OSX_ARM_GTEST_LDFLAGS := -L$(OSX_ARM_GTEST_PREFIX)/lib

    # Prefer pkg-config for jsoncpp on arm64 brew
    PKGCONF_ARM := pkg-config
    OSX_ARM_JSONCPP_LIBS    := $(shell $(PKGCONF_ARM) --libs jsoncpp 2>/dev/null || echo -ljsoncpp)
    OSX_ARM_JSONCPP_CFLAGS  := $(shell $(PKGCONF_ARM) --cflags jsoncpp 2>/dev/null)

    # No x86_64 or universal builds on macOS
endif

# ================================
# Linux
# ================================
ifeq ($(UNAME_S),Linux)
    LINUX_INCLUDES := -I/usr/include -I/usr/include/jsoncpp
endif

# ================================
# Directories
# ================================
SRC_DIR := .
BUILD_DIR := build
BUILD_DIR_X86 := $(BUILD_DIR)/x86_64
BUILD_DIR_ARM := $(BUILD_DIR)/arm64
BUILD_DIR_OSX_ARM := $(BUILD_DIR)/osx-arm64

# Sources
MAIN_SRCS := observer.cpp
INCLUDES  := -I$(SRC_DIR)
COMMON_HEADERS := $(SRC_DIR)/observer.h

# Objects
OBJS_X86      := $(MAIN_SRCS:%.cpp=$(BUILD_DIR_X86)/%.o)
OBJS_ARM      := $(MAIN_SRCS:%.cpp=$(BUILD_DIR_ARM)/%.o)
OBJS_OSX_ARM  := $(MAIN_SRCS:%.cpp=$(BUILD_DIR_OSX_ARM)/%.o)

# Targets
TARGET_X86     := $(BUILD_DIR_X86)/observer
TARGET_ARM     := $(BUILD_DIR_ARM)/observer
TARGET_OSX_ARM := $(BUILD_DIR_OSX_ARM)/observer

# Libraries
LINUX_LIBS := -ljsoncpp
TEST_LIBS  := -lgtest -lgtest_main

# Tests
TEST_SRCS := $(wildcard $(SRC_DIR)/*_test.cpp)
TEST_OBJS_X86     := $(TEST_SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_X86)/%.o)
TEST_OBJS_ARM     := $(TEST_SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_ARM)/%.o)
TEST_OBJS_OSX_ARM := $(TEST_SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_OSX_ARM)/%.o)

TEST_TARGET_X86     := $(BUILD_DIR_X86)/observer_test
TEST_TARGET_ARM     := $(BUILD_DIR_ARM)/observer_test
TEST_TARGET_OSX_ARM := $(BUILD_DIR_OSX_ARM)/observer_test

# ================================
# Default target by OS
# ================================
ifeq ($(UNAME_S),Darwin)
    all: osx-arm64
else
    all: linux
endif

# ================================
# Linux builds
# ================================
linux: x86_64 arm64

x86_64: $(TARGET_X86)
$(TARGET_X86): $(OBJS_X86)
	@mkdir -p $(dir $@)
	$(CXX_X86) $(OBJS_X86) -o $@ $(LINUX_LIBS)

$(BUILD_DIR_X86)/%.o: $(SRC_DIR)/%.cpp $(COMMON_HEADERS)
	@mkdir -p $(dir $@)
	$(CXX_X86) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

arm64: $(TARGET_ARM)
$(TARGET_ARM): $(OBJS_ARM)
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(OBJS_ARM) -o $@ $(LINUX_LIBS)

$(BUILD_DIR_ARM)/%.o: $(SRC_DIR)/%.cpp $(COMMON_HEADERS)
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(CXXFLAGS) $(INCLUDES) $(LINUX_INCLUDES) -c $< -o $@

# ================================
# macOS (Apple Silicon only)
# ================================
osx-arm64: $(TARGET_OSX_ARM)

$(TARGET_OSX_ARM): $(OBJS_OSX_ARM)
	@mkdir -p $(dir $@)
	$(CXX) $(OSX_ARM_FLAGS) $(OBJS_OSX_ARM) -o $@ \
		$(OSX_ARM_LIB_PATHS) $(OSX_ARM_JSONCPP_LIBS) -lfmt

$(BUILD_DIR_OSX_ARM)/%.o: $(SRC_DIR)/%.cpp $(COMMON_HEADERS)
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) $(OSX_ARM_FLAGS) $(INCLUDES) \
		$(OSX_ARM_INCLUDES) $(OSX_ARM_JSONCPP_CFLAGS) $(OSX_ARM_GTEST_CFLAGS) -c $< -o $@

# ================================
# Tests
# ================================
test: test-$(shell uname -s | tr A-Z a-z)

test-linux: test-x86_64 test-arm64
test-darwin: test-osx-arm64

test-x86_64: $(TEST_TARGET_X86)
	./$(TEST_TARGET_X86)

test-arm64: $(TEST_TARGET_ARM)
	./$(TEST_TARGET_ARM)

test-osx-arm64: $(TEST_TARGET_OSX_ARM)
	./$(TEST_TARGET_OSX_ARM)

$(TEST_TARGET_X86): $(TEST_OBJS_X86)
	@mkdir -p $(dir $@)
	$(CXX_X86) $(TEST_OBJS_X86) -o $@ $(LINUX_LIBS) $(TEST_LIBS)

$(TEST_TARGET_ARM): $(TEST_OBJS_ARM)
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(TEST_OBJS_ARM) -o $@ $(LINUX_LIBS) $(TEST_LIBS)

$(TEST_TARGET_OSX_ARM): $(TEST_OBJS_OSX_ARM)
	@mkdir -p $(dir $@)
	$(CXX) $(OSX_ARM_FLAGS) $(TEST_OBJS_OSX_ARM) -o $@ \
		$(OSX_ARM_LIB_PATHS) $(OSX_ARM_JSONCPP_LIBS) $(OSX_ARM_GTEST_LDFLAGS) -lfmt $(TEST_LIBS)

# ================================
# Utilities
# ================================
clean:
	rm -rf $(BUILD_DIR)

install-arm-toolchain:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		sudo apt-get update && \
		sudo apt-get install -y g++-aarch64-linux-gnu; \
	else \
		echo "ARM toolchain installation only needed on Linux"; \
	fi

install-deps:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		sudo apt-get update && \
		sudo apt-get install -y libjsoncpp-dev libgtest-dev; \
	elif [ "$(UNAME_S)" = "Darwin" ]; then \
		brew install jsoncpp googletest pkg-config; \
	fi

.PHONY: all linux x86_64 arm64 osx-arm64 clean install-arm-toolchain install-deps \
        test test-linux test-darwin test-x86_64 test-arm64 test-osx-arm64

help:
	@echo "Targets:"
	@echo "  all                - Build default for current OS"
	@echo "  linux              - Build Linux x86_64 and ARM64"
	@echo "  osx-arm64          - Build macOS (Apple Silicon) only"
	@echo "  clean              - Remove build directory"
	@echo "  install-deps       - Install required libraries"
	@echo "  install-arm-toolchain - Install ARM64 cross-compiler (Linux only)"
	@echo ""
	@echo "Build configuration:"
	@echo "  BUILD_TYPE=debug|release (current: $(BUILD_TYPE))"
	@echo "  Current OS: $(UNAME_S)"
	@echo ""
	@echo "Tests:"
	@echo "  test               - Run tests for current platform"
	@echo "  test-linux         - Run Linux tests (x86_64 and ARM64)"
	@echo "  test-darwin        - Run macOS tests (arm64 only)"

	
