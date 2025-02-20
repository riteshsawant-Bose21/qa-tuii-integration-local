#include <arpa/inet.h>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstring>
#include <fcntl.h>
#include <functional>
#include <fstream>
#include <iomanip>
#include <iostream>
#include <json/json.h>
#include <mutex>
#include <netinet/in.h>
#include <poll.h>
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
 * sliceEnd).
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

  // Split on '.'
  while (std::getline(iss, token, '.')) {
    if (token.empty())
      continue;

    // Token exactly "[*]" means “any array element”
    if (token == "[*]") {
      PatternComponent pc;
      pc.isArrayAccess = true;
      pc.isArrayWildcard = true;
      components.push_back(pc);
      continue;
    }

    // If token contains '[' and ends with ']'
    size_t bracketPos = token.find('[');
    if (bracketPos != std::string::npos && token.back() == ']') {
      // Add any key portion before '['.
      const std::string keyPart = token.substr(0, bracketPos);
      if (!keyPart.empty()) {
        PatternComponent pc;
        pc.key = keyPart;
        components.push_back(pc);
      }

      // Process the bracketed part.
      const std::string inside =
          token.substr(bracketPos + 1, token.size() - bracketPos - 2);
      PatternComponent pcArr;
      pcArr.isArrayAccess = true;
      if (inside == "*") {
        pcArr.isArrayWildcard = true;
      } else if (inside.find(':') != std::string::npos) {
        // Slice pattern.
        pcArr.isSlice = true;
        const size_t colonPos = inside.find(':');
        const std::string startStr = inside.substr(0, colonPos);
        const std::string endStr = inside.substr(colonPos + 1);
        try {
          pcArr.sliceStart = std::stoi(startStr);
          pcArr.sliceEnd = std::stoi(endStr);
        } catch (...) {
          throw std::runtime_error("Invalid slice indices in pattern: " +
                                   token);
        }
      } else {
        // Literal numeric index.
        for (char c : inside) {
          if (!std::isdigit(c))
            throw std::runtime_error("Invalid array index in pattern: " +
                                     token);
        }
        try {
          pcArr.index = std::stoi(inside);
        } catch (const std::exception &) {
          throw std::runtime_error("Invalid array index in pattern: " + token);
        }
      }
      components.push_back(pcArr);
    } else {
      // Simple key token.
      PatternComponent pc;
      pc.key = token;
      components.push_back(pc);
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
 * @param verbose If true, prints error messages.
 * @return The JSON value at the given path or Json::nullValue if not found.
 */
inline Json::Value
getJsonValueAtPath(const Json::Value &root,
                   const std::vector<PathComponent> &pathParts,
                   bool verbose = false) {
  const Json::Value *current = &root;
  for (const auto &part : pathParts) {
    if (part.isArrayAccess) {
      if (!current->isArray()) {
        if (verbose)
          std::cout << "Expected an array but found non-array at index: "
                    << part.arrayIndex << std::endl;
        return Json::nullValue;
      }
      if (part.arrayIndex >= static_cast<int>(current->size())) {
        if (verbose)
          std::cout << "Array index " << part.arrayIndex
                    << " is out of bounds (size: " << current->size() << ")"
                    << std::endl;
        return Json::nullValue;
      }
      current = &((*current)[part.arrayIndex]);
    } else {
      if (!current->isObject() || !current->isMember(part.key)) {
        if (verbose)
          std::cout << "Key not found in object: " << part.key << std::endl;
        return Json::nullValue;
      }
      current = &((*current)[part.key]);
    }
  }
  return *current;
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
   * @param verbose If true, enables verbose logging.
   */
  JsonMonitor(Json::Value initial_data = Json::objectValue,
              bool verbose = false)
      : data_(initial_data), verbose_(verbose) {}

  /**
   * @brief Register a callback to be notified when a concrete path is updated.
   *
   * @param path The concrete JSON path to watch. An empty string indicates the
   * root.
   * @param callback The function to call when the specified path is updated.
   */
  void watch(const std::string &path, ChangeCallback callback) {
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
    pattern_watchers_[pattern].push_back(callback);
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
    return parts;
  }

  /**
   * @brief Process an external JSON update for a given path.
   *
   * This function updates the internal state and notifies any registered
   * watchers (exact, pattern, and root watchers) if the state has changed.
   *
   * @param path The concrete JSON path that has been updated.
   * @param new_state The new JSON state for that path.
   */
  void handleExternalUpdate(const std::string &path,
                            const Json::Value &new_state) {
    std::lock_guard<std::mutex> lock(state_mutex_);

    if (verbose_) {
      log("Received update for path: " + path);
    }

    Json::Value oldData = data_;
    updateInternalState(path, new_state);
    Json::Value newData = data_;

    if (oldData == newData) {
      if (verbose_) {
        log("No change detected for path: " + path);
      }
      return;
    }

    const Json::Value oldValue = extractValue(oldData, path);
    const Json::Value newValue = extractValue(newData, path);

    // Notify exact-match watchers.
    const auto it = watchers_.find(path);
    if (it != watchers_.end()) {
      if (verbose_)
        log("Triggering exact watchers for: " + path);
      for (const auto &callback : it->second)
        callback(path, oldValue, newValue);
    }

    // Notify pattern watchers.
    for (const auto &[subscription, callbacks] : pattern_watchers_) {
      const auto &tokens = getParsedPattern(subscription);
      std::vector<PathComponent> splitP = splitPath(path);
      if (patternMatchesPath(tokens, splitP)) {
        for (const auto &callback : callbacks)
          callback(path, oldValue, newValue);
      }
    }

    // Notify root watchers.
    for (const auto &callback : root_watchers_) {
      if (verbose_) {
        log("Triggering root watchers for: " + path);
      }
      callback(path, oldValue, newValue);
    }
  }

  /**
   * @brief Retrieves the parsed pattern for the given subscription, using a
   * cache.
   *
   * @param pattern The subscription pattern string.
   * @return The parsed pattern as a vector of PatternComponent.
   */
  const std::vector<PatternComponent> &
  getParsedPattern(const std::string &pattern) {
    std::lock_guard<std::mutex> lock(cache_mutex_);
    const auto it = parsedPatternCache_.find(pattern);
    if (it != parsedPatternCache_.end()) {
      return it->second;
    }

    // Parse and cache the pattern.
    parsedPatternCache_[pattern] = parsePattern(pattern);
    return parsedPatternCache_[pattern];
  }

  /**
   * @brief Enable or disable verbose logging.
   * @param verbose Set to true to enable detailed logging.
   */
  void setVerbose(bool verbose) { verbose_ = verbose; }

private:
  // Helper for logging.
  void log(const std::string &message) const {
    std::cout << "[JsonMonitor] " << message << std::endl;
  }

  /**
   * @brief Updates the internal JSON state at a given path.
   *
   * If the path is empty, the entire state is replaced. Otherwise, the function
   * traverses (and creates nodes as needed) and updates the target node.
   *
   * @param path The JSON path to update.
   * @param new_state The new JSON value to set at the path.
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
   *
   * @param state The root JSON state.
   * @param path The concrete JSON path.
   * @return The JSON value at the path, or Json::nullValue if not found.
   */
  Json::Value extractValue(const Json::Value &state,
                           const std::string &path) const {
    if (path.empty())
      return state;
    std::vector<PathComponent> parts = splitPath(path);
    return getJsonValueAtPath(state, parts, verbose_);
  }

  mutable std::mutex state_mutex_;
  Json::Value data_;
  bool verbose_;
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
 *
 * This class handles creation and cleanup of a UDP socket.
 */
class UDPSocket {
public:
  /**
   * @brief Constructs a UDPSocket.
   *
   * @param domain The protocol family (e.g., AF_INET).
   * @param type The socket type (e.g., SOCK_DGRAM).
   * @param protocol The protocol to use.
   * @throws std::runtime_error if socket creation fails.
   */
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

  // Non-copyable.
  UDPSocket(const UDPSocket &) = delete;
  UDPSocket &operator=(const UDPSocket &) = delete;

private:
  int sockfd_;
};

/**
 * @brief Monitors remote JSON values via UDP and updates a local JsonMonitor.
 *
 * The UDPValueMonitor listens for incoming JSON messages via UDP, processes
 * them, and notifies registered callbacks.
 */
class UDPValueMonitor {
public:
  /**
   * @brief Constructs a UDPValueMonitor.
   *
   * Sets up the UDP socket, binds to a local port, registers callbacks,
   * sends an initial state request, and starts the receive thread.
   *
   * @param serverIP The server's IP address.
   * @param port The server's port number.
   * @param targetPaths A vector of JSON paths or patterns to monitor.
   * @param verbose If true, enables verbose logging.
   * @throws std::runtime_error on socket or binding errors.
   */
  UDPValueMonitor(const std::string &serverIP, int port,
                  const std::vector<std::string> &targetPaths,
                  void (*updateHandler)(const std::string &),
                  bool verbose = false)
      : targetPaths_(targetPaths), updateHandler_(updateHandler),
        verbose_(verbose), jsonMonitor_(Json::objectValue, verbose) {
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

    // Set socket non-blocking.
    int flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

    // Register watchers based on whether the path contains a wildcard.
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

  /**
   * @brief Stops the UDPValueMonitor and joins the receive thread.
   */
  void stop() {
    running_ = false;
    if (receiveThread_.joinable())
      receiveThread_.join();
  }

  /**
   * @brief For testing: Get the JSON value at a given path.
   *
   * @param path The JSON path.
   * @return The JSON value.
   */
  Json::Value get(const std::string &path) const {
    return jsonMonitor_.get(path);
  }

  /**
   * @brief For testing: Get the local port to which the socket is bound.
   *
   * @return The local port number, or -1 on error.
   */
  int getLocalPort() const {
    sockaddr_in localAddr;
    socklen_t addrLen = sizeof(localAddr);
    if (getsockname(udpSocket_.get(), reinterpret_cast<sockaddr *>(&localAddr),
                    &addrLen) == 0)
      return ntohs(localAddr.sin_port);
    return -1;
  }

private:
  // Logging helper.
  void log(const std::string &message) const {
    std::cout << "[UDPValueMonitor] " << message << std::endl;
  }

  /**
   * @brief Returns the current timestamp as a string (HH:MM:SS).
   */
  std::string getTimestamp() const {
    auto now = std::chrono::system_clock::now();
    auto now_c = std::chrono::system_clock::to_time_t(now);
    struct tm local_tm;
    localtime_r(&now_c, &local_tm);
    std::stringstream ss;
    ss << std::put_time(&local_tm, "%H:%M:%S");
    return ss.str();
  }

  /**
   * @brief Handles a monitored value change.
   */
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
                   + std::to_string(path_parts[4].arrayIndex + 1) + "]"
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
    else if (path_parts[0].key == "dsp_static_config") {
      message = "{ \"target\": \"session\", \"name\": \"destroy_all_audio_tasks\" }";
      updateHandler_(message);

      std::ofstream dsp_config("/tmp/dsp_config.json");
      dsp_config << new_val;
      dsp_config.close();

      message = "{ \"target\": \"session\", \"name\": \"create_audio_task\", \"value\": \"/tmp/dsp_config.json\" }";
      updateHandler_(message);
    }
  }

  /**
   * @brief Sends an initial state request to the server.
   */
  void requestInitialState(const sockaddr_in &serverAddr) {
    Json::Value message;
    message["action"] = "get";
    Json::StreamWriterBuilder writerBuilder;
    std::string jsonStr = Json::writeString(writerBuilder, message);
    ssize_t sent = sendto(udpSocket_.get(), jsonStr.c_str(), jsonStr.length(),
                          0, reinterpret_cast<const sockaddr *>(&serverAddr),
                          sizeof(serverAddr));
    if (sent < 0 && verbose_) {
      log("Failed to send initial state request: " +
          std::string(strerror(errno)));
    }
    receivedInitialState_ = false;
  }

  /**
   * @brief Retrieves a JSON value at a given path from a JSON tree.
   */
  Json::Value getValueAtPath(const Json::Value &root,
                             const std::vector<PathComponent> &pathParts) {
    return getJsonValueAtPath(root, pathParts, verbose_);
  }

  /**
   * @brief Helper to construct a JSON path string from a vector of
   * PathComponent.
   */
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

  /**
   * @brief Recursively traverses a JSON node and updates matching paths.
   */
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

  /**
   * @brief Processes an incoming JSON update message.
   */
  void handleUpdateMessage(const Json::Value &update) {
    if (verbose_)
      log("Processing incoming JSON update: " + update.toStyledString());

    for (const auto &path : targetPaths_) {
      if (path.find('*') != std::string::npos) {
        const auto &parsedPattern = jsonMonitor_.getParsedPattern(path);
        std::vector<PathComponent> currentPath;
        traverseAndUpdate(update, currentPath, parsedPattern);
      } else {
        auto path_parts = jsonMonitor_.splitPath(path);
        Json::Value value = getValueAtPath(update, path_parts);
        if (!value.isNull()) {
          if (verbose_)
            log("Detected value at " + path + ": " + value.toStyledString());
          jsonMonitor_.handleExternalUpdate(path, value);
        } else if (verbose_) {
          log("No matching value found for path: " + path);
        }
      }
    }
  }

  /**
   * @brief Main loop that listens for incoming UDP messages.
   */
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
        const ssize_t received =
            recvfrom(udpSocket_.get(), buffer, BUFFER_SIZE - 1, 0,
                     reinterpret_cast<sockaddr *>(&senderAddr), &senderLen);
        if (received < 0) {
          if (errno == EWOULDBLOCK || errno == EAGAIN)
            continue;
          std::cerr << "Error receiving data: " << strerror(errno) << std::endl;
          continue;
        }
        buffer[received] = '\0';
        if (verbose_)
          log("Received data: " + std::string(buffer));

        Json::Value response;
        Json::CharReaderBuilder readerBuilder;
        std::istringstream iss(buffer);
        std::string errs;
        if (Json::parseFromStream(readerBuilder, iss, &response, &errs)) {
          if (response.isMember("status") && response.isMember("data")) {
            if (verbose_)
              log("Processing initial state response");
            receivedInitialState_ = true;
            handleUpdateMessage(response["data"]);
          } else {
            if (verbose_)
              log("Processing update message");
            handleUpdateMessage(response);
          }
        } else if (verbose_) {
          std::cerr << "Failed to parse JSON: " << errs << std::endl;
        }
      }
    }
  }

  UDPSocket udpSocket_{AF_INET, SOCK_DGRAM, 0};
  std::atomic<bool> running_{true};
  std::thread receiveThread_;
  std::vector<std::string> targetPaths_;
  void (*updateHandler_)(const std::string &);
  bool verbose_;
  JsonMonitor jsonMonitor_;
  sockaddr_in serverAddr_;
  bool receivedInitialState_{false};
};
