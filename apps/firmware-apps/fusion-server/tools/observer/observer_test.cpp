#include "observer.h"

#include <gtest/gtest.h>

class JsonMonitorTest : public ::testing::Test {
protected:
  JsonMonitor monitor;
  std::vector<std::string> receivedPaths;
  std::vector<Json::Value> oldValues;
  std::vector<Json::Value> newValues;

  void SetUp() override {
    receivedPaths.clear();
    oldValues.clear();
    newValues.clear();
  }

  void addCallback(const std::string &path) {
    monitor.watch(path, [this](const std::string &p, const Json::Value &old_val,
                               const Json::Value &new_val) {
      receivedPaths.push_back(p);
      oldValues.push_back(old_val);
      newValues.push_back(new_val);
    });
  }

  void addPatternCallback(const std::string &pattern) {
    monitor.watchPattern(pattern, [this](const std::string &p,
                                         const Json::Value &old_val,
                                         const Json::Value &new_val) {
      receivedPaths.push_back(p);
      oldValues.push_back(old_val);
      newValues.push_back(new_val);
    });
  }
};

// Basic Path Tests
TEST_F(JsonMonitorTest, SimplePathUpdate) {
  addCallback("settings.volume");
  monitor.update("settings.volume", 0.5);
  ASSERT_EQ(receivedPaths.size(), 1);
  EXPECT_EQ(receivedPaths[0], "settings.volume");
  EXPECT_EQ(newValues[0].asDouble(), 0.5);
}

// Array Tests
TEST_F(JsonMonitorTest, ArrayIndexUpdate) {
  addCallback("audio.eq[2].gain");
  monitor.update("audio.eq[2].gain", 3.0);
  ASSERT_EQ(receivedPaths.size(), 1);
  EXPECT_EQ(receivedPaths[0], "audio.eq[2].gain");
  EXPECT_EQ(newValues[0].asDouble(), 3.0);
}

// Wildcard Pattern Tests
TEST_F(JsonMonitorTest, WildcardPattern) {
  addPatternCallback("audio.settings.*");
  monitor.update("audio.settings.volume", 0.7);
  monitor.update("audio.settings.mute", true);
  ASSERT_EQ(receivedPaths.size(), 2);
  EXPECT_EQ(receivedPaths[0], "audio.settings.volume");
  EXPECT_EQ(receivedPaths[1], "audio.settings.mute");
}

// Nested Pattern Tests
TEST_F(JsonMonitorTest, NestedWildcard) {
  addPatternCallback("audio.*.gain");
  monitor.update("audio.eq1.gain", 1.0);
  monitor.update("audio.eq2.gain", 2.0);
  ASSERT_EQ(receivedPaths.size(), 2);
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq2.gain");
}

// Multiple Observer Tests
TEST_F(JsonMonitorTest, MultipleObservers) {
  addCallback("settings.volume");
  addPatternCallback("settings.*");
  monitor.update("settings.volume", 0.8);
  ASSERT_EQ(receivedPaths.size(), 2);
  EXPECT_EQ(receivedPaths[0], "settings.volume");
  EXPECT_EQ(receivedPaths[1], "settings.volume");
}

// Edge Cases
TEST_F(JsonMonitorTest, EmptyPath) {
  addCallback("");
  monitor.update("", Json::Value(1));
  ASSERT_EQ(receivedPaths.size(), 1);
}

TEST_F(JsonMonitorTest, InvalidArrayIndex) {
  addCallback("array[-1]");
  monitor.update("array[-1]", Json::Value(1));
  ASSERT_EQ(receivedPaths.size(), 0);
}

TEST_F(JsonMonitorTest, DuplicateUpdates) {
  addCallback("test.path");
  Json::Value val(1);
  monitor.update("test.path", val);
  monitor.update("test.path", val);
  ASSERT_EQ(receivedPaths.size(), 1);
}

TEST_F(JsonMonitorTest, PathComponentParsing) {
  auto components = monitor.split_path("audio.eq[2].gain[0]");
  ASSERT_EQ(components.size(), 4);
  EXPECT_EQ(components[0].key, "audio");
  EXPECT_FALSE(components[0].isArrayAccess);
  EXPECT_EQ(components[1].key, "eq");
  EXPECT_TRUE(components[1].isArrayAccess);
  EXPECT_EQ(components[1].arrayIndex, 2);
}

// Pattern Matching Tests
TEST_F(JsonMonitorTest, ComplexPatternMatching) {
  PathPattern pattern("audio.*.gain[*]");
  std::vector<PathComponent> path = monitor.split_path("audio.eq1.gain[2]");
  EXPECT_TRUE(pattern.matches(path));
  path = monitor.split_path("audio.settings.other");
  EXPECT_FALSE(pattern.matches(path));
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}