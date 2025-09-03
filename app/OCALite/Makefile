# OCALite Makefile
CXX := g++
CXXFLAGS := -Wall -Wextra -std=c++11 \
	    -DOCA_RUN \
    -I../../common \
    -I../../common/HostInterfaceLite \
    -I../../common/OCALite \
    -I../../common/OCALite/OCC \
    -I../../common/OCALite/OCF \
    -I../../common/OCALite/OCP.1 \
    -I../../common/OCALite/Proxy

# Source files
SOURCES := OCALite.cpp \
          $(shell find HostInterface -name "*.cpp")

OBJECTS := $(SOURCES:.cpp=.o)

# Common library
COMMON_LIB := ../../common/libocalitecommon.a

# Output executable
TARGET := ocalite

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS) $(COMMON_LIB)
	$(CXX) $(OBJECTS) $(COMMON_LIB) -o $@ -lpthread -lc -ldns_sd

$(COMMON_LIB):
	$(MAKE) -C ../../common

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f $(OBJECTS) $(TARGET)
