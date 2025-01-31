#include <arpa/inet.h>
#include <atomic>
#include <chrono>
#include <cstring>
#include <fcntl.h>
#include <functional>
#include <iomanip>
#include <iostream>
#include <json/json.h>
#include <netinet/in.h>
#include <regex>
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>

/**
 * @brief Represents a component of a JSON path
 *
 * This struct handles both simple key-based access and array indexing
 * within JSON path strings.
 */
struct PathComponent {
  std::string key;
  int arrayIndex;
  bool isArrayAccess;

  /**
   * @brief Constructs a simple key-based path component
   * @param k The key string
   */
  PathComponent(const std::string &k)
      : key(k), arrayIndex(-1), isArrayAccess(false) {}

  /**
   * @brief Constructs an array access path component
   * @param k The key string
   * @param idx The array index
   */
  PathComponent(const std::string &k, int idx)
      : key(k), arrayIndex(idx), isArrayAccess(true) {}
};

/**
 * @brief Represents a parsed JSON path pattern with wildcard support
 *
 * Handles the parsing and matching of JSON path patterns that may include
 * wildcards (*) for matching multiple path components.
 */
struct PathPattern {
  std::vector<std::string> segments;
  bool hasWildcard;

  /**
   * @brief Constructs a path pattern from a string
   * @param pattern The path pattern string (e.g., "audio.settings.*")
   */
  explicit PathPattern(const std::string &pattern) {
    std::string segment;
    for (char c : pattern) {
      if (c == '.') {
        if (!segment.empty()) {
          segments.push_back(segment);
          segment.clear();
        }
      } else {
        segment += c;
      }
    }

    if (!segment.empty()) {
      segments.push_back(segment);
    }
  }

  /**
   * @brief Checks if a path matches this pattern
   * @param path Vector of path components to check against the pattern
   * @return true if the path matches the pattern, false otherwise
   *
   * A path matches if either:
   * - It exactly matches all non-wildcard segments
   * - It matches all segments up to a wildcard, which then matches all
   * remaining components
   */
  bool matches(const std::vector<PathComponent> &path) const {
    if (segments.empty())
      return path.empty();

    size_t pathIdx = 0;
    size_t patternIdx = 0;

    while (pathIdx < path.size() && patternIdx < segments.size()) {
      const auto &pattern = segments[patternIdx];

      // Handle gain[*] pattern
      if (pattern.find("[*]") != std::string::npos) {
        std::string baseName = pattern.substr(0, pattern.find("["));

        // Need at least two more components
        if (pathIdx + 1 >= path.size())
          return false;

        // Match base name
        if (path[pathIdx].key != baseName)
          return false;

        // Next component must be array
        if (!path[pathIdx + 1].isArrayAccess)
          return false;

        // Skip both the name and array components
        pathIdx += 2;
        patternIdx++;
        continue;
      }

      // Handle simple wildcard
      if (pattern == "*") {
        pathIdx++;
        patternIdx++;
        continue;
      }

      // Handle exact match
      if (pattern != path[pathIdx].key) {
        return false;
      }

      pathIdx++;
      patternIdx++;
    }

    return pathIdx == path.size() && patternIdx == segments.size();
  }
};

/**
 * @brief Monitors and manages JSON data with support for path-based access and
 * change notifications
 *
 * This class provides functionality to watch specific paths within a JSON
 * structure and receive notifications when values change at those paths.
 */
class JsonMonitor {
public:
  using ChangeCallback = std::function<void(
      const std::string &, const Json::Value &, const Json::Value &)>;

  /**
   * @brief Constructs a JsonMonitor with optional initial data
   * @param initial_data Initial JSON data (defaults to empty object)
   */
  JsonMonitor(Json::Value initial_data = Json::objectValue,
              bool verbose = false)
      : data_(initial_data), verbose_(verbose) {}

  /**
   * @brief Registers a callback for changes at a specific path
   * @param path The JSON path to watch
   * @param callback Function to call when the value changes
   *
   * Pattern watchers receive notifications for all changes to paths
   * that match their pattern, with the full path of the change included
   * in the notification.
   */
  void watch(const std::string &path, ChangeCallback callback) {
    if (path.empty()) {
      root_watchers_.push_back(callback);
    } else {
      watchers_[path].push_back(callback);
    }
  }

  /**
   * @brief Registers a pattern-based watcher for JSON path changes
   * @param pattern The pattern to watch (may include wildcards)
   * @param callback Function to call when matching paths change
   */
  void watchPattern(const std::string &pattern, ChangeCallback callback) {
    pattern_watchers_[pattern].push_back(callback);
  }

  /**
   * @brief Retrieves the current value at a specific path
   * @param path The JSON path to query
   * @return The value at the specified path, or null if not found
   */
  Json::Value get(const std::string &path) const {
    if (path.empty()) {
      return data_;
    }

    std::vector<PathComponent> path_parts = splitPath(path);
    const Json::Value *current = &data_;

    for (const auto &part : path_parts) {
      if (part.isArrayAccess) {
        if (!current->isArray() ||
            part.arrayIndex >= static_cast<int>(current->size())) {
          return Json::nullValue;
        }
        current = &(*current)[part.arrayIndex];
      } else {
        if (!current->isObject() || !current->isMember(part.key)) {
          return Json::nullValue;
        }
        current = &(*current)[part.key];
      }
    }
    return *current;
  }

  std::vector<PathComponent> splitPath(const std::string &path) const {
    std::vector<PathComponent> parts;
    if (path.empty()) {
      return parts;
    }

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
          if (index < 0) {
            return std::vector<PathComponent>(); // Invalid path
          }
          parts.push_back(PathComponent("", index));
        } catch (...) {
          return std::vector<PathComponent>(); // Invalid index
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
      std::cout << "Parsed Path: ";
      for (const auto &p : parts) {
        if (p.isArrayAccess) {
          std::cout << "[" << p.arrayIndex << "] ";
        } else {
          std::cout << p.key << " ";
        }
      }
      std::cout << std::endl;
    }

    return parts;
  }

  void handleExternalUpdate(const std::string &path,
                            const Json::Value &new_state) {
    if (verbose_) {
      std::cout << "Received update for path: " << path << std::endl;
    }

    Json::Value old_state = get(path);
    updateInternalState(path, new_state);

    Json::Value current_state = get(path);
    if (old_state != current_state) {
      if (verbose_) {
        std::cout << "Updated: " << path << " from " << old_state << " to "
                  << current_state << std::endl;
      }
      notifyWatchers(path, splitPath(path), old_state, current_state);
    } else {
      if (verbose_) {
        std::cout << "No change detected at: " << path << std::endl;
      }
    }
  }

  void setVerbose(bool verbose) { verbose_ = verbose; }

private:
  void updateInternalState(const std::string &path,
                           const Json::Value &new_state) {
    std::vector<PathComponent> path_parts = splitPath(path);
    Json::Value *current = &data_;

    for (size_t i = 0; i < path_parts.size() - 1; ++i) {
      const auto &part = path_parts[i];
      if (part.isArrayAccess) {
        if (!current->isArray()) {
          *current = Json::arrayValue;
        }
        while (current->size() <= static_cast<size_t>(part.arrayIndex)) {
          current->append(Json::Value());
        }
        current = &(*current)[part.arrayIndex];
      } else {
        if (!current->isObject()) {
          *current = Json::objectValue;
        }
        if (!current->isMember(part.key)) {
          (*current)[part.key] = Json::Value();
        }
        current = &(*current)[part.key];
      }
    }

    const auto &last_part = path_parts.back();
    if (last_part.isArrayAccess) {
      if (!current->isArray()) {
        *current = Json::arrayValue;
      }
      while (current->size() <= static_cast<size_t>(last_part.arrayIndex)) {
        current->append(Json::Value());
      }
      (*current)[last_part.arrayIndex] = new_state;
    } else {
      if (!current->isObject()) {
        *current = Json::objectValue;
      }
      (*current)[last_part.key] = new_state;
    }
  }

  void notifyWatchers(const std::string &path,
                      const std::vector<PathComponent> &path_parts,
                      const Json::Value &old_value,
                      const Json::Value &new_value) {
    if (verbose_) {
      std::cout << "Notifying watchers for: " << path << std::endl;
    }

    auto it = watchers_.find(path);
    if (it != watchers_.end()) {
      for (const auto &callback : it->second) {
        if (verbose_) {
          std::cout << "Triggering exact watcher: " << path << std::endl;
        }
        callback(path, old_value, new_value);
      }
    }

    for (const auto &[pattern, callbacks] : pattern_watchers_) {
      PathPattern matcher(pattern);
      if (matcher.matches(path_parts)) {
        if (verbose_) {
          std::cout << "Matched pattern: " << pattern << " for path: " << path
                    << std::endl;
        }
        for (const auto &callback : callbacks) {
          callback(path, old_value, new_value);
        }
      }
    }

    if (!path.empty()) {
      for (const auto &callback : root_watchers_) {
        if (verbose_) {
          std::cout << "Triggering root watcher for: " << path << std::endl;
        }
        callback(path, old_value, new_value);
      }
    }
  }

  Json::Value data_;
  bool verbose_;
  std::unordered_map<std::string, std::vector<ChangeCallback>> watchers_;
  std::unordered_map<std::string, std::vector<ChangeCallback>>
      pattern_watchers_;
  std::vector<ChangeCallback> root_watchers_;
};

/**
 * @brief Monitors JSON values over UDP network connection
 *
 * This class establishes a UDP connection to a server and monitors specific
 * JSON paths for changes, providing real-time updates.
 */
class UDPValueMonitor {
public:
  /**
   * @brief Constructs a UDP monitor
   * @param serverIP The IP address of the server
   * @param port The UDP port number
   * @param targetPaths The JSON paths to monitor
   * @throw std::runtime_error if socket creation or binding fails
   */
  UDPValueMonitor(const std::string &serverIP, int port,
                  const std::vector<std::string> &targetPaths,
                  bool verbose = false)
      : targetPaths_(targetPaths), verbose_(verbose) {
    sockfd = socket(AF_INET, SOCK_DGRAM, 0);
    if (sockfd < 0) {
      throw std::runtime_error("Failed to create socket");
    }

    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    if (inet_pton(AF_INET, serverIP.c_str(), &serverAddr.sin_addr) <= 0) {
      close(sockfd);
      throw std::runtime_error("Invalid address");
    }

    struct sockaddr_in clientAddr;
    memset(&clientAddr, 0, sizeof(clientAddr));
    clientAddr.sin_family = AF_INET;
    clientAddr.sin_addr.s_addr = INADDR_ANY;
    clientAddr.sin_port = htons(0);

    if (bind(sockfd, (struct sockaddr *)&clientAddr, sizeof(clientAddr)) < 0) {
      close(sockfd);
      throw std::runtime_error("Failed to bind socket: " +
                               std::string(strerror(errno)));
    }

    const auto flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);

    jsonMonitor.setVerbose(verbose_);

    // Set up watchers for all target paths
    for (const auto &path : targetPaths_) {
      if (path.find('*') != std::string::npos) {
        jsonMonitor.watchPattern(path, [this](const std::string &p,
                                              const Json::Value &old_val,
                                              const Json::Value &new_val) {
          handleValueChange(p, old_val, new_val);
        });
      } else {
        jsonMonitor.watch(path, [this](const std::string &p,
                                       const Json::Value &old_val,
                                       const Json::Value &new_val) {
          handleValueChange(p, old_val, new_val);
        });
      }
    }

    requestInitialState();
    receiveThread = std::thread(&UDPValueMonitor::receiveLoop, this);
  }

  ~UDPValueMonitor() {
    stop();
    if (sockfd >= 0) {
      close(sockfd);
    }
  }

  void stop() {
    running = false;
    if (receiveThread.joinable()) {
      receiveThread.join();
    }
  }

private:
  /**
   * @brief Generates a timestamp string for logging
   * @return Formatted time string (HH:MM:SS)
   */
  std::string getTimestamp() {
    const auto now = std::chrono::system_clock::now();
    const auto now_c = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(std::localtime(&now_c), "%H:%M:%S");
    return ss.str();
  }

  /**
   * @brief Handles value changes in the monitored path
   * @param path The path where the change occurred
   * @param old_val The previous value
   * @param new_val The new value
   */
  void handleValueChange(const std::string &path, const Json::Value &old_val,
                         const Json::Value &new_val) {
    if (old_val != new_val) {
      Json::StreamWriterBuilder builder;
      builder["precision"] = 2;
      builder["indentation"] = "";

      if (verbose_) {
        std::cout << getTimestamp() << " " << path << " changed from: ";
        std::cout << Json::writeString(builder, old_val);
        std::cout << " to: " << Json::writeString(builder, new_val)
                  << std::endl;
      }
    }
  }

  /**
   * @brief Sends a request for initial state to the server
   */
  void requestInitialState() {
    Json::Value message;
    message["action"] = "get";
    Json::FastWriter writer;
    const auto jsonStr = writer.write(message);
    sendto(sockfd, jsonStr.c_str(), jsonStr.length(), 0,
           (struct sockaddr *)&serverAddr, sizeof(serverAddr));
  }

  /**
   * @brief Retrieves a value at a specific path within a JSON structure
   * @param root The root JSON value to search in
   * @param path_parts The parsed path components
   * @return The value at the specified path, or null if not found
   */
  Json::Value getValueAtPath(const Json::Value &root,
                             const std::vector<PathComponent> &path_parts) {
    const Json::Value *current = &root;

    for (const auto &part : path_parts) {
      if (part.isArrayAccess) {
        if (!current->isArray()) {
          if (verbose_) {
            std::cout
                << "Expected array but found non-array at path component: "
                << part.arrayIndex << std::endl;
          }
          return Json::nullValue; // Path does not match expected JSON structure
        }
        if (part.arrayIndex >= static_cast<int>(current->size())) {
          if (verbose_) {
            std::cout << "Array index out of bounds: " << part.arrayIndex
                      << std::endl;
          }
          return Json::nullValue; // Index out of range
        }
        current = &(*current)[part.arrayIndex];
      } else {
        if (!current->isObject() || !current->isMember(part.key)) {
          if (verbose_) {
            std::cout << "Key not found in object: " << part.key << std::endl;
          }
          return Json::nullValue;
        }
        current = &(*current)[part.key];
      }
    }

    return *current; // Successfully retrieved value
  }

  /**
   * @brief Processes incoming JSON update messages
   * @param update The received JSON update
   */
  void handleUpdateMessage(const Json::Value &update) {
    if (verbose_) {
      std::cout << "Processing incoming JSON update: " << update << std::endl;
    }
    for (const auto &path : targetPaths_) {
      std::vector<PathComponent> path_parts = jsonMonitor.splitPath(path);
      Json::Value value = getValueAtPath(update, path_parts);
      if (!value.isNull()) {
        if (verbose_) {
          std::cout << "Detected value at " << path << ": " << value
                    << std::endl;
        }
        jsonMonitor.handleExternalUpdate(path, value);
      } else {
        if (verbose_) {
          std::cout << "No matching value found for path: " << path
                    << std::endl;
        }
      }
    }
  }

  /**
   * @brief Recursively traverses JSON structure to find and update matching
   * paths
   * @param node Current JSON node being examined
   * @param currentPath String representation of path to current node
   * @param pattern Pattern string to match against paths
   *
   * Traverses both objects and arrays within the JSON structure. For
   * objects, it examines each key-value pair. For arrays, it processes each
   * element with its index. When a path matches the provided pattern, it
   * triggers an update through the JsonMonitor.
   *
   * Example patterns:
   * - "audio.settings.*" matches any path starting with "audio.settings"
   * - "audio.*.gain" matches paths like "audio.eq.gain" or
   * "audio.comp.gain"
   *
   * @note The function maintains the full path context during traversal,
   *       ensuring accurate path matching and updates at all levels
   */
  void traverseAndUpdate(const Json::Value &node,
                         const std::string &currentPath,
                         const std::string &pattern) {
    if (node.isObject()) {
      for (const auto &key : node.getMemberNames()) {
        std::string newPath =
            currentPath.empty() ? key : currentPath + "." + key;
        PathPattern pathPattern(pattern);
        std::vector<PathComponent> path_parts = jsonMonitor.splitPath(newPath);

        if (pathPattern.matches(path_parts)) {
          jsonMonitor.handleExternalUpdate(newPath, node[key]);
        }
        traverseAndUpdate(node[key], newPath, pattern);
      }
    } else if (node.isArray()) {
      for (Json::ArrayIndex i = 0; i < node.size(); ++i) {
        std::string newPath = currentPath + "[" + std::to_string(i) + "]";
        PathPattern pathPattern(pattern);
        std::vector<PathComponent> path_parts = jsonMonitor.splitPath(newPath);

        if (pathPattern.matches(path_parts)) {
          jsonMonitor.handleExternalUpdate(newPath, node[i]);
        }
        traverseAndUpdate(node[i], newPath, pattern);
      }
    }
  }

  /**
   * @brief Main receive loop that processes incoming UDP messages
   */
  void receiveLoop() {
    char buffer[BUFFER_SIZE];
    struct sockaddr_in senderAddr;
    socklen_t senderLen = sizeof(senderAddr);

    while (running) {
      const ssize_t received =
          recvfrom(sockfd, buffer, BUFFER_SIZE, 0,
                   (struct sockaddr *)&senderAddr, &senderLen);

      if (received > 0) {
        buffer[received] = '\0';

        if (verbose_) {
          std::cout << "Received data: " << buffer << std::endl;
        }

        Json::Value response;
        Json::Reader reader;
        if (reader.parse(buffer, response)) {
          // Handle initial state response
          if (response.isMember("status") && response.isMember("data")) {
            if (verbose_) {
              std::cout << "Processing initial state response" << std::endl;
            }
            handleUpdateMessage(response["data"]);
          } else {
            // Handle direct update
            if (verbose_) {
              std::cout << "Processing update message" << std::endl;
            }
            handleUpdateMessage(response);
          }
        }
      } else if (received < 0 && errno != EWOULDBLOCK && errno != EAGAIN) {
        std::cerr << "Error receiving data: " << strerror(errno) << std::endl;
      }

      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
  }

  int sockfd;
  struct sockaddr_in serverAddr;
  std::atomic<bool> running{true};
  std::thread receiveThread;

  std::vector<std::string> targetPaths_;

  JsonMonitor jsonMonitor;
  bool verbose_;

  static constexpr size_t BUFFER_SIZE = 65535;
};
