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

TEST_F(JsonMonitorTest, SimplePathUpdate) {
  addCallback("settings.volume");
  monitor.handleExternalUpdate("settings.volume", Json::Value(0.5));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "settings.volume");
  EXPECT_EQ(newValues[0].asDouble(), 0.5);
}

TEST_F(JsonMonitorTest, ArrayIndexUpdate) {
  addCallback("audio.eq[2].gain");
  monitor.handleExternalUpdate("audio.eq[2].gain", Json::Value(3.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "audio.eq[2].gain");
  EXPECT_EQ(newValues[0].asDouble(), 3.0);
}

TEST_F(JsonMonitorTest, EmptyPath) {
  addCallback("");
  Json::Value root;
  root["key"] = "value";
  monitor.handleExternalUpdate("", root);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(newValues[0]["key"].asString(), "value");
}

TEST_F(JsonMonitorTest, DuplicateUpdates) {
  addCallback("test.path");
  Json::Value val(1);
  monitor.handleExternalUpdate("test.path", val);
  monitor.handleExternalUpdate("test.path", val);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
}

TEST_F(JsonMonitorTest, ArraySlicePatternMatching) {
  addPatternCallback("audio.eq[1:3].gain");
  monitor.handleExternalUpdate("audio.eq[0].gain",
                               Json::Value(0.0)); // should not match
  monitor.handleExternalUpdate("audio.eq[1].gain",
                               Json::Value(1.1)); // should match
  monitor.handleExternalUpdate("audio.eq[2].gain",
                               Json::Value(1.2)); // should match
  monitor.handleExternalUpdate("audio.eq[3].gain",
                               Json::Value(1.3)); // should match
  monitor.handleExternalUpdate("audio.eq[4].gain",
                               Json::Value(1.4)); // should not match
  // Expect exactly three notifications for indices 1, 2, and 3.
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(3));
  EXPECT_EQ(receivedPaths[0], "audio.eq[1].gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq[2].gain");
  EXPECT_EQ(receivedPaths[2], "audio.eq[3].gain");
}

TEST_F(JsonMonitorTest, ComplexPatternMatching) {
  addPatternCallback("audio.*.gain[*]");
  monitor.handleExternalUpdate("audio.eq1.gain[2]", Json::Value(1.5));
  monitor.handleExternalUpdate("audio.comp.gain[0]", Json::Value(2.5));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain[2]");
  EXPECT_EQ(receivedPaths[1], "audio.comp.gain[0]");
}

TEST_F(JsonMonitorTest, ExtensivePatternMatching) {
  // Pattern with multiple wildcards and bracket wildcard
  // Pattern: "system.*.status[*]"
  // Expected: Match any update that starts with "system", has any second token,
  // then "status", and then an array access (any index).
  receivedPaths.clear();
  addPatternCallback("system.*.status[*]");

  // These updates should match:
  monitor.handleExternalUpdate("system.cpu.status[0]", Json::Value("OK"));
  monitor.handleExternalUpdate("system.cpu.status[1]", Json::Value("WARN"));
  monitor.handleExternalUpdate("system.gpu.status[0]", Json::Value("FAIL"));
  monitor.handleExternalUpdate("system.memory.status[0]", Json::Value("GOOD"));
  // This update should NOT match (missing the array access at the end)
  monitor.handleExternalUpdate("system.cpu.status", Json::Value("INVALID"));

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(4));
  EXPECT_EQ(receivedPaths[0], "system.cpu.status[0]");
  EXPECT_EQ(receivedPaths[1], "system.cpu.status[1]");
  EXPECT_EQ(receivedPaths[2], "system.gpu.status[0]");
  EXPECT_EQ(receivedPaths[3], "system.memory.status[0]");

  // Pattern with a slice
  // Pattern: "array[1:2].value" should match updates with indices 1 and 2 only.
  receivedPaths.clear();
  addPatternCallback("array[1:2].value");

  monitor.handleExternalUpdate("array[0].value",
                               Json::Value(10)); // Should NOT match
  monitor.handleExternalUpdate("array[1].value", Json::Value(20)); // Match
  monitor.handleExternalUpdate("array[2].value", Json::Value(30)); // Match
  monitor.handleExternalUpdate("array[3].value",
                               Json::Value(40)); // Should NOT match

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "array[1].value");
  EXPECT_EQ(receivedPaths[1], "array[2].value");

  // Nested wildcard pattern
  // Pattern: "settings.*.zone.*.speaker"
  // Expected: Match paths that follow the structure: settings -> any token ->
  // zone -> any token -> speaker.
  receivedPaths.clear();
  addPatternCallback("settings.*.zone.*.speaker");

  monitor.handleExternalUpdate("settings.A.zone.1.speaker", Json::Value("101"));
  monitor.handleExternalUpdate("settings.A.zone.2.speaker", Json::Value("102"));
  monitor.handleExternalUpdate("settings.B.zone.1.speaker", Json::Value("201"));

  // Negative tests:
  monitor.handleExternalUpdate(
      "settings.B.zone.1.speaker.extra",
      Json::Value("Extra")); // extra level, should not match
  monitor.handleExternalUpdate(
      "settings.B.zone.2",
      Json::Value("NoRoom")); // missing final token, should not match

  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(3));
  EXPECT_EQ(receivedPaths[0], "settings.A.zone.1.speaker");
  EXPECT_EQ(receivedPaths[1], "settings.A.zone.2.speaker");
  EXPECT_EQ(receivedPaths[2], "settings.B.zone.1.speaker");
}

TEST_F(JsonMonitorTest, StateRetrieval) {
  Json::Value state;
  state["volume"] = 0.8;
  monitor.handleExternalUpdate("settings", state);
  Json::Value retrieved = monitor.get("settings.volume");
  EXPECT_EQ(retrieved.asDouble(), 0.8);
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

TEST_F(JsonMonitorTest, WildcardPattern) {
  addPatternCallback("audio.settings.*");
  monitor.handleExternalUpdate("audio.settings.volume", Json::Value(0.7));
  monitor.handleExternalUpdate("audio.settings.mute", Json::Value(true));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.settings.volume");
  EXPECT_EQ(receivedPaths[1], "audio.settings.mute");
}

TEST_F(JsonMonitorTest, NestedWildcard) {
  addPatternCallback("audio.*.gain");
  monitor.handleExternalUpdate("audio.eq1.gain", Json::Value(1.0));
  monitor.handleExternalUpdate("audio.eq2.gain", Json::Value(2.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq2.gain");
}

TEST_F(JsonMonitorTest, NestedWildcardValueChanges) {
  addPatternCallback("settings.audio.*");
  Json::Value state;
  state["low_gain"] = -6.0;
  state["high_gain"] = 6.0;
  monitor.handleExternalUpdate("settings.audio.tone_eq1", state);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "settings.audio.tone_eq1");
  EXPECT_EQ(newValues[0]["low_gain"].asDouble(), -6.0);
  EXPECT_EQ(newValues[0]["high_gain"].asDouble(), 6.0);
}

TEST_F(JsonMonitorTest, MultipleWildcards) {
  addPatternCallback("audio.*.eq.*.gain");
  monitor.handleExternalUpdate("audio.ch1.eq.band1.gain", Json::Value(1.0));
  monitor.handleExternalUpdate("audio.ch2.eq.band2.gain", Json::Value(2.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.ch1.eq.band1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.ch2.eq.band2.gain");
}

TEST_F(JsonMonitorTest, PatternWithBracketWildcard) {
  // Register a pattern watcher using the problematic pattern.
  addPatternCallback("settings.audio.*.*[*]");

  // Simulate an update with a JSON structure that should match the pattern.
  // Here we create an example update that contains nested objects and an array.
  Json::Value update;
  update["settings"]["audio"]["ch1"]["eq"] = Json::arrayValue;
  update["settings"]["audio"]["ch1"]["eq"].append(Json::Value(0.8));
  update["settings"]["audio"]["ch1"]["eq"].append(Json::Value(1.2));

  // This update should trigger the pattern callback for each matching concrete
  // path.
  monitor.handleExternalUpdate("settings.audio.ch1.eq[0]", Json::Value(0.8));
  monitor.handleExternalUpdate("settings.audio.ch1.eq[1]", Json::Value(1.2));

  // Verify that the callbacks were triggered.
  ASSERT_GE(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "settings.audio.ch1.eq[0]");
  EXPECT_EQ(receivedPaths[1], "settings.audio.ch1.eq[1]");
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
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq1.gain");
}

TEST_F(JsonMonitorTest, IntermediateStateCreation) {
  // Update a nested path that doesn't exist yet.
  // This should create the missing objects ("new" and "branch") and an array
  // for "branch", then set index 2 of that array to an object containing
  // "leaf".
  Json::Value value("hello");
  monitor.handleExternalUpdate("new.branch[2].leaf", value);

  // Verify that get() returns the correct value.
  Json::Value retrieved = monitor.get("new.branch[2].leaf");
  EXPECT_EQ(retrieved.asString(), "hello");

  // Also, verify that the overall internal state reflects the changes.
  Json::Value state = monitor.get("");
  ASSERT_TRUE(state.isObject());
  ASSERT_TRUE(state.isMember("new"));

  Json::Value newObj = state["new"];
  ASSERT_TRUE(newObj.isObject());
  ASSERT_TRUE(newObj.isMember("branch"));

  Json::Value branch = newObj["branch"];
  ASSERT_TRUE(branch.isArray());
  // Since we updated index 2, the array should have at least 3 elements.
  EXPECT_GE(branch.size(), static_cast<Json::ArrayIndex>(3));
  // Verify that the value at index 2, under "leaf", is "hello".
  EXPECT_EQ(branch[2]["leaf"].asString(), "hello");
}

TEST_F(JsonMonitorTest, ArrayExpansion) {
  // Update an array index that is out-of-bounds. For example, update
  // "myArray[4]" when "myArray" doesn't exist yet (or is empty). The observer
  // should create an array of at least 5 elements and assign the value to
  // index 4.
  Json::Value value(99);
  monitor.handleExternalUpdate("myArray[4]", value);

  // Check that the value at "myArray[4]" is the one we set.
  Json::Value retrieved = monitor.get("myArray[4]");
  EXPECT_EQ(retrieved.asInt(), 99);

  // Also verify that the array "myArray" has been expanded to the proper size.
  Json::Value arrayValue = monitor.get("myArray");
  ASSERT_TRUE(arrayValue.isArray());
  EXPECT_EQ(arrayValue.size(), static_cast<Json::ArrayIndex>(5));
}

TEST_F(JsonMonitorTest, GetCoverage) {

  Json::Value state;
  state["settings"]["volume"] = 0.8;

  state["settings"]["channels"] = Json::arrayValue;
  state["settings"]["channels"].append("left");
  state["settings"]["channels"].append("right");

  state["settings"]["nested"]["values"] = Json::arrayValue;
  state["settings"]["nested"]["values"].append(1);
  state["settings"]["nested"]["values"].append(2);
  state["settings"]["nested"]["values"].append(3);

  state["data"] = Json::arrayValue;
  Json::Value obj1, obj2;
  obj1["name"] = "one";
  obj2["name"] = "two";
  state["data"].append(obj1);
  state["data"].append(obj2);

  // Update the monitor's state with the new state (empty path means root).
  monitor.handleExternalUpdate("", state);

  //
  // Valid retrievals
  //

  // Retrieve a simple nested key.
  Json::Value volume = monitor.get("settings.volume");
  EXPECT_DOUBLE_EQ(volume.asDouble(), 0.8);

  // Retrieve elements from an array.
  Json::Value leftChannel = monitor.get("settings.channels[0]");
  EXPECT_EQ(leftChannel.asString(), "left");

  Json::Value rightChannel = monitor.get("settings.channels[1]");
  EXPECT_EQ(rightChannel.asString(), "right");

  // Retrieve a nested array element.
  Json::Value nestedValue = monitor.get("settings.nested.values[1]");
  EXPECT_EQ(nestedValue.asInt(), 2);

  // Retrieve a property from an object inside an array.
  Json::Value nameOne = monitor.get("data[0].name");
  EXPECT_EQ(nameOne.asString(), "one");

  Json::Value nameTwo = monitor.get("data[1].name");
  EXPECT_EQ(nameTwo.asString(), "two");

  //
  // Invalid or out-of-bound retrievals:
  //

  // Out-of-bounds index for an array.
  Json::Value invalidChannel = monitor.get("settings.channels[2]");
  EXPECT_TRUE(invalidChannel.isNull());

  // Nonexistent key in an object.
  Json::Value nonExistent = monitor.get("settings.nonexistent");
  EXPECT_TRUE(nonExistent.isNull());

  // Out-of-bounds index in an array of objects.
  Json::Value invalidData = monitor.get("data[2].name");
  EXPECT_TRUE(invalidData.isNull());

  // Nonexistent property on an existing object.
  Json::Value invalidProp = monitor.get("data[0].nonexistent");
  EXPECT_TRUE(invalidProp.isNull());
}

TEST_F(JsonMonitorTest, RootWatcherGlobalUpdate) {
  // Register a root watcher by using an empty string.
  addCallback("");

  // Create a new state that will replace the entire internal state.
  Json::Value newState;
  newState["key"] = "value";

  // Update the entire state by passing an empty update path.
  monitor.handleExternalUpdate("", newState);

  // Verify that the root watcher callback was triggered.
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));

  // For a root watcher, the update path is empty.
  EXPECT_EQ(receivedPaths[0], "");

  // The new value passed to the callback should be the entire new state.
  EXPECT_EQ(newValues[0]["key"].asString(), "value");
}

TEST_F(JsonMonitorTest, MultipleGlobalUpdatesRootWatcher) {
  // Register a root watcher.
  addCallback("");

  // First global update: set the state to { "a": 1 }
  Json::Value state1;
  state1["a"] = 1;
  monitor.handleExternalUpdate("", state1);

  // Second global update: update the state to { "a": 2, "b": 3 }
  Json::Value state2;
  state2["a"] = 2;
  state2["b"] = 3;
  monitor.handleExternalUpdate("", state2);

  // Verify that the root watcher was triggered for both updates.
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));

  // The first callback (from the first update) should have an empty path,
  // and the new value should match state1.
  EXPECT_EQ(receivedPaths[0], "");
  EXPECT_EQ(newValues[0]["a"].asInt(), 1);

  // The second callback (from the second update) should also have an empty
  // path, and the new value should match state2.
  EXPECT_EQ(receivedPaths[1], "");
  EXPECT_EQ(newValues[1]["a"].asInt(), 2);
  EXPECT_EQ(newValues[1]["b"].asInt(), 3);
}

#include <thread>
#include <vector>

TEST_F(JsonMonitorTest, ConcurrentUpdatesThreadSafety) {
  const int numThreads = 10;
  const int numUpdates = 100;
  std::vector<std::thread> threads;

  // Spawn several threads that update distinct keys concurrently.
  for (int i = 0; i < numThreads; ++i) {
    threads.emplace_back([this, i]() {
      // Each thread updates a unique key: "concurrent.keyX"
      std::string path = "concurrent.key" + std::to_string(i);
      for (int j = 0; j < numUpdates; ++j) {
        monitor.handleExternalUpdate(path, Json::Value(j));
        // Optionally yield to encourage context switching.
        std::this_thread::yield();
      }
    });
  }

  // Wait for all threads to complete.
  for (auto &thread : threads) {
    thread.join();
  }

  // After all updates, each key should have the final value (numUpdates - 1).
  for (int i = 0; i < numThreads; ++i) {
    std::string path = "concurrent.key" + std::to_string(i);
    Json::Value val = monitor.get(path);
    EXPECT_EQ(val.asInt(), numUpdates - 1)
        << "Expected " << numUpdates - 1 << " at path " << path;
  }
}

TEST(ParsePatternInvalid, NonNumericArrayIndex) {
  // "foo" is not numeric, so parsing should throw an error.
  EXPECT_THROW(parsePattern("audio.eq[foo].gain"), std::runtime_error);
}

TEST(ParsePatternInvalid, InvalidSliceNonNumericEnd) {
  // The slice "1:bar" is invalid because "bar" is not a number.
  EXPECT_THROW(parsePattern("audio.eq[1:bar].gain"), std::runtime_error);
}

TEST(ParsePatternInvalid, EmptyBracketContent) {
  // The brackets are empty (i.e. "[]"), which is not allowed.
  EXPECT_THROW(parsePattern("audio.eq[].gain"), std::runtime_error);
}

TEST(ParsePatternInvalid, MultipleBracketPairsInToken) {
  // A token like "eq[1][2]" is not supported. The parser will treat the inner
  // content as "1][2", which is not a valid numeric index, so it should throw.
  EXPECT_THROW(parsePattern("audio.eq[1][2].gain"), std::runtime_error);
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
