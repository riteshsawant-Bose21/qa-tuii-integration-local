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

  // Simulate server update
  monitor.handleExternalUpdate("settings.volume", Json::Value(0.5));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "settings.volume");
  EXPECT_EQ(newValues[0].asDouble(), 0.5);
}

// Array Tests
TEST_F(JsonMonitorTest, ArrayIndexUpdate) {
  addCallback("audio.eq[2].gain");

  // Simulate server update
  monitor.handleExternalUpdate("audio.eq[2].gain", Json::Value(3.0));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "audio.eq[2].gain");
  EXPECT_EQ(newValues[0].asDouble(), 3.0);
}

// Wildcard Pattern Tests
TEST_F(JsonMonitorTest, WildcardPattern) {
  addPatternCallback("audio.settings.*");

  // Simulate server updates
  monitor.handleExternalUpdate("audio.settings.volume", Json::Value(0.7));
  monitor.handleExternalUpdate("audio.settings.mute", Json::Value(true));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.settings.volume");
  EXPECT_EQ(receivedPaths[1], "audio.settings.mute");
}

// Nested Pattern Tests
TEST_F(JsonMonitorTest, NestedWildcard) {
  addPatternCallback("audio.*.gain");

  // Simulate server updates
  monitor.handleExternalUpdate("audio.eq1.gain", Json::Value(1.0));
  monitor.handleExternalUpdate("audio.eq2.gain", Json::Value(2.0));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq2.gain");
}

// Value Change Tests
TEST_F(JsonMonitorTest, NestedValueChanges) {
  addPatternCallback("settings.audio.*");

  // Simulate server sending complete state for a nested object
  Json::Value state;
  state["low_gain"] = -6.0;
  state["high_gain"] = 6.0;
  monitor.handleExternalUpdate("settings.audio.tone_eq1", state);

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "settings.audio.tone_eq1");
  EXPECT_EQ(newValues[0]["low_gain"].asDouble(), -6.0);
  EXPECT_EQ(newValues[0]["high_gain"].asDouble(), 6.0);
}

// Edge Cases
TEST_F(JsonMonitorTest, EmptyPath) {
  addCallback("");

  // Simulate server update at root
  Json::Value root;
  root["key"] = "value";
  monitor.handleExternalUpdate("", root);

  std::cout << "Received paths count: " << receivedPaths.size() << std::endl;
  for (const auto &path : receivedPaths) {
    std::cout << "Received path: '" << path << "'" << std::endl;
  }

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(newValues[0]["key"].asString(), "value");
}

TEST_F(JsonMonitorTest, DuplicateUpdates) {
  addCallback("test.path");

  // Simulate server sending same value twice
  Json::Value val(1);
  monitor.handleExternalUpdate("test.path", val);
  monitor.handleExternalUpdate("test.path", val);

  // Should only receive one notification since value didn't change
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
}

// Pattern Matching Tests
TEST_F(JsonMonitorTest, ComplexPatternMatching) {
  addPatternCallback("audio.*.gain[*]");

  // Simulate server updates for array elements
  monitor.handleExternalUpdate("audio.eq1.gain[2]", Json::Value(1.5));
  monitor.handleExternalUpdate("audio.comp.gain[0]", Json::Value(2.5));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain[2]");
  EXPECT_EQ(receivedPaths[1], "audio.comp.gain[0]");
}

// State Retrieval Tests
TEST_F(JsonMonitorTest, StateRetrieval) {
  // Set up initial state
  Json::Value state;
  state["volume"] = 0.8;
  monitor.handleExternalUpdate("settings", state);

  // Test get() functionality
  Json::Value retrieved = monitor.get("settings.volume");
  EXPECT_EQ(retrieved.asDouble(), 0.8);

  // Test non-existent path
  retrieved = monitor.get("settings.nonexistent");
  EXPECT_TRUE(retrieved.isNull());
}

TEST_F(JsonMonitorTest, MultipleWatchersOnSamePath) {
  std::vector<std::string> paths1, paths2;

  monitor.watch("test.path", [&](const std::string &p, const Json::Value &,
                                 const Json::Value &) { paths1.push_back(p); });

  monitor.watch("test.path", [&](const std::string &p, const Json::Value &,
                                 const Json::Value &) { paths2.push_back(p); });

  monitor.handleExternalUpdate("test.path", Json::Value(1));

  EXPECT_EQ(paths1.size(), static_cast<size_t>(1));
  EXPECT_EQ(paths2.size(), static_cast<size_t>(1));
}

TEST_F(JsonMonitorTest, MultipleWildcards) {
  addPatternCallback("audio.*.eq.*.gain");

  monitor.handleExternalUpdate("audio.ch1.eq.band1.gain", Json::Value(1.0));
  monitor.handleExternalUpdate("audio.ch2.eq.band2.gain", Json::Value(2.0));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.ch1.eq.band1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.ch2.eq.band2.gain");
}

TEST_F(JsonMonitorTest, ValueTypeChanges) {
  addCallback("test.value");

  monitor.handleExternalUpdate("test.value", Json::Value(42));
  monitor.handleExternalUpdate("test.value", Json::Value("string"));
  monitor.handleExternalUpdate("test.value", Json::Value(true));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(3));
  EXPECT_TRUE(oldValues[1].isInt());
  EXPECT_TRUE(newValues[1].isString());
  EXPECT_TRUE(oldValues[2].isString());
  EXPECT_TRUE(newValues[2].isBool());
}

TEST_F(JsonMonitorTest, DeepNestedPath) {
  addCallback("a.b.c.d.e.f.g.h.i.j.value");

  monitor.handleExternalUpdate("a.b.c.d.e.f.g.h.i.j.value", Json::Value(1));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "a.b.c.d.e.f.g.h.i.j.value");
}

TEST_F(JsonMonitorTest, RootWatcherWithNestedUpdates) {

  // Root watcher
  addCallback("");

  monitor.handleExternalUpdate("deep.nested.path", Json::Value(1));
  monitor.handleExternalUpdate("another.path", Json::Value(2));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "deep.nested.path");
  EXPECT_EQ(receivedPaths[1], "another.path");
}

TEST_F(JsonMonitorTest, ConcurrentPatternAndExactWatchers) {
  addCallback("audio.eq1.gain");
  addPatternCallback("audio.*.gain");

  monitor.handleExternalUpdate("audio.eq1.gain", Json::Value(1.0));

  // Should receive two notifications - one for each watcher
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq1.gain");
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}