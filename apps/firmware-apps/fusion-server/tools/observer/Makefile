# Detect operating system
UNAME_S := $(shell uname -s)

# Compiler settings
CXX_X86 := g++
CXX_ARM := aarch64-linux-gnu-g++


# OSX-specific settings
ifeq ($(UNAME_S),Darwin)
    CXX_X86 := clang++
    CXX_ARM := clang++
    # Use proper flags for OSX ARM64 (Apple Silicon)
    OSX_ARM_FLAGS := -target arm64-apple-darwin
    OSX_X86_FLAGS := -target x86_64-apple-darwin
	# Framework and library paths for OSX
    OSX_INCLUDES := -I/usr/local/include -I/opt/homebrew/include
    OSX_LIB_PATHS := -L/usr/local/lib -L/opt/homebrew/lib
else
	LINUX_INCLUDES := -I/usr/include -I/usr/include/jsoncpp	
endif

# Common compiler flags
CXXFLAGS := -std=c++17 -Wall -Wextra -pthread

# Build type (debug/release)
BUILD_TYPE ?= release

ifeq ($(BUILD_TYPE),debug)
    CXXFLAGS += -g -O0 -DDEBUG
else
    CXXFLAGS += -O2 -DNDEBUG
endif

# Directories
SRC_DIR := .
BUILD_DIR := build
BUILD_DIR_X86 := $(BUILD_DIR)/x86_64
BUILD_DIR_ARM := $(BUILD_DIR)/arm64
BUILD_DIR_OSX_X86 := $(BUILD_DIR)/osx-x86_64
BUILD_DIR_OSX_ARM := $(BUILD_DIR)/osx-arm64

# Source files
SRCS := $(wildcard $(SRC_DIR)/*.cpp)
OBJS_X86 := $(SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_X86)/%.o)
OBJS_ARM := $(SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_ARM)/%.o)
OBJS_OSX_X86 := $(SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_OSX_X86)/%.o)
OBJS_OSX_ARM := $(SRCS:$(SRC_DIR)/%.cpp=$(BUILD_DIR_OSX_ARM)/%.o)

# Library dependencies
LIBS := -ljsoncpp
INCLUDES := -I$(SRC_DIR)

# Target executables
TARGET_X86 := $(BUILD_DIR_X86)/observer
TARGET_ARM := $(BUILD_DIR_ARM)/observer
TARGET_OSX_X86 := $(BUILD_DIR_OSX_X86)/observer
TARGET_OSX_ARM := $(BUILD_DIR_OSX_ARM)/observer

# Default target depends on OS
ifeq ($(UNAME_S),Darwin)
    all: osx
else
    all: linux
endif

# Linux builds
linux: x86_64 arm64

# OSX builds
osx: osx-x86_64 osx-arm64

# Universal binary for OSX (combines ARM64 and x86_64)
osx-universal: osx
	@mkdir -p $(BUILD_DIR)
	lipo -create -output $(BUILD_DIR)/observer-universal \
		$(TARGET_OSX_X86) $(TARGET_OSX_ARM)

# x86_64 Linux build
x86_64: $(TARGET_X86)

$(TARGET_X86): $(OBJS_X86)
	@mkdir -p $(dir $@)
	$(CXX_X86) $(OBJS_X86) -o $(TARGET_X86) $(LIBS)

$(BUILD_DIR_X86)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX_X86) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

# ARM64 Linux build
arm64: $(TARGET_ARM)

$(TARGET_ARM): $(OBJS_ARM)
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(OBJS_ARM) -o $(TARGET_ARM) $(LIBS)

$(BUILD_DIR_ARM)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(CXXFLAGS) $(INCLUDES) $(LINUX_INCLUDES) -c $< -o $@

# OSX x86_64 build
osx-x86_64: $(TARGET_OSX_X86)

$(TARGET_OSX_X86): $(OBJS_OSX_X86)
	@mkdir -p $(dir $@)
	$(CXX_X86) $(OSX_X86_FLAGS) $(OBJS_OSX_X86) -o $(TARGET_OSX_X86) \
		$(OSX_LIB_PATHS) $(LIBS)

$(BUILD_DIR_OSX_X86)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX_X86) $(CXXFLAGS) $(OSX_X86_FLAGS) $(INCLUDES) $(OSX_INCLUDES) -c $< -o $@

# OSX ARM64 build
osx-arm64: $(TARGET_OSX_ARM)

$(TARGET_OSX_ARM): $(OBJS_OSX_ARM)
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(OSX_ARM_FLAGS) $(OBJS_OSX_ARM) -o $(TARGET_OSX_ARM) \
		$(OSX_LIB_PATHS) $(LIBS)

$(BUILD_DIR_OSX_ARM)/%.o: $(SRC_DIR)/%.cpp
	@mkdir -p $(dir $@)
	$(CXX_ARM) $(CXXFLAGS) $(OSX_ARM_FLAGS) $(INCLUDES) $(OSX_INCLUDES) -c $< -o $@

# Clean build directories
clean:
	rm -rf $(BUILD_DIR)

# Install ARM64 cross-compiler tools (Ubuntu/Debian)
install-arm-toolchain:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		sudo apt-get update && \
		sudo apt-get install -y g++-aarch64-linux-gnu; \
	else \
		echo "ARM toolchain installation only needed on Linux"; \
	fi

# Install dependencies
install-deps:
	@if [ "$(UNAME_S)" = "Linux" ]; then \
		sudo apt-get update && \
		sudo apt-get install -y libjsoncpp-dev; \
	elif [ "$(UNAME_S)" = "Darwin" ]; then \
		brew install jsoncpp; \
	fi

.PHONY: all linux osx osx-universal x86_64 arm64 osx-x86_64 osx-arm64 clean install-arm-toolchain install-deps

# Help target
help:
	@echo "Available targets:"
	@echo "  all               - Build default targets for current OS"
	@echo "  linux            - Build both Linux x86_64 and ARM64 versions"
	@echo "  osx              - Build both OSX x86_64 and ARM64 versions"
	@echo "  osx-universal    - Build universal binary for OSX (x86_64 + ARM64)"
	@echo "  x86_64           - Build Linux x86_64 version"
	@echo "  arm64            - Build Linux ARM64 version"
	@echo "  osx-x86_64       - Build OSX x86_64 version"
	@echo "  osx-arm64        - Build OSX ARM64 version"
	@echo "  clean            - Remove build directory"
	@echo "  install-deps     - Install required libraries"
	@echo "  install-arm-toolchain - Install ARM64 cross-compiler (Linux only)"
	@echo ""
	@echo "Build configuration:"
	@echo "  BUILD_TYPE=debug|release (current: $(BUILD_TYPE))"
	@echo "  Current OS: $(UNAME_S)"
