# OCALite Device Makefile
BUILD_DIR := build

# Detect platform for DNS-SD support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CXX := g++
    # macOS: Use native DNS-SD framework
    PKG_CFLAGS :=
    PKG_CDEFS  :=
    PKG_LIBS :=
    LDFLAGS :=
else ifeq ($(ARCH),arm64)
    PKG_LIBS   := -L ${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/lib
    PKG_CFLAGS := -I ${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/include
    PKG_CDEFS  := -DFUSION
    LDFLAGS    := -ldns_sd
else
    CXX=g++
    PKG_CFLAGS :=
    PKG_LIBS :=
    PKG_CDEFS  :=
    LDFLAGS := -ldns_sd
endif

CXXFLAGS := -Wall -Wextra -std=c++11 $(PKG_CFLAGS) \
	    $(PKG_CDEFS) \
	    -DOCA_RUN \
    -I../../common \
    -I../../common/HostInterfaceLite \
    -I../../common/OCALite \
    -I../../common/OCALite/OCC \
    -I../../common/OCALite/OCF \
    -I../../common/OCALite/OCP.1 \
    -I../../common/OCALite/Proxy

# App-specific source files (excluding AES67)
APP_SOURCES := $(wildcard *.cpp) \
               $(shell find HostInterface -name "*.cpp" | grep -v "AES67")

# Common source files (all from common directory, excluding AES67)
COMMON_SOURCES := $(shell find ../../common -name "*.cpp" | grep -v "AES67" | grep -v "OcaLiteMediaTransportNetworkAES67")

# All source files
ALL_SOURCES := $(APP_SOURCES) $(COMMON_SOURCES)

# Object files in build directory, preserving directory structure
APP_OBJECTS := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(APP_SOURCES))
COMMON_OBJECTS := $(patsubst ../../common/%.cpp,$(BUILD_DIR)/common/%.o,$(COMMON_SOURCES))
ALL_OBJECTS := $(APP_OBJECTS) $(COMMON_OBJECTS)

# Output executable
TARGET := ocalite

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS)
	$(CXX) $(ALL_OBJECTS) $(PKG_LIBS) -o $@ -lpthread -lc $(LDFLAGS)

# App source files
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Common source files  
$(BUILD_DIR)/common/%.o: ../../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
