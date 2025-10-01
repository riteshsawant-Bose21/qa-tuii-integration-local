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

CXXFLAGS := -Wall -Wextra -std=c++11 -g -O0 $(PKG_CFLAGS) \
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
APP_COMMON_SOURCES       := ../common/ZoneConfigBuilder.cpp \
                           ../common/FusionProxy.cpp \
                           ../common/workers/ConcreteGainActuator.cpp \
                           ../common/workers/ConcreteMuteActuator.cpp \
                           ../common/workers/ConcreteSwitchActuator.cpp \
                           ../common/workers/ZoneGroup.cpp

# App-specific source files
APP_SOURCES := OCALiteController.cpp \
               OcaServiceDiscovery.cpp \
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
