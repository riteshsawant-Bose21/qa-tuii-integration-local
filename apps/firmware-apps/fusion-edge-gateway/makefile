CXXFLAGS ?= -Wall -Wextra -O2 --std=c++17

SRC_DIR := src
INCLUDE_DIR := include
EXTERNAL_INCLUDE_DIRS := external/include external/include/nlohmann
BUILD_DIR := build
TARGET := $(BUILD_DIR)/fusion-edge-gateway

SOURCES := $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(SOURCES))

INCLUDES := -I$(INCLUDE_DIR) $(foreach dir,$(EXTERNAL_INCLUDE_DIRS),-I$(dir))

# Detect if SDK environment is sourced
ifdef SDKTARGETSYSROOT
    # Cross-compilation
    SYSROOT := $(SDKTARGETSYSROOT)
    CROSS_COMPILE ?= $(CROSS_COMPILE)
    CXX := $(CROSS_COMPILE)g++
    CC := $(CROSS_COMPILE)gcc
    CXXFLAGS += --sysroot="$(SYSROOT)" -I"$(SYSROOT)/usr/include"
    LDFLAGS += --sysroot="$(SYSROOT)" -L"$(SYSROOT)/usr/lib" -lcurl
endif

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

debug: clean
	$(MAKE) -j$(shell nproc) CXXFLAGS="$(CXXFLAGS) -g -O0 -DDEBUG" LDFLAGS="$(LDFLAGS)" all

release: clean
	$(MAKE) -j$(shell nproc) CXXFLAGS="$(CXXFLAGS) -g0 -O2 -DNDEBUG" LDFLAGS="$(LDFLAGS)" all
	-$(CROSS_COMPILE)strip $(TARGET) || true

local: clean
	$(MAKE) -j$(shell nproc) CXX=g++ CXXFLAGS="-Wall -Wextra -O2 --std=c++17 -g" LDFLAGS="-lcurl" EXE_EXT="" all

clean:
	rm -rf $(BUILD_DIR)

strip:
	-$(CROSS_COMPILE)strip $(TARGET) || true

.PHONY: all clean strip release local debug
