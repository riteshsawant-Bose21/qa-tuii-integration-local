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

# ================================
# Boost ASIO support
# ================================
ifeq ($(UNAME_S),Darwin)
    # macOS: Use Homebrew Boost (header-only boost::system, don't force -lboost_system)
    BOOST_PREFIX := $(shell brew --prefix 2>/dev/null)
    # Fallback to default Homebrew paths if BOOST_PREFIX is empty
    ifeq ($(BOOST_PREFIX),)
        # Try Apple Silicon default first, then Intel
        ifeq ($(shell test -d /opt/homebrew && echo yes),yes)
            BOOST_PREFIX := /opt/homebrew
        else
            BOOST_PREFIX := /usr/local
        endif
    endif
    BOOST_CFLAGS := -I$(BOOST_PREFIX)/include
    BOOST_LIBS :=

else ifeq ($(ARCH),arm64)
    # Cross-compile ARM64: Use SDK paths if available
    ifneq ($(SDK_DIR),)
        BOOST_LIBS := -lboost_system
        BOOST_CFLAGS := -I${SDK_DIR}/sysroots/cortexa53-crypto-poky-linux/usr/include
    else
        BOOST_LIBS := -lboost_system
        BOOST_CFLAGS := -I/usr/include
    endif
else
    # Linux: Standard system paths
    BOOST_LIBS := -lboost_system
    BOOST_CFLAGS := -I/usr/include
endif

# Add boost flags to existing variables
PKG_CFLAGS += $(BOOST_CFLAGS)
PKG_LIBS += $(BOOST_LIBS)


# Disable DNS-SD (Bonjour/Avahi) across the device build
DISABLE_DNSSD_FLAGS := -DOCA_DISABLE_DNSSD

CXXFLAGS := -Wall -Wextra -std=c++17 -g -O0 $(PKG_CFLAGS) \
	    $(PKG_CDEFS) \
	    -DOCA_RUN \
	    -D_DEBUG \
    $(DISABLE_DNSSD_FLAGS) \
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
APP_COMMON_SOURCES       := ../common/workers/ConcreteGainActuator.cpp \
                           ../common/workers/ConcreteMuteActuator.cpp \
                           ../common/workers/ConcreteSwitchActuator.cpp \
                           ../common/workers/ZoneGroup.cpp \
                           ../common/OcaLiteControllerConfigManager.cpp \
                           ../common/workers/FusionBlock.cpp \
                           ../common/UDPSender.cpp \
                           ../common/FusionAudioBridge.cpp

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
