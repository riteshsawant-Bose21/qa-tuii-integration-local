CXX ?= g++
CXXFLAGS ?= -Wall -Wextra -O2 --std=c++17

SRC_DIR = src
INCLUDE_DIR = include
EX_INCLUDE_DIR = -Iexternal/include \
				-Iexternal/include/nlohmann
BUILD_DIR = build
TARGET = $(BUILD_DIR)/fusion-edge-gateway

SOURCES = $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS = $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(SOURCES))

INCLUDES = -I$(INCLUDE_DIR) $(EX_INCLUDE_DIR)

UNAME_S := $(shell uname -s)

ifeq ($(OS),Windows_NT)
    # Native Windows (Cygwin or cmd)
    CXX ?= g++
    LDFLAGS ?= -lcurl
    EXE_EXT := .exe
    CROSS_COMPILE :=
else ifeq ($(UNAME_S),Linux)
    ifneq (,$(findstring Microsoft,$(shell uname -r)))
        # WSL environment
        CXX ?= g++
        LDFLAGS ?= -lcurl
        EXE_EXT :=
        CROSS_COMPILE :=
    else
        # Native Linux or cross-compile
        TOOLCHAIN_DIR ?= /opt/bosepro-fusion/6.12-styhead
        SDKTARGETSYSROOT ?= $(TOOLCHAIN_DIR)/sysroots/armv8a-poky-linux
        CROSS_COMPILE ?= aarch64-poky-linux-
        CXX := $(CROSS_COMPILE)g++
        CC := $(CROSS_COMPILE)gcc

        PKG_CONFIG := PKG_CONFIG_SYSROOT_DIR=$(SDKTARGETSYSROOT) \
                      PKG_CONFIG_LIBDIR=$(SDKTARGETSYSROOT)/usr/lib/pkgconfig \
                      $(TOOLCHAIN_DIR)/sysroots/x86_64-pokysdk-linux/usr/bin/pkg-config

        PKG_CFLAGS := $(shell $(PKG_CONFIG) --cflags libcurl)
        PKG_LDFLAGS := $(shell $(PKG_CONFIG) --libs libcurl)

        CXXFLAGS += --sysroot=$(SDKTARGETSYSROOT) $(PKG_CFLAGS)
        LDFLAGS += --sysroot=$(SDKTARGETSYSROOT) $(PKG_LDFLAGS)
        EXE_EXT :=
    endif
endif

TARGET := $(TARGET)$(EXE_EXT)

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

release: clean
	$(MAKE) -j$(shell nproc) CXXFLAGS="$(CXXFLAGS) -g0 -O2 -DNDEBUG" LDFLAGS="$(LDFLAGS)" all
	$(CROSS_COMPILE)strip $(TARGET)

local: clean
	$(MAKE) -j$(shell nproc) CXX=g++ CXXFLAGS="-Wall -Wextra -O2 --std=c++17 -g" LDFLAGS="-lcurl" EXE_EXT="" all

clean:
	rm -rf $(BUILD_DIR)

strip:
	$(CROSS_COMPILE)strip $(TARGET)

.PHONY: all clean strip release local
