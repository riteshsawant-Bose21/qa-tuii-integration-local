CXX := g++
CXXFLAGS := -Wall -Wextra -std=c++11 \
    -I./common/HostInterfaceLite \
    -I./common/OCALite \
    -I./common/OCALite/OCC \
    -I./common/OCALite/OCF \
    -I./common/OCALite/OCP.1 \
    -I./common

# Directories
COMMON_DIR := common
APP_DIR := app

.PHONY: all clean OCALite OCALiteController

all: OCALite OCALiteController

OCALite:
	$(MAKE) -C $(APP_DIR)/OCALite

OCALiteController:
	$(MAKE) -C $(APP_DIR)/OCALiteController

clean:
	$(MAKE) -C $(APP_DIR)/OCALite clean
	$(MAKE) -C $(APP_DIR)/OCALiteController clean
