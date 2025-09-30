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
    -I../common \
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

# Common source files
FRAMEWORK_COMMON_SOURCES := $(shell find ../../common -name "*.cpp" | grep -v "AES67" | grep -v "OcaLiteMediaTransportNetworkAES67")
APP_COMMON_SOURCES       := ../common/ZoneConfigBuilder.cpp \
                           ../common/workers/ConcreteGainActuator.cpp \
                           ../common/workers/ConcreteMuteActuator.cpp \
                           ../common/workers/ConcreteSwitchActuator.cpp \
                           ../common/workers/FusionBlock.cpp \
                           ../common/workers/ZoneGroup.cpp

# Object files
APP_OBJECTS                := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(APP_SOURCES))
FRAMEWORK_COMMON_OBJECTS   := $(patsubst ../../common/%.cpp,$(BUILD_DIR)/framework-common/%.o,$(FRAMEWORK_COMMON_SOURCES))
APP_COMMON_OBJECTS         := $(patsubst ../common/%.cpp,$(BUILD_DIR)/app-common/%.o,$(APP_COMMON_SOURCES))
ALL_OBJECTS                := $(APP_OBJECTS) $(FRAMEWORK_COMMON_OBJECTS) $(APP_COMMON_OBJECTS)

# Output executable
TARGET := ocalite

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS)
	$(CXX) $^ $(PKG_LIBS) -o $@ -lpthread -lc $(LDFLAGS)

# App source files
$(BUILD_DIR)/%.o: %.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# App-common source files
$(BUILD_DIR)/app-common/%.o: ../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

# Framework-common source files
$(BUILD_DIR)/framework-common/%.o: ../../common/%.cpp
	@mkdir -p $(dir $@)
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -rf $(BUILD_DIR) $(TARGET)
