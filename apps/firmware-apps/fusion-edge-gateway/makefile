# fusion-edge-gateway Makefile

SRC_DIR := src
INCLUDE_DIR := include
EXTERNAL_INCLUDE_DIRS := external/include external/include/nlohmann
BUILD_DIR := build
TARGET := $(BUILD_DIR)/fusion-edge-gateway

SOURCES := $(wildcard $(SRC_DIR)/*.cpp)
OBJECTS := $(patsubst $(SRC_DIR)/%.cpp, $(BUILD_DIR)/%.o, $(SOURCES))

INCLUDES := -I$(INCLUDE_DIR) $(foreach dir,$(EXTERNAL_INCLUDE_DIRS),-I$(dir))

LDLIBS += -lcurl -lfmt
RELEASE_CXXFLAGS = -g -Wall -Wextra -O2 -std=c++17 -DNDEBUG -DSPDLOG_ACTIVE_LEVEL=SPDLOG_LEVEL_DEBUG -DSPDLOG_FMT_EXTERNAL

all: $(TARGET)

$(TARGET): $(OBJECTS)
	$(CXX) $(OBJECTS) -o $@ $(LDFLAGS) $(LDLIBS)

$(BUILD_DIR)/%.o: $(SRC_DIR)/%.cpp | $(BUILD_DIR)
	$(CXX) $(CXXFLAGS) $(INCLUDES) -c $< -o $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

release: clean
	$(MAKE) -j$(PARALLEL_MAKE) all CXXFLAGS='$(RELEASE_CXXFLAGS)'

clean:
	rm -rf $(BUILD_DIR)

.PHONY: all clean release
