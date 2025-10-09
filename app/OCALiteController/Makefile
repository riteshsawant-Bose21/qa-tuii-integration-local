# OCALiteController Makefile
BUILD_DIR := build

# Detect platform for DNS-SD support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    CXX=g++
    # macOS: Use native DNS-SD framework
    PKG_CFLAGS :=
    PKG_LIBS := -framework CoreServices
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

# ================================
# Cross-platform jsoncpp support
# ================================
ifeq ($(UNAME_S),Darwin)
    # macOS: Prefer pkg-config, fallback to Homebrew paths
    PKGCONF := pkg-config
    JSONCPP_LIBS := $(shell $(PKGCONF) --libs jsoncpp 2>/dev/null || echo "-L/opt/homebrew/lib -ljsoncpp")
    JSONCPP_CFLAGS := $(shell $(PKGCONF) --cflags jsoncpp 2>/dev/null || echo "-I/opt/homebrew/include")
else ifeq ($(ARCH),arm64)
    # Cross-compile ARM64: Use SDK paths if available, otherwise standard Linux
    ifneq ($(SDK_DIR),)
        JSONCPP_LIBS := -ljsoncpp
        JSONCPP_CFLAGS := -I${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/include/jsoncpp
    else
        JSONCPP_LIBS := -ljsoncpp
        JSONCPP_CFLAGS := -I/usr/include/jsoncpp
    endif
else
    # Linux: Standard system paths
    JSONCPP_LIBS := -ljsoncpp
    JSONCPP_CFLAGS := -I/usr/include/jsoncpp
endif

# Add jsoncpp flags to existing variables
PKG_CFLAGS += $(JSONCPP_CFLAGS)
PKG_LIBS += $(JSONCPP_LIBS)

CXXFLAGS := -Wall -Wextra -std=c++17 -g -O0 $(PKG_CFLAGS) \
	    $(PKG_CDEFS) \
	    -DOCA_LITE_CONTROLLER \
	    -DOCA_RUN \
	    -D_DEBUG \
	-I../common \
    -I../../common \
    -I../../common/HostInterfaceLite \
    -I../../common/OCALite \
    -I../../common/OCALite/OCC \
    -I../../common/OCALite/OCF \
    -I../../common/OCALite/OCP.1 \
    -I../../common/OCALite/Proxy

# Source files from the top-level common directory
FRAMEWORK_COMMON_SOURCES := $(shell find ../../common -name "*.cpp" | grep -v "AES67" | grep -v "OcaLiteMediaTransportNetworkAES67")

# Source files from the app-level common directory
APP_COMMON_SOURCES       := ../common/FusionProxy.cpp \
                            ../common/workers/ZoneGroup.cpp

# App-specific source files
APP_SOURCES := OCALiteController.cpp \
               OcaServiceDiscovery.cpp \
               ControlPalGainActuator.cpp \
               ControlPalMuteActuator.cpp \
               ControlPalSwitchActuator.cpp \
               ControlPalSetupUtils.cpp \
               $(shell find HostInterface -name "*.cpp")

# Object files in build directory, preserving directory structure
FRAMEWORK_COMMON_OBJECTS   := $(patsubst ../../common/%.cpp,$(BUILD_DIR)/framework-common/%.o,$(FRAMEWORK_COMMON_SOURCES))
APP_COMMON_OBJECTS         := $(patsubst ../common/%.cpp,$(BUILD_DIR)/app-common/%.o,$(APP_COMMON_SOURCES))
APP_OBJECTS                := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(APP_SOURCES))
ALL_OBJECTS                := $(APP_OBJECTS) $(FRAMEWORK_COMMON_OBJECTS) $(APP_COMMON_OBJECTS)

# Output executable
TARGET := ocalitecontroller

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS)
	$(CXX) $^ $(PKG_LIBS) -o $@ -lpthread -lc $(LDFLAGS)

# Rule for app-specific sources
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Rule for app-common sources
$(BUILD_DIR)/app-common/%.o: ../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Rule for framework-common sources
$(BUILD_DIR)/framework-common/%.o: ../../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
