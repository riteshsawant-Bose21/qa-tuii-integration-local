CXX := g++
CXXFLAGS := -std=c++17 -Wall -O2

TARGET := cluster_listener
SRC := cluster_listener.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CXX) $(CXXFLAGS) -o $@ $^

clean:
	rm -f $(TARGET)

.PHONY: all clean