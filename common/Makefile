# Common library Makefile
CXX := g++
CXXFLAGS := -Wall -Wextra -std=c++11 -fPIC \
    -I. \
    -I./HostInterfaceLite \
    -I./OCALite \
    -I./OCALite/OCC \
    -I./OCALite/OCF \
    -I./OCALite/OCP.1 \
    -I./OCALite/Proxy

# Source directories
HOSTINTERFACE_DIR := HostInterfaceLite
OCALITE_DIR := OCALite
OCC_DIR := $(OCALITE_DIR)/OCC
OCF_DIR := $(OCALITE_DIR)/OCF
OCP1_DIR := $(OCALITE_DIR)/OCP.1
PROXY_DIR := $(OCALITE_DIR)/Proxy

# Find all source files
SOURCES := $(shell find $(HOSTINTERFACE_DIR) -name "*.cpp") \
          $(shell find $(OCALITE_DIR)/OCC -name "*.cpp") \
          $(shell find $(OCALITE_DIR)/OCF -name "*.cpp") \
          $(shell find $(OCALITE_DIR)/OCP.1 -name "*.cpp") \
          $(shell find $(OCALITE_DIR)/Proxy -name "*.cpp")

# Generate object file names
OBJECTS := $(SOURCES:.cpp=.o)

# Output library
LIBRARY := libocalitecommon.a

.PHONY: all clean

all: $(LIBRARY)

$(LIBRARY): $(OBJECTS)
	ar rcs $@ $^

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(LIBRARY)
