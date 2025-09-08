# OCALiteController Makefile
CXX := g++
BUILD_DIR := build

# Detect platform for DNS-SD support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    # macOS: Use native DNS-SD framework
    PKG_CFLAGS :=
    PKG_LIBS := -framework CoreServices
    LDFLAGS :=
else
    # Linux: Use Avahi compatibility layer
    PKG_CFLAGS := $(shell pkg-config --cflags avahi-compat-libdns_sd 2>/dev/null || echo "")
    PKG_LIBS := $(shell pkg-config --libs avahi-compat-libdns_sd 2>/dev/null || echo "-lavahi-compat-libdns_sd")
    LDFLAGS := 
endif

CXXFLAGS := -Wall -Wextra -std=c++11 $(PKG_CFLAGS) \
	    -DOCA_LITE_CONTROLLER \
	    -DOCA_RUN \
    -I../../common \
    -I../../common/HostInterfaceLite \
    -I../../common/OCALite \
    -I../../common/OCALite/OCC \
    -I../../common/OCALite/OCF \
    -I../../common/OCALite/OCP.1 \
    -I../../common/OCALite/Proxy

# App-specific source files
APP_SOURCES := OCALiteController.cpp \
               OcaServiceDiscovery.cpp \
               $(shell find HostInterface -name "*.cpp")

# Common source files (all from common directory, excluding AES67)
COMMON_SOURCES := $(shell find ../../common -name "*.cpp" | grep -v "AES67" | grep -v "OcaLiteMediaTransportNetworkAES67")

# All source files
ALL_SOURCES := $(APP_SOURCES) $(COMMON_SOURCES)

# Object files in build directory, preserving directory structure
APP_OBJECTS := $(patsubst %.cpp,$(BUILD_DIR)/%.o,$(APP_SOURCES))
COMMON_OBJECTS := $(patsubst ../../common/%.cpp,$(BUILD_DIR)/common/%.o,$(COMMON_SOURCES))
ALL_OBJECTS := $(APP_OBJECTS) $(COMMON_OBJECTS)

# Output executable
TARGET := ocalitecontroller

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(ALL_OBJECTS)
	$(CXX) $(ALL_OBJECTS) $(PKG_LIBS) -o $@ -lpthread -lc++ $(LDFLAGS)

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
