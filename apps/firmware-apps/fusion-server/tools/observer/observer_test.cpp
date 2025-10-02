#include "observer.h"

#include <thread>
#include <vector>

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

/* Verifies a simple exact-path update triggers a single callback with the new value. */
TEST_F(JsonMonitorTest, SimplePathUpdate) {
  addCallback("settings.volume");
  monitor.handleExternalUpdate("settings.volume", Json::Value(0.5));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "settings.volume");
  EXPECT_DOUBLE_EQ(newValues[0].asDouble(), 0.5);
}

/* Verifies exact-path updates work when the path contains an array index. */
TEST_F(JsonMonitorTest, ArrayIndexUpdate) {
  addCallback("audio.eq[2].gain");
  monitor.handleExternalUpdate("audio.eq[2].gain", Json::Value(3.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "audio.eq[2].gain");
  EXPECT_DOUBLE_EQ(newValues[0].asDouble(), 3.0);
}

/* Confirms an empty path replaces the entire root state and notifies root watcher. */
TEST_F(JsonMonitorTest, EmptyPath) {
  addCallback("");
  Json::Value root;
  root["key"] = "value";
  monitor.handleExternalUpdate("", root);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(newValues[0]["key"].asString(), "value");
}

/* Ensures identical back-to-back updates do not emit duplicate notifications. */
TEST_F(JsonMonitorTest, DuplicateUpdates) {
  addCallback("test.path");
  Json::Value val(1);
  monitor.handleExternalUpdate("test.path", val);
  monitor.handleExternalUpdate("test.path", val);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
}

/* Validates slice patterns match only indices within the closed interval. */
TEST_F(JsonMonitorTest, ArraySlicePatternMatching) {
  addPatternCallback("audio.eq[1:3].gain");
  monitor.handleExternalUpdate("audio.eq[0].gain", Json::Value(0.0)); // no
  monitor.handleExternalUpdate("audio.eq[1].gain", Json::Value(1.1)); // yes
  monitor.handleExternalUpdate("audio.eq[2].gain", Json::Value(1.2)); // yes
  monitor.handleExternalUpdate("audio.eq[3].gain", Json::Value(1.3)); // yes
  monitor.handleExternalUpdate("audio.eq[4].gain", Json::Value(1.4)); // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(3));
  EXPECT_EQ(receivedPaths[0], "audio.eq[1].gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq[2].gain");
  EXPECT_EQ(receivedPaths[2], "audio.eq[3].gain");
}

/* Checks combined key wildcard and trailing array wildcard behavior. */
TEST_F(JsonMonitorTest, ComplexPatternMatching) {
  addPatternCallback("audio.*.gain[*]");
  monitor.handleExternalUpdate("audio.eq1.gain[2]", Json::Value(1.5));
  monitor.handleExternalUpdate("audio.comp.gain[0]", Json::Value(2.5));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain[2]");
  EXPECT_EQ(receivedPaths[1], "audio.comp.gain[0]");
}

/* Exercises multiple wildcard positions and validates negative cases. */
TEST_F(JsonMonitorTest, ExtensivePatternMatching) {
  receivedPaths.clear();
  addPatternCallback("system.*.status[*]");
  monitor.handleExternalUpdate("system.cpu.status[0]", Json::Value("OK"));
  monitor.handleExternalUpdate("system.cpu.status[1]", Json::Value("WARN"));
  monitor.handleExternalUpdate("system.gpu.status[0]", Json::Value("FAIL"));
  monitor.handleExternalUpdate("system.memory.status[0]", Json::Value("GOOD"));
  monitor.handleExternalUpdate("system.cpu.status", Json::Value("INVALID")); // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(4));
  EXPECT_EQ(receivedPaths[0], "system.cpu.status[0]");
  EXPECT_EQ(receivedPaths[1], "system.cpu.status[1]");
  EXPECT_EQ(receivedPaths[2], "system.gpu.status[0]");
  EXPECT_EQ(receivedPaths[3], "system.memory.status[0]");

  receivedPaths.clear();
  addPatternCallback("array[1:2].value");
  monitor.handleExternalUpdate("array[0].value", Json::Value(10)); // no
  monitor.handleExternalUpdate("array[1].value", Json::Value(20)); // yes
  monitor.handleExternalUpdate("array[2].value", Json::Value(30)); // yes
  monitor.handleExternalUpdate("array[3].value", Json::Value(40)); // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "array[1].value");
  EXPECT_EQ(receivedPaths[1], "array[2].value");

  receivedPaths.clear();
  addPatternCallback("settings.*.zone.*.speaker");
  monitor.handleExternalUpdate("settings.A.zone.1.speaker", Json::Value("101"));
  monitor.handleExternalUpdate("settings.A.zone.2.speaker", Json::Value("102"));
  monitor.handleExternalUpdate("settings.B.zone.1.speaker", Json::Value("201"));
  monitor.handleExternalUpdate("settings.B.zone.1.speaker.extra",
                               Json::Value("Extra")); // no
  monitor.handleExternalUpdate("settings.B.zone.2", Json::Value("NoRoom"));    // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(3));
  EXPECT_EQ(receivedPaths[0], "settings.A.zone.1.speaker");
  EXPECT_EQ(receivedPaths[1], "settings.A.zone.2.speaker");
  EXPECT_EQ(receivedPaths[2], "settings.B.zone.1.speaker");
}

/* Ensures get() returns existing values and null for missing paths. */
TEST_F(JsonMonitorTest, StateRetrieval) {
  Json::Value state;
  state["volume"] = 0.8;
  monitor.handleExternalUpdate("settings", state);
  Json::Value retrieved = monitor.get("settings.volume");
  EXPECT_DOUBLE_EQ(retrieved.asDouble(), 0.8);
  retrieved = monitor.get("settings.nonexistent");
  EXPECT_TRUE(retrieved.isNull());
}

/* Verifies multiple watchers bound to the same path are all notified once. */
TEST_F(JsonMonitorTest, MultipleWatchersOnSamePath) {
  std::vector<std::string> paths1, paths2;
  monitor.watch("test.path", [&](const std::string &p, const Json::Value &, const Json::Value &) { paths1.push_back(p); });
  monitor.watch("test.path", [&](const std::string &p, const Json::Value &, const Json::Value &) { paths2.push_back(p); });
  monitor.handleExternalUpdate("test.path", Json::Value(1));
  EXPECT_EQ(paths1.size(), static_cast<size_t>(1));
  EXPECT_EQ(paths2.size(), static_cast<size_t>(1));
}

/* Confirms trailing key wildcard matches any child under a concrete prefix. */
TEST_F(JsonMonitorTest, WildcardPattern) {
  addPatternCallback("audio.settings.*");
  monitor.handleExternalUpdate("audio.settings.volume", Json::Value(0.7));
  monitor.handleExternalUpdate("audio.settings.mute", Json::Value(true));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.settings.volume");
  EXPECT_EQ(receivedPaths[1], "audio.settings.mute");
}

/* Validates single-level wildcard between concrete segments. */
TEST_F(JsonMonitorTest, NestedWildcard) {
  addPatternCallback("audio.*.gain");
  monitor.handleExternalUpdate("audio.eq1.gain", Json::Value(1.0));
  monitor.handleExternalUpdate("audio.eq2.gain", Json::Value(2.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq2.gain");
}

/* Ensures complex object updates are delivered to wildcard pattern watchers. */
TEST_F(JsonMonitorTest, NestedWildcardValueChanges) {
  addPatternCallback("settings.audio.*");
  Json::Value state;
  state["low_gain"] = -6.0;
  state["high_gain"] = 6.0;
  monitor.handleExternalUpdate("settings.audio.tone_eq1", state);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "settings.audio.tone_eq1");
  EXPECT_DOUBLE_EQ(newValues[0]["low_gain"].asDouble(), -6.0);
  EXPECT_DOUBLE_EQ(newValues[0]["high_gain"].asDouble(), 6.0);
}

/* Confirms multiple wildcards across multiple levels behave as expected. */
TEST_F(JsonMonitorTest, MultipleWildcards) {
  addPatternCallback("audio.*.eq.*.gain");
  monitor.handleExternalUpdate("audio.ch1.eq.band1.gain", Json::Value(1.0));
  monitor.handleExternalUpdate("audio.ch2.eq.band2.gain", Json::Value(2.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.ch1.eq.band1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.ch2.eq.band2.gain");
}

/* Validates bracket wildcard [*] at the end of a path token. */
TEST_F(JsonMonitorTest, PatternWithBracketWildcard) {
  addPatternCallback("settings.audio.*.*[*]");
  monitor.handleExternalUpdate("settings.audio.ch1.eq[0]", Json::Value(0.8));
  monitor.handleExternalUpdate("settings.audio.ch1.eq[1]", Json::Value(1.2));
  ASSERT_GE(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "settings.audio.ch1.eq[0]");
  EXPECT_EQ(receivedPaths[1], "settings.audio.ch1.eq[1]");
}

/* Ensures notifications occur when a value changes type across updates. */
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

/* Stress a deep concrete path to verify splitting and internal updates. */
TEST_F(JsonMonitorTest, DeepNestedPath) {
  addCallback("a.b.c.d.e.f.g.h.i.j.value");
  monitor.handleExternalUpdate("a.b.c.d.e.f.g.h.i.j.value", Json::Value(1));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "a.b.c.d.e.f.g.h.i.j.value");
}

/* Validates root watchers receive notifications for any concrete update. */
TEST_F(JsonMonitorTest, RootWatcherWithNestedUpdates) {
  addCallback("");
  monitor.handleExternalUpdate("deep.nested.path", Json::Value(1));
  monitor.handleExternalUpdate("another.path", Json::Value(2));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "deep.nested.path");
  EXPECT_EQ(receivedPaths[1], "another.path");
}

/* Ensures both exact and wildcard pattern watchers trigger for same update. */
TEST_F(JsonMonitorTest, ConcurrentPatternAndExactWatchers) {
  addCallback("audio.eq1.gain");
  addPatternCallback("audio.*.gain");
  monitor.handleExternalUpdate("audio.eq1.gain", Json::Value(1.0));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "audio.eq1.gain");
  EXPECT_EQ(receivedPaths[1], "audio.eq1.gain");
}

/* Confirms missing intermediate objects/arrays are created during updates. */
TEST_F(JsonMonitorTest, IntermediateStateCreation) {
  Json::Value value("hello");
  monitor.handleExternalUpdate("new.branch[2].leaf", value);
  Json::Value retrieved = monitor.get("new.branch[2].leaf");
  EXPECT_EQ(retrieved.asString(), "hello");

  Json::Value state = monitor.get("");
  ASSERT_TRUE(state.isObject());
  ASSERT_TRUE(state.isMember("new"));

  Json::Value newObj = state["new"];
  ASSERT_TRUE(newObj.isObject());
  ASSERT_TRUE(newObj.isMember("branch"));

  Json::Value branch = newObj["branch"];
  ASSERT_TRUE(branch.isArray());
  EXPECT_GE(branch.size(), static_cast<Json::ArrayIndex>(3));
  EXPECT_EQ(branch[2]["leaf"].asString(), "hello");
}

/* Validates array auto-expansion when updating an out-of-bounds index. */
TEST_F(JsonMonitorTest, ArrayExpansion) {
  Json::Value value(99);
  monitor.handleExternalUpdate("myArray[4]", value);
  Json::Value retrieved = monitor.get("myArray[4]");
  EXPECT_EQ(retrieved.asInt(), 99);
  Json::Value arrayValue = monitor.get("myArray");
  ASSERT_TRUE(arrayValue.isArray());
  EXPECT_EQ(arrayValue.size(), static_cast<Json::ArrayIndex>(5));
}

/* Covers successful and failing get() scenarios across nested arrays/objects. */
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

  monitor.handleExternalUpdate("", state);

  Json::Value volume = monitor.get("settings.volume");
  EXPECT_DOUBLE_EQ(volume.asDouble(), 0.8);
  Json::Value leftChannel = monitor.get("settings.channels[0]");
  EXPECT_EQ(leftChannel.asString(), "left");
  Json::Value rightChannel = monitor.get("settings.channels[1]");
  EXPECT_EQ(rightChannel.asString(), "right");
  Json::Value nestedValue = monitor.get("settings.nested.values[1]");
  EXPECT_EQ(nestedValue.asInt(), 2);
  Json::Value nameOne = monitor.get("data[0].name");
  EXPECT_EQ(nameOne.asString(), "one");
  Json::Value nameTwo = monitor.get("data[1].name");
  EXPECT_EQ(nameTwo.asString(), "two");

  Json::Value invalidChannel = monitor.get("settings.channels[2]");
  EXPECT_TRUE(invalidChannel.isNull());
  Json::Value nonExistent = monitor.get("settings.nonexistent");
  EXPECT_TRUE(nonExistent.isNull());
  Json::Value invalidData = monitor.get("data[2].name");
  EXPECT_TRUE(invalidData.isNull());
  Json::Value invalidProp = monitor.get("data[0].nonexistent");
  EXPECT_TRUE(invalidProp.isNull());
}

/* Confirms root watcher is called when replacing the entire state. */
TEST_F(JsonMonitorTest, RootWatcherGlobalUpdate) {
  addCallback("");
  Json::Value newState; newState["key"] = "value";
  monitor.handleExternalUpdate("", newState);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(1));
  EXPECT_EQ(receivedPaths[0], "");
  EXPECT_EQ(newValues[0]["key"].asString(), "value");
}

/* Verifies multiple whole-state updates each notify the root watcher. */
TEST_F(JsonMonitorTest, MultipleGlobalUpdatesRootWatcher) {
  addCallback("");
  Json::Value state1; state1["a"] = 1;
  monitor.handleExternalUpdate("", state1);
  Json::Value state2; state2["a"] = 2; state2["b"] = 3;
  monitor.handleExternalUpdate("", state2);
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], ""); EXPECT_EQ(newValues[0]["a"].asInt(), 1);
  EXPECT_EQ(receivedPaths[1], ""); EXPECT_EQ(newValues[1]["a"].asInt(), 2);
  EXPECT_EQ(newValues[1]["b"].asInt(), 3);
}

/* Hammers updates from multiple threads; final values should equal last write. */
TEST_F(JsonMonitorTest, ConcurrentUpdatesThreadSafety) {
  const int numThreads = 10;
  const int numUpdates = 100;
  std::vector<std::thread> threads;

  for (int i = 0; i < numThreads; ++i) {
    threads.emplace_back([this, i]() {
      std::string path = "concurrent.key" + std::to_string(i);
      for (int j = 0; j < numUpdates; ++j) {
        monitor.handleExternalUpdate(path, Json::Value(j));
        std::this_thread::yield();
      }
    });
  }
  for (auto &t : threads) t.join();

  for (int i = 0; i < numThreads; ++i) {
    std::string path = "concurrent.key" + std::to_string(i);
    Json::Value val = monitor.get(path);
    EXPECT_EQ(val.asInt(), numUpdates - 1) << "Expected " << numUpdates - 1 << " at " << path;
  }
}

/* parsePattern should reject non-numeric indices like [foo]. */
TEST(ParsePatternInvalid, NonNumericArrayIndex) {
  EXPECT_THROW(parsePattern("audio.eq[foo].gain"), std::runtime_error);
}

/* parsePattern should reject slices where end is non-numeric. */
TEST(ParsePatternInvalid, InvalidSliceNonNumericEnd) {
  EXPECT_THROW(parsePattern("audio.eq[1:bar].gain"), std::runtime_error);
}

/* parsePattern should reject empty brackets []. */
TEST(ParsePatternInvalid, EmptyBracketContent) {
  EXPECT_THROW(parsePattern("audio.eq[].gain"), std::runtime_error);
}

/* parsePattern now supports multiple bracket groups; verify tokenization. */
TEST(ParsePatternValid, MultipleBracketPairsInTokenNowValid) {
  EXPECT_NO_THROW({
    auto comps = parsePattern("audio.eq[1][2].gain");
    ASSERT_GE(comps.size(), 5u);
    EXPECT_FALSE(comps[0].isArrayAccess);
    EXPECT_EQ(comps[0].key, "audio");
    EXPECT_FALSE(comps[1].isArrayAccess);
    EXPECT_EQ(comps[1].key, "eq");
    EXPECT_TRUE(comps[2].isArrayAccess);
    EXPECT_FALSE(comps[2].isArrayWildcard);
    EXPECT_EQ(comps[2].index, 1);
    EXPECT_TRUE(comps[3].isArrayAccess);
    EXPECT_FALSE(comps[3].isArrayWildcard);
    EXPECT_EQ(comps[3].index, 2);
    EXPECT_FALSE(comps[4].isArrayAccess);
    EXPECT_EQ(comps[4].key, "gain");
  });
}

/* 2D: any cell should match with matrix[*][*]. */
TEST_F(JsonMonitorTest, MatrixAnyCell) {
  addPatternCallback("settings.params.matrix[*][*]");
  monitor.handleExternalUpdate("settings.params.matrix[0][0]", Json::Value(10));
  monitor.handleExternalUpdate("settings.params.matrix[2][7]", Json::Value(42));
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "settings.params.matrix[0][0]");
  EXPECT_EQ(receivedPaths[1], "settings.params.matrix[2][7]");
}

/* 2D: specific row match with matrix[r][*]. */
TEST_F(JsonMonitorTest, MatrixSpecificRow) {
  addPatternCallback("settings.params.matrix[3][*]");
  monitor.handleExternalUpdate("settings.params.matrix[3][0]", Json::Value(1));
  monitor.handleExternalUpdate("settings.params.matrix[3][5]", Json::Value(2));
  monitor.handleExternalUpdate("settings.params.matrix[2][5]", Json::Value(3)); // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "settings.params.matrix[3][0]");
  EXPECT_EQ(receivedPaths[1], "settings.params.matrix[3][5]");
}

/* 2D: specific column match with matrix[*][c]. */
TEST_F(JsonMonitorTest, MatrixSpecificColumn) {
  addPatternCallback("settings.params.matrix[*][7]");
  monitor.handleExternalUpdate("settings.params.matrix[0][7]", Json::Value(11));
  monitor.handleExternalUpdate("settings.params.matrix[5][7]", Json::Value(12));
  monitor.handleExternalUpdate("settings.params.matrix[5][6]", Json::Value(13)); // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_EQ(receivedPaths[0], "settings.params.matrix[0][7]");
  EXPECT_EQ(receivedPaths[1], "settings.params.matrix[5][7]");
}

/* 2D: rectangular region slice matrix[r0:r1][c0:c1] should match interior cells only. */
TEST_F(JsonMonitorTest, MatrixRegionSlice) {
  addPatternCallback("M[1:2][4:5]");
  monitor.handleExternalUpdate("M[0][4]", Json::Value(1)); // no
  monitor.handleExternalUpdate("M[1][4]", Json::Value(2)); // yes
  monitor.handleExternalUpdate("M[1][5]", Json::Value(3)); // yes
  monitor.handleExternalUpdate("M[2][4]", Json::Value(4)); // yes
  monitor.handleExternalUpdate("M[2][5]", Json::Value(5)); // yes
  monitor.handleExternalUpdate("M[3][5]", Json::Value(6)); // no
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(4));
  EXPECT_EQ(receivedPaths[0], "M[1][4]");
  EXPECT_EQ(receivedPaths[1], "M[1][5]");
  EXPECT_EQ(receivedPaths[2], "M[2][4]");
  EXPECT_EQ(receivedPaths[3], "M[2][5]");
}

/* Confirms explicit null updates are not dropped and are delivered to watchers. */
TEST_F(JsonMonitorTest, ExplicitNullUpdateIsObserved) {
  addCallback("x.y[2]");
  monitor.handleExternalUpdate("x.y[2]", Json::Value("value"));
  monitor.handleExternalUpdate("x.y[2]", Json::Value()); // explicit null
  ASSERT_EQ(receivedPaths.size(), static_cast<size_t>(2));
  EXPECT_TRUE(newValues[1].isNull());
}

int main(int argc, char **argv) {
  testing::InitGoogleTest(&argc, argv);
  return RUN_ALL_TESTS();
}
