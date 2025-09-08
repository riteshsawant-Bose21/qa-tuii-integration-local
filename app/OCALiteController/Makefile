# OCALiteController Makefile
CXX := g++

# Detect platform for DNS-SD support
UNAME_S := $(shell uname -s)
ifeq ($(UNAME_S),Darwin)
    # macOS: Use native DNS-SD framework
    PKG_CFLAGS :=
    PKG_LIBS :=
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

# Source files
SOURCES := OCALiteController.cpp \
          $(shell find HostInterface -name "*.cpp")

OBJECTS := $(SOURCES:.cpp=.o)

# Common library
COMMON_LIB := ../../common/libocalitecommon.a

# Output executable
TARGET := ocalitecontroller

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS) $(COMMON_LIB)
	$(CXX) $(OBJECTS) $(COMMON_LIB) $(PKG_LIBS) -o $@ -lpthread -lc $(LDFLAGS)

$(COMMON_LIB):
	$(MAKE) -C ../../common

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)
