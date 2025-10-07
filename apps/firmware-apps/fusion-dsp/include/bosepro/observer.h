#pragma once

#include <arpa/inet.h>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstring>
#include <curl/curl.h>
#include <fcntl.h>
#include <functional>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <json/json.h>
#include <mutex>
#include <netinet/in.h>
#include <poll.h>
#include <spdlog/spdlog.h>
#include <sstream>
#include <stdexcept>
#include <string>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>
#include <vector>

/**
 * @brief Represents a component of a JSON path.
 *
 * A path component may be a key (when accessing an object) or an array index.
 */
struct PathComponent {
  std::string key;    ///< The object key.
  int arrayIndex;     ///< Valid only if isArrayAccess is true.
  bool isArrayAccess; ///< True if this component represents an array index.

  explicit PathComponent(const std::string &k)
      : key(k), arrayIndex(-1), isArrayAccess(false) {}

  explicit PathComponent(int idx)
      : key(""), arrayIndex(idx), isArrayAccess(true) {}
};

/**
 * @brief Represents one component of a subscription pattern.
 *
 * For keys:
 *   - key == "*" means match any key.
 *
 * For array accesses:
 *   - isArrayAccess is true.
 *   - isArrayWildcard true means match any index.
 *   - isSlice true means that a slice is specified (with sliceStart and
 *     sliceEnd).
 *   - Otherwise, index holds the required numeric index.
 */
struct PatternComponent {
  std::string key; ///< Valid if not an array access.
  bool isArrayAccess =
      false; ///< True if this token represents an array access.
  bool isArrayWildcard = false; ///< True if the array index is a wildcard.
  bool isSlice = false;         ///< True if a slice is specified.
  int index = -1;               ///< Used for a literal numeric index.
  int sliceStart = 0;           ///< Inclusive lower bound for a slice.
  int sliceEnd = 0;             ///< Inclusive upper bound for a slice.
};

/**
 * @brief Parse a subscription pattern string into components.
 *
 * Examples:
 *   - "settings.audio.*.*.[*]" splits into:
 *         "settings", "audio", "*" , "*" , "[*]"
 *   - "gain[*]" is treated as key "gain" plus an array wildcard.
 *   - "audio.eq[1:3].gain" is parsed so that "[1:3]" is recognized as a slice.
 *
 * @param pattern The pattern string.
 * @return A vector of PatternComponent objects.
 * @throws std::runtime_error on invalid syntax.
 */
inline std::vector<PatternComponent> parsePattern(const std::string &pattern) {
  std::vector<PatternComponent> components;
  std::istringstream iss(pattern);
  std::string token;

  auto pushKey = [&](const std::string& key) {
    if (!key.empty()) {
      PatternComponent pc;
      pc.key = key;
      components.push_back(pc);
    }
  };

  auto parseBracket = [&](const std::string& inside, const std::string& wholeToken) {
    PatternComponent pcArr;
    pcArr.isArrayAccess = true;

    if (inside == "*") {
      pcArr.isArrayWildcard = true;
    } else if (inside.find(':') != std::string::npos) {
      // Slice
      pcArr.isSlice = true;
      const size_t colonPos = inside.find(':');
      const std::string startStr = inside.substr(0, colonPos);
      const std::string endStr   = inside.substr(colonPos + 1);
      try {
        pcArr.sliceStart = std::stoi(startStr);
        pcArr.sliceEnd   = std::stoi(endStr);
      } catch (...) {
        throw std::runtime_error("Invalid slice indices in pattern: " + wholeToken);
      }
    } else {
      // Literal numeric index
      for (char c : inside) {
        if (!std::isdigit(static_cast<unsigned char>(c))) {
          throw std::runtime_error("Invalid array index in pattern: " + wholeToken);
        }
      }
      try {
        pcArr.index = std::stoi(inside);
      } catch (...) {
        throw std::runtime_error("Invalid array index in pattern: " + wholeToken);
      }
    }

    components.push_back(pcArr);
  };

  // Split the pattern on '.'
  while (std::getline(iss, token, '.')) {
    if (token.empty()) continue;

    // Special-case token that is exactly "[*]"
    if (token == "[*]") {
      PatternComponent pc;
      pc.isArrayAccess = true;
      pc.isArrayWildcard = true;
      components.push_back(pc);
      continue;
    }

    // General case: key followed by zero or more bracket groups
    // e.g., "matrix[*][2]" -> key "matrix", then two array components
    size_t pos = 0;

    // Extract optional key prefix (everything before the first '[')
    size_t firstBracket = token.find('[');
    if (firstBracket == std::string::npos) {
      // Pure key token
      pushKey(token);
      continue;
    }

    // Push the key (if any)
    std::string keyPart = token.substr(0, firstBracket);
    pushKey(keyPart);
    pos = firstBracket;

    // Parse a chain of bracket groups
    while (pos < token.size()) {
      if (token[pos] != '[') {
        throw std::runtime_error("Unexpected character in pattern token: " + token);
      }
      size_t close = token.find(']', pos);
      if (close == std::string::npos) {
        throw std::runtime_error("Unclosed '[' in pattern token: " + token);
      }
      std::string inside = token.substr(pos + 1, close - (pos + 1));
      parseBracket(inside, token);
      pos = close + 1;
    }
  }

  return components;
}

/**
 * @brief Retrieves a JSON value by traversing a JSON tree using a vector of
 * path components.
 *
 * @param root The root JSON value to traverse.
 * @param pathParts A vector of PathComponent specifying the path.
 * @return The JSON value at the given path or Json::nullValue if not found.
 */
inline Json::Value
getJsonValueAtPath(const Json::Value &root,
                   const std::vector<PathComponent> &pathParts) {
  const Json::Value *current = &root;
  for (const auto &part : pathParts) {
    if (part.isArrayAccess) {
      if (!current->isArray()) {
        SPDLOG_DEBUG("Expected an array but found non-array at index: {}",
                     part.arrayIndex);
        return Json::nullValue;
      }
      if (part.arrayIndex >= static_cast<int>(current->size())) {
        SPDLOG_DEBUG("Array index {} is out of bounds (size: {})",
                     part.arrayIndex, current->size());
        return Json::nullValue;
      }
      current = &((*current)[part.arrayIndex]);
    } else {
      if (!current->isObject() || !current->isMember(part.key)) {
        SPDLOG_DEBUG("Key '{}' not found in object", part.key);
        return Json::nullValue;
      }
      current = &((*current)[part.key]);
    }
  }
  return *current;
}

/**
 * @brief Like getJsonValueAtPath but indicates whether the path existed.
 *
 * Returns true if the path is present (even if value is explicit JSON null).
 */
inline bool tryGetJsonValueAtPath(const Json::Value &root,
                                  const std::vector<PathComponent> &pathParts,
                                  Json::Value *out) {
  const Json::Value *current = &root;
  for (const auto &part : pathParts) {
    if (part.isArrayAccess) {
      if (!current->isArray()) {
        SPDLOG_DEBUG("Expected an array at index: {}", part.arrayIndex);
        return false;
      }
      if (part.arrayIndex < 0 ||
          part.arrayIndex >= static_cast<int>(current->size())) {
        SPDLOG_DEBUG("Array index {} out of bounds (size: {})",
                     part.arrayIndex, current->size());
        return false;
      }
      current = &((*current)[part.arrayIndex]);
    } else {
      if (!current->isObject() || !current->isMember(part.key)) {
        SPDLOG_DEBUG("Missing key: {}", part.key);
        return false;
      }
      current = &((*current)[part.key]);
    }
  }
  if (out)
    *out = *current;
  return true;
}

/**
 * @brief Matches a concrete update path against a subscription pattern.
 *
 * @param pattern The parsed subscription pattern.
 * @param path The concrete update path (as a series of PathComponent).
 * @return true if the update path matches the subscription pattern.
 */
inline bool patternMatchesPath(const std::vector<PatternComponent> &pattern,
                               const std::vector<PathComponent> &path) {
  size_t pIdx = 0, pathIdx = 0;
  while (pIdx < pattern.size() && pathIdx < path.size()) {
    const auto &pcomp = pattern[pIdx];
    const auto &comp = path[pathIdx];

    if (pcomp.isArrayAccess) {
      if (!comp.isArrayAccess)
        return false;
      if (pcomp.isSlice) {
        if (comp.arrayIndex < pcomp.sliceStart ||
            comp.arrayIndex > pcomp.sliceEnd)
          return false;
      } else if (!pcomp.isArrayWildcard) {
        if (pcomp.index != comp.arrayIndex)
          return false;
      }
      ++pIdx;
      ++pathIdx;
    } else {
      if (pcomp.key != "*" && pcomp.key != comp.key)
        return false;
      ++pIdx;
      ++pathIdx;
    }
  }
  return (pIdx == pattern.size() && pathIdx == path.size());
}

// -----------------------------------------------------------------------------
// Class: JsonMonitor
// -----------------------------------------------------------------------------

/**
 * @brief Monitors and manages JSON data with support for path-based access and
 * change notifications.
 */
class JsonMonitor {
public:
  /// Type definition for change notification callbacks.
  using ChangeCallback = std::function<void(
      const std::string &, const Json::Value &, const Json::Value &)>;

  /**
   * @brief Constructs a JsonMonitor with an optional initial JSON state.
   * @param initial_data The initial JSON state (default is an empty object).
   */
  JsonMonitor(Json::Value initial_data = Json::objectValue)
      : data_(initial_data) {}

  /**
   * @brief Register a callback to be notified when a concrete path is updated.
   *
   * @param path The concrete JSON path to watch. An empty string indicates the
   * root.
   * @param callback The function to call when the specified path is updated.
   */
  void watch(const std::string &path, ChangeCallback callback) {
    std::lock_guard<std::mutex> lk(watchers_mutex_);
    if (path.empty()) {
      root_watchers_.push_back(callback);
    } else {
      watchers_[path].push_back(callback);
    }
  }

  /**
   * @brief Register a callback to be notified when a subscription pattern is
   * updated.
   *
   * @param pattern The subscription pattern string (may include wildcards).
   * @param callback The function to call when an update matching the pattern
   * occurs.
   */
  void watchPattern(const std::string &pattern, ChangeCallback callback) {
    std::lock_guard<std::mutex> lk(watchers_mutex_);
    pattern_watchers_[pattern].push_back(callback);
  }

  void watchMatrixCell(JsonMonitor& jm, const std::string& base, int r, int c,
                       JsonMonitor::ChangeCallback cb) {
        jm.watch(base + "[" + std::to_string(r) + "][" + std::to_string(c) + "]", std::move(cb));
  }

  void watchMatrixRow(JsonMonitor& jm, const std::string& base, int r,
                      JsonMonitor::ChangeCallback cb) {
    jm.watchPattern(base + "[" + std::to_string(r) + "][*]", std::move(cb));
  }

  void watchMatrixCol(JsonMonitor& jm, const std::string& base, int c,
                      JsonMonitor::ChangeCallback cb) {
    jm.watchPattern(base + "[*][" + std::to_string(c) + "]", std::move(cb));
  }

  void watchMatrixRegion(JsonMonitor& jm, const std::string& base,
    int r0, int r1, int c0, int c1,
                        JsonMonitor::ChangeCallback cb) {
    jm.watchPattern(base + "[" + std::to_string(r0) + ":" + std::to_string(r1) + "]"
                          + "[" + std::to_string(c0) + ":" + std::to_string(c1) + "]",
                    std::move(cb));
  }

  /**
   * @brief Retrieve the JSON value at a given path.
   *
   * @param path The concrete JSON path (dot and bracket notation).
   * @return The JSON value at the path, or null if the path is invalid.
   */
  Json::Value get(const std::string &path) const {
    std::lock_guard<std::mutex> lock(state_mutex_);
    if (path.empty())
      return data_;

    std::vector<PathComponent> path_parts = splitPath(path);
    const Json::Value *current = &data_;
    for (const auto &part : path_parts) {
      if (part.isArrayAccess) {
        if (!current->isArray() ||
            part.arrayIndex >= static_cast<int>(current->size()))
          return Json::nullValue;
        current = &((*current)[part.arrayIndex]);
      } else {
        if (!current->isObject() || !current->isMember(part.key))
          return Json::nullValue;
        current = &((*current)[part.key]);
      }
    }
    return *current;
  }

  /**
   * @brief Splits a JSON path string into its component parts.
   *
   * The path is expected in a dot/bracket notation (e.g., "settings.audio[0]").
   *
   * @param path The JSON path string.
   * @return A vector of PathComponent representing the path.
   */
  std::vector<PathComponent> splitPath(const std::string &path) const {
    std::vector<PathComponent> parts;
    if (path.empty())
      return parts;
    std::string key;
    std::string arrayPart;
    bool inArray = false;
    for (size_t i = 0; i < path.length(); ++i) {
      const char c = path[i];
      if (c == '.') {
        if (!key.empty()) {
          parts.push_back(PathComponent(key));
          key.clear();
        }
      } else if (c == '[') {
        inArray = true;
        if (!key.empty()) {
          parts.push_back(PathComponent(key));
          key.clear();
        }
      } else if (c == ']') {
        inArray = false;
        try {
          int index = std::stoi(arrayPart);
          if (index < 0)
            return std::vector<PathComponent>(); // invalid
          parts.push_back(PathComponent(index));
        } catch (...) {
          return std::vector<PathComponent>(); // invalid index
        }
        arrayPart.clear();
      } else if (inArray) {
        arrayPart += c;
      } else {
        key += c;
      }
    }

    if (!key.empty()) {
      parts.push_back(PathComponent(key));
    }

#if 0
    if (verbose_) {
      std::cout << "Parsed concrete path: ";
      for (const auto &p : parts) {
        if (p.isArrayAccess)
          std::cout << "[" << p.arrayIndex << "] ";
        else
          std::cout << p.key << " ";
      }
      std::cout << std::endl;
    }
#endif
    return parts;
  }

  /**
   * @brief Process an external JSON update for a given path.
   *
   * Updates internal state and notifies registered watchers (exact, pattern, root)
   * if the state has changed.
   *
   * @param path The concrete JSON path that has been updated.
   * @param new_state The new JSON state for that path.
   */
  void handleExternalUpdate(const std::string &path,
                            const Json::Value &new_state) {
    // Mutate state and compute diffs under state_mutex_
    Json::Value oldData, newData, oldValue, newValue;
    {
      std::lock_guard<std::mutex> slk(state_mutex_);
      SPDLOG_DEBUG("Received update for path: {}", path);

      oldData = data_;
      updateInternalState(path, new_state);
      newData = data_;

      if (oldData == newData) {
        SPDLOG_DEBUG("No change detected for path: {}", path);
        return;
      }

      oldValue = extractValue(oldData, path);
      newValue = extractValue(newData, path);
    }

    // Collect callbacks under watchers_mutex_
    std::vector<ChangeCallback> exact, patternCbs, roots;
    std::vector<PathComponent> splitP = splitPath(path);
    {
      std::lock_guard<std::mutex> wlk(watchers_mutex_);
      if (auto it = watchers_.find(path); it != watchers_.end())
        exact = it->second;

      for (const auto &kv : pattern_watchers_) {
        const auto &subscription = kv.first;
        const auto &callbacks = kv.second;
        const auto &tokens = getParsedPattern(subscription);
        if (patternMatchesPath(tokens, splitP)) {
          patternCbs.insert(patternCbs.end(), callbacks.begin(), callbacks.end());
        }
      }
      roots = root_watchers_;
    }

    if ((!exact.empty() || !patternCbs.empty() || !roots.empty())) {
      SPDLOG_DEBUG("Dispatching callbacks for: {}", path);
    }

    for (const auto &cb : exact) {
        cb(path, oldValue, newValue);
    }

    for (const auto &cb : patternCbs) {
        cb(path, oldValue, newValue);
    }

    for (const auto &cb : roots) {
        cb(path, oldValue, newValue);
    }
  }

  /**
   * @brief Retrieves the parsed pattern for the given subscription, using a cache.
   */
  const std::vector<PatternComponent> &
  getParsedPattern(const std::string &pattern) {
    std::lock_guard<std::mutex> lock(cache_mutex_);
    const auto it = parsedPatternCache_.find(pattern);
    if (it != parsedPatternCache_.end()) {
      return it->second;
    }

    parsedPatternCache_[pattern] = parsePattern(pattern);
    return parsedPatternCache_[pattern];
  }


private:
  /**
   * @brief Updates the internal JSON state at a given path.
   */
  void updateInternalState(const std::string &path,
                           const Json::Value &new_state) {
    if (path.empty()) {
      data_ = new_state;
      return;
    }
    std::vector<PathComponent> path_parts = splitPath(path);
    Json::Value *current = &data_;
    for (size_t i = 0; i < path_parts.size() - 1; ++i) {
      const auto &part = path_parts[i];
      if (part.isArrayAccess) {
        if (!current->isArray())
          *current = Json::arrayValue;
        while (current->size() <= static_cast<size_t>(part.arrayIndex))
          current->append(Json::Value());
        current = &((*current)[part.arrayIndex]);
      } else {
        bool nextIsArray =
            (i + 1 < path_parts.size() && path_parts[i + 1].isArrayAccess);
        if (!current->isObject())
          *current = Json::objectValue;
        if (!current->isMember(part.key)) {
          (*current)[part.key] =
              nextIsArray ? Json::arrayValue : Json::objectValue;
        }
        current = &((*current)[part.key]);
      }
    }
    // Update final token.
    const auto &last_part = path_parts.back();
    if (last_part.isArrayAccess) {
      if (!current->isArray())
        *current = Json::arrayValue;
      while (current->size() <= static_cast<size_t>(last_part.arrayIndex))
        current->append(Json::Value());
      (*current)[last_part.arrayIndex] = new_state;
    } else {
      if (!current->isObject())
        *current = Json::objectValue;
      (*current)[last_part.key] = new_state;
    }
  }

  /**
   * @brief Extracts the JSON value from a state at the specified path.
   */
  Json::Value extractValue(const Json::Value &state,
                           const std::string &path) const {
    if (path.empty())
      return state;
    std::vector<PathComponent> parts = splitPath(path);
    return getJsonValueAtPath(state, parts);
  }

  mutable std::mutex state_mutex_;
  mutable std::mutex watchers_mutex_;
  Json::Value data_;
  std::unordered_map<std::string, std::vector<ChangeCallback>> watchers_;
  std::unordered_map<std::string, std::vector<ChangeCallback>>
      pattern_watchers_;
  std::vector<ChangeCallback> root_watchers_;

  // Cache for parsed subscription patterns.
  std::unordered_map<std::string, std::vector<PatternComponent>>
      parsedPatternCache_;
  mutable std::mutex cache_mutex_;
};

/**
 * @brief A RAII wrapper for a UDP socket.
 */
class UDPSocket {
public:
  UDPSocket(int domain, int type, int protocol)
      : sockfd_(::socket(domain, type, protocol)) {
    if (sockfd_ < 0)
      throw std::runtime_error("Failed to create socket");
  }

  ~UDPSocket() {
    if (sockfd_ >= 0) {
      ::close(sockfd_);
    }
  }

  int get() const { return sockfd_; }

  UDPSocket(const UDPSocket &) = delete;
  UDPSocket &operator=(const UDPSocket &) = delete;

private:
  int sockfd_;
};

/**
 * @brief Monitors remote JSON values via UDP and updates a local JsonMonitor.
 */
class UDPValueMonitor {
public:
  UDPValueMonitor(const std::string &serverIP, int port,
                  const std::vector<std::string> &targetPaths,
                  void (*updateHandler)(const std::string &))
      : targetPaths_(targetPaths), updateHandler_(updateHandler),
        jsonMonitor_(Json::objectValue), device_id(""), fixed_device_id(false) {
    const int sockfd = udpSocket_.get();

    // Set up the server address.
    std::memset(&serverAddr_, 0, sizeof(serverAddr_));
    serverAddr_.sin_family = AF_INET;
    serverAddr_.sin_port = htons(port);
    if (inet_pton(AF_INET, serverIP.c_str(), &serverAddr_.sin_addr) <= 0)
      throw std::runtime_error("Invalid server address: " + serverIP);

    // Bind the socket to any available local port.
    sockaddr_in clientAddr;
    std::memset(&clientAddr, 0, sizeof(clientAddr));
    clientAddr.sin_family = AF_INET;
    clientAddr.sin_addr.s_addr = INADDR_ANY;
    clientAddr.sin_port = htons(0);
    if (bind(sockfd, reinterpret_cast<sockaddr *>(&clientAddr),
             sizeof(clientAddr)) < 0)
      throw std::runtime_error("Failed to bind socket: " +
                               std::string(strerror(errno)));

    // Set socket non-blocking with error checks.
    int flags = fcntl(sockfd, F_GETFL, 0);
    if (flags == -1) {
      throw std::runtime_error(std::string("fcntl(F_GETFL) failed: ") +
                               strerror(errno));
    }
    if (fcntl(sockfd, F_SETFL, flags | O_NONBLOCK) == -1) {
      throw std::runtime_error(std::string("fcntl(F_SETFL) failed: ") +
                               strerror(errno));
    }

    // Register watchers.
    for (const auto &path : targetPaths_) {
      if (path.find('*') != std::string::npos) {
        jsonMonitor_.watchPattern(path, [this](const std::string &p,
                                               const Json::Value &old_val,
                                               const Json::Value &new_val) {
          handleValueChange(p, old_val, new_val);
        });
      } else {
        jsonMonitor_.watch(path, [this](const std::string &p,
                                        const Json::Value &old_val,
                                        const Json::Value &new_val) {
          handleValueChange(p, old_val, new_val);
        });
      }
    }
    requestInitialState(serverAddr_);
    receiveThread_ = std::thread(&UDPValueMonitor::receiveLoop, this);
  }

  ~UDPValueMonitor() { stop(); }

  void stop() {
    running_ = false;
    if (receiveThread_.joinable()) {
      receiveThread_.join();
    }
  }

  Json::Value get(const std::string &path) const { return jsonMonitor_.get(path); }

  /**
   * @brief Sets the device ID for filtering updates.
   *
   * This ID is used to filter updates for specific devices in the JSON data.
   *
   * @param id The device ID to set.
   */
  void setDeviceID(const std::string &id) {
    device_id = id;
    fixed_device_id = true;
  }

private:
  std::string getTimestamp() const {
    auto now = std::chrono::system_clock::now();
    auto now_c = std::chrono::system_clock::to_time_t(now);
    struct tm local_tm;
    localtime_r(&now_c, &local_tm);
    std::stringstream ss;
    ss << std::put_time(&local_tm, "%H:%M:%S");
    return ss.str();
  }

  static size_t curlWriteCallback(void *contents, size_t size,
                                 size_t nmemb, std::string *userp) {
    size_t totalSize = size * nmemb;
    userp->append(static_cast<char *>(contents), totalSize);
    return totalSize;
  }

  void handleValueChange(const std::string &path, const Json::Value &old_val,
                         const Json::Value &new_val) {
    std::vector<PathComponent> path_parts = jsonMonitor_.splitPath(path);
    std::string message;

    if (path_parts[0].key == "settings") {
      if (old_val != new_val) {
        message = "{ \"target\": \"" + path_parts[2].key + "\""
            + ", \"name\": \"" + path_parts[3].key + "\""
            + ((path_parts.size() > 4 && path_parts[4].isArrayAccess)
               ? ", \"index\": ["
                   + std::to_string(path_parts[4].arrayIndex + 1)
                   + ((path_parts.size() > 5 && path_parts[5].isArrayAccess)
                     ? ", "
                       + std::to_string(path_parts[5].arrayIndex + 1) + "]"
                     : "]")
               : "")
            + ", \"value\": " + (new_val.isString() ? "\"" : "")
            + new_val.asString() + (new_val.isString() ? "\"" : "") + " }";

        updateHandler_(message);
      }
    }
    else if (path_parts[0].key == "fw_static_config") {
      message = "{ \"target\": \"session\", \"name\": \"destroy_all_periodic_tasks\" }";
      updateHandler_(message);

      std::ofstream fw_config("/tmp/fw_config.json");
      fw_config << new_val;
      fw_config.close();

      message = "{ \"target\": \"session\", \"name\": \"create_periodic_task\", \"value\": \"/tmp/fw_config.json\" }";
      updateHandler_(message);
    }
    else if (path_parts[0].key == "devices") {
      SPDLOG_DEBUG("Processing devices {} {}", fixed_device_id, device_id);
      if (!fixed_device_id) {
        CURL *curl = curl_easy_init();
        CURLcode res;
        std::string response;

        if (curl) {
          curl_easy_setopt(curl, CURLOPT_URL, "http://localhost:9090/device");
          curl_easy_setopt(curl, CURLOPT_WRITEFUNCTION, curlWriteCallback);
          curl_easy_setopt(curl, CURLOPT_WRITEDATA, &response);
          res = curl_easy_perform(curl);
          if (res != CURLE_OK) {
            SPDLOG_WARN("Failed to retrieve device id: {}",
                        curl_easy_strerror(res));
          }
          else {
            Json::CharReaderBuilder readerBuilder;
            Json::Value jsonResponse;
            std::istringstream iss(response);
            std::string errs;

            if (!Json::parseFromStream(readerBuilder, iss, &jsonResponse, &errs)) {
              SPDLOG_WARN("Failed to parse device response: {}", errs);
            } else {
              device_id = jsonResponse["id"].asString();
              SPDLOG_DEBUG("Device ID set to: {}", device_id);
            }
          }
          curl_easy_cleanup(curl);
        }
      }

      if (new_val["id"] == device_id)
      {
        message = "{ \"target\": \"session\", \"name\": \"destroy_all_audio_tasks\" }";
        updateHandler_(message);

        std::ofstream dsp_config("/tmp/dsp_config.json");
        dsp_config << new_val["dsp_static_config"];
        dsp_config.close();

        message = "{ \"target\": \"session\", \"name\": \"create_audio_task\", \"value\": \"/tmp/dsp_config.json\" }";
        updateHandler_(message);
      }
    }
  }

  void requestInitialState(const sockaddr_in &serverAddr) {
    Json::Value message;
    message["action"] = "get";
    Json::StreamWriterBuilder writerBuilder;
    std::string jsonStr = Json::writeString(writerBuilder, message);
    ssize_t sent = sendto(udpSocket_.get(), jsonStr.c_str(), jsonStr.length(),
                          0, reinterpret_cast<const sockaddr *>(&serverAddr),
                          sizeof(serverAddr));
    if (sent < 0) {
      SPDLOG_WARN("Failed to send initial state request: {}",
                  std::string(strerror(errno)));
    }
    receivedInitialState_ = false;
  }

  Json::Value getValueAtPath(const Json::Value &root,
                             const std::vector<PathComponent> &pathParts) {
    return getJsonValueAtPath(root, pathParts);
  }

  std::string constructPath(const std::vector<PathComponent> &path) const {
    std::ostringstream oss;
    for (size_t i = 0; i < path.size(); ++i) {
      if (path[i].isArrayAccess) {
        oss << "[" << path[i].arrayIndex << "]";
      } else {
        if (i > 0)
          oss << ".";
        oss << path[i].key;
      }
    }
    return oss.str();
  }

  void traverseAndUpdate(const Json::Value &node,
                         std::vector<PathComponent> &currentPath,
                         const std::vector<PatternComponent> &parsedPattern) {
    if (patternMatchesPath(parsedPattern, currentPath)) {
      const std::string pathStr = constructPath(currentPath);
      jsonMonitor_.handleExternalUpdate(pathStr, node);
    }
    if (node.isObject()) {
      for (const auto &key : node.getMemberNames()) {
        currentPath.push_back(PathComponent(key));
        traverseAndUpdate(node[key], currentPath, parsedPattern);
        currentPath.pop_back();
      }
    } else if (node.isArray()) {
      for (Json::ArrayIndex i = 0; i < node.size(); ++i) {
        currentPath.push_back(PathComponent(static_cast<int>(i)));
        traverseAndUpdate(node[i], currentPath, parsedPattern);
        currentPath.pop_back();
      }
    }
  }

  void handleUpdateMessage(const Json::Value &update) {
    SPDLOG_TRACE("Received update: {}", update.toStyledString());

    for (const auto &path : targetPaths_) {
      if (path.find('*') != std::string::npos) {
        const auto &parsedPattern = jsonMonitor_.getParsedPattern(path);
        std::vector<PathComponent> currentPath;
        traverseAndUpdate(update, currentPath, parsedPattern);
      } else {
        auto path_parts = jsonMonitor_.splitPath(path);
        Json::Value value;
        if (tryGetJsonValueAtPath(update, path_parts, &value)) {
          SPDLOG_DEBUG("Detected value at {}: {}", path, value.toStyledString());
          jsonMonitor_.handleExternalUpdate(path, value);
        } else {
          SPDLOG_DEBUG("No value found at path: {}", path);
        }
      }
    }
  }

  void receiveLoop() {
    pollfd pfd;
    pfd.fd = udpSocket_.get();
    pfd.events = POLLIN;
    constexpr size_t BUFFER_SIZE = 65535;
    char buffer[BUFFER_SIZE];
    sockaddr_in senderAddr;
    socklen_t senderLen = sizeof(senderAddr);

    while (running_) {
      const int pollResult = poll(&pfd, 1, 1000);
      if (pollResult < 0) {
        if (errno == EINTR)
          continue;
        std::cerr << "Poll error: " << strerror(errno) << std::endl;
        break;
      } else if (pollResult == 0) {
        if (!receivedInitialState_)
          requestInitialState(serverAddr_);
        continue;
      }

      if (pfd.revents & POLLIN) {
        senderLen = sizeof(senderAddr);
        const ssize_t received =
            recvfrom(udpSocket_.get(), buffer, BUFFER_SIZE - 1, 0,
                     reinterpret_cast<sockaddr *>(&senderAddr), &senderLen);
        if (received < 0) {
          if (errno == EWOULDBLOCK || errno == EAGAIN)
            continue;
          std::cerr << "Error receiving data: " << strerror(errno) << std::endl;
          continue;
        }
        // Optional: filter unexpected senders.
        if (senderAddr.sin_addr.s_addr != serverAddr_.sin_addr.s_addr) {
          SPDLOG_DEBUG("Ignoring datagram from unexpected sender");
          continue;
        }
        buffer[received] = '\0';
        SPDLOG_TRACE("Received data: {}", buffer);

        Json::Value response;
        Json::CharReaderBuilder readerBuilder;
        std::istringstream iss(buffer);
        std::string errs;
        if (Json::parseFromStream(readerBuilder, iss, &response, &errs)) {
          if (response.isMember("status") && response.isMember("data")) {
            SPDLOG_DEBUG("Received initial state response.");
            receivedInitialState_ = true;
            handleUpdateMessage(response["data"]);
          } else {
            SPDLOG_DEBUG("Processing update message.");
            handleUpdateMessage(response);
          }
        } else {
          SPDLOG_DEBUG("Failed to parse JSON: {}", errs);
        }
      }
    }
  }

  UDPSocket udpSocket_{AF_INET, SOCK_DGRAM, 0};
  std::atomic<bool> running_{true};
  std::thread receiveThread_;
  std::vector<std::string> targetPaths_;
  void (*updateHandler_)(const std::string &);
  JsonMonitor jsonMonitor_;
  sockaddr_in serverAddr_{};
  std::string device_id;
  bool fixed_device_id;
  bool receivedInitialState_{false};
};
