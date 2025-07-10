CXXFLAGS ?= -Wall -Wextra -O2 --std=c++17

SRC_DIR := src
INCLUDE_DIR := include
EXTERNAL_INCLUDE_DIRS := external/include external/include/nlohmann
BUILD_DIR := build
TARGET := $(BUILD_DIR)/fusion-edge-gateway
DEBUG_FILE := $(TARGET).debug

SOURCES := $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(SOURCES))

INCLUDES := -I$(INCLUDE_DIR) $(foreach dir,$(EXTERNAL_INCLUDE_DIRS),-I$(dir))

# Detect if SDK environment is sourced
ifdef SDKTARGETSYSROOT
    SYSROOT := $(SDKTARGETSYSROOT)
    CROSS_COMPILE ?= $(CROSS_COMPILE)
    CXX := $(CROSS_COMPILE)g++
    CC := $(CROSS_COMPILE)gcc
    OBJCOPY := $(CROSS_COMPILE)objcopy
    STRIP := $(CROSS_COMPILE)strip
    CXXFLAGS += --sysroot="$(SYSROOT)" -I"$(SYSROOT)/usr/include"
    LDFLAGS += --sysroot="$(SYSROOT)" -L"$(SYSROOT)/usr/lib" -lcurl
else
    OBJCOPY := objcopy
    STRIP := strip
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

release: clean
	$(MAKE) -j$(PARALLEL_MAKE) all \
		CXXFLAGS='$(CXXFLAGS) -g -O2 -DNDEBUG -DSPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_DEBUG' \
		LDFLAGS='$(LDFLAGS)'
	@echo "→ Extracting debug info to $(DEBUG_FILE)"
	$(OBJCOPY) --only-keep-debug $(TARGET) $(DEBUG_FILE)
	@echo "→ Stripping binary to reduce size"
	$(STRIP) --strip-debug --strip-unneeded $(TARGET)
	$(OBJCOPY) --add-gnu-debuglink=$(DEBUG_FILE) $(TARGET)

local: clean
	$(MAKE) -j$(PARALLEL_MAKE) CXX=g++ CXXFLAGS="-Wall -Wextra -O2 --std=c++17 -g -DSPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_DEBUG" LDFLAGS="-lcurl" EXE_EXT="" all

clean:
	rm -rf $(BUILD_DIR)

strip:
	-$(CROSS_COMPILE)strip $(TARGET) || true

.PHONY: all clean strip release local debug
