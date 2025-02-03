#include <arpa/inet.h>
#include <atomic>
#include <cctype>
#include <chrono>
#include <cstring>
#include <fcntl.h>
#include <functional>
#include <iomanip>
#include <iostream>
#include <json/json.h>
#include <mutex>
#include <netinet/in.h>
#include <regex>
#include <sstream>
#include <stdexcept>
#include <string>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>
#include <vector>

struct PathComponent {
  std::string key;
  int arrayIndex; // Valid only if isArrayAccess is true
  bool isArrayAccess;

  PathComponent(const std::string &k)
      : key(k), arrayIndex(-1), isArrayAccess(false) {}
  PathComponent(int idx) : key(""), arrayIndex(idx), isArrayAccess(true) {}
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
  std::string key; // valid if not an array access
  bool isArrayAccess = false;
  bool isArrayWildcard = false;
  bool isSlice = false; // if true, then use sliceStart and sliceEnd
  int index = -1;       // used for literal index
  int sliceStart = 0;   // inclusive lower bound
  int sliceEnd = 0;     // inclusive upper bound
};

/**
 * @brief Parse a subscription pattern string into components.
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

    // If token is exactly "[*]", then it means “any array element”
    if (token == "[*]") {
      PatternComponent pc;
      pc.isArrayAccess = true;
      pc.isArrayWildcard = true;
      components.push_back(pc);
      continue;
    }

    // If token contains a '[' and ends with ']'
    size_t bracketPos = token.find('[');
    if (bracketPos != std::string::npos && token.back() == ']') {
      // First, if there is a key portion before the '[' add that as a
      // component.
      std::string keyPart = token.substr(0, bracketPos);
      if (!keyPart.empty()) {
        PatternComponent pc;
        pc.key = keyPart;
        components.push_back(pc);
      }

      // Now process the content within the brackets.
      std::string inside =
          token.substr(bracketPos + 1, token.size() - bracketPos - 2);
      PatternComponent pcArr;
      pcArr.isArrayAccess = true;
      if (inside == "*") {
        pcArr.isArrayWildcard = true;
      } else if (inside.find(':') != std::string::npos) {
        // This is a slice pattern.
        pcArr.isSlice = true;
        size_t colonPos = inside.find(':');
        std::string startStr = inside.substr(0, colonPos);
        std::string endStr = inside.substr(colonPos + 1);
        try {
          pcArr.sliceStart = std::stoi(startStr);
          pcArr.sliceEnd = std::stoi(endStr);
        } catch (...) {
          throw std::runtime_error("Invalid slice indices in pattern: " +
                                   token);
        }
      } else {
        // Otherwise, literal numeric index.
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
        pcArr.index = std::stoi(inside);
      }
      components.push_back(pcArr);
    } else {
      // Otherwise, token is a simple key.
      PatternComponent pc;
      pc.key = token;
      components.push_back(pc);
    }
  }
  return components;
}

/**
 * @brief Retrieves an aggregated JSON value for a subscription that may include
 * a slice.
 *
 * Given a JSON root (for example, the current internal state or a copy of it)
 * and a subscription string (like "settings.telemetry.report_period[1:3]"),
 * this function parses the subscription and then traverses the JSON.
 * When it encounters a slice token, it aggregates all elements whose index is
 * between sliceStart and sliceEnd (inclusive) into a JSON array.
 *
 * @param root The JSON value (state) to search.
 * @param subscription The subscription pattern string.
 * @return The aggregated JSON value, or null if the subscription cannot be
 * fully resolved.
 */
inline Json::Value getAggregatedFrom(const Json::Value &root,
                                     const std::string &subscription) {
  // Parse the subscription into tokens (PatternComponent objects)
  std::vector<PatternComponent> tokens = parsePattern(subscription);
  Json::Value current = root;
  for (const auto &token : tokens) {
    if (!token.isArrayAccess) {
      // Normal key: current must be an object and contain the key.
      if (!current.isObject() || !current.isMember(token.key))
        return Json::nullValue;
      current = current[token.key];
    } else {
      // Token is an array access.
      if (token.isSlice) {
        // If current is not an array, we cannot aggregate.
        if (!current.isArray())
          return Json::nullValue;
        Json::Value aggregated(Json::arrayValue);
        int maxIndex = static_cast<int>(current.size()) - 1;
        int end = std::min(token.sliceEnd, maxIndex);
        // Aggregate all values from sliceStart to end (inclusive)
        for (int j = token.sliceStart; j <= end; ++j) {
          aggregated.append(current[j]);
        }
        current = aggregated;
      } else if (token.isArrayWildcard) {
        // For wildcards, we simply expect current to be an array.
        if (!current.isArray())
          return Json::nullValue;
        // Here we simply leave current as is (or you could copy it if desired).
      } else {
        // Literal array index.
        if (!current.isArray() ||
            token.index >= static_cast<int>(current.size()))
          return Json::nullValue;
        current = current[token.index];
      }
    }
  }
  return current;
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
      continue;
    }

    if (pcomp.key != "*" && pcomp.key != comp.key)
      return false;
    ++pIdx;
    ++pathIdx;
  }
  // Require that both the pattern and the path have been fully matched.
  return (pIdx == pattern.size() && pathIdx == path.size());
}

/**
 * @brief Monitors and manages JSON data with support for path-based access and
 * change notifications.
 */
class JsonMonitor {
public:
  using ChangeCallback = std::function<void(
      const std::string &, const Json::Value &, const Json::Value &)>;

  JsonMonitor(Json::Value initial_data = Json::objectValue,
              bool verbose = false)
      : data_(initial_data), verbose_(verbose) {}

  void watch(const std::string &path, ChangeCallback callback) {
    if (path.empty()) {
      root_watchers_.push_back(callback);
    } else {
      watchers_[path].push_back(callback);
    }
  }

  void watchPattern(const std::string &pattern, ChangeCallback callback) {
    pattern_watchers_[pattern].push_back(callback);
  }

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
            // Invalid path
            return std::vector<PathComponent>();
          }
          parts.push_back(PathComponent(index));
        } catch (...) {
          // Invalid index
          return std::vector<PathComponent>();
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
    std::lock_guard<std::mutex> lock(state_mutex_);

    if (verbose_) {
      std::cout << "Received update for path: " << path << std::endl;
    }

    // Save a copy of the current internal state.
    Json::Value oldData = data_;

    // Update the internal state.
    updateInternalState(path, new_state);

    // After update, the internal state is newData.
    Json::Value newData = data_;

    // Check if the update actually changed the state
    if (oldData == newData) {
      // No actual change occurred, so don't notify watchers.
      if (verbose_) {
        std::cout << "No change detected for path: " << path << std::endl;
      }
      return;
    }

    // Notify exact (non-pattern) watchers as before.
    auto it = watchers_.find(path);
    if (it != watchers_.end()) {
      for (const auto &callback : it->second) {
        if (verbose_) {
          std::cout << "Triggering exact watcher for: " << path << std::endl;
        }
        callback(path, extractValue(oldData, path),
                 extractValue(newData, path));
      }
    }

    // Now handle pattern watchers.
    for (const auto &[subscription, callbacks] : pattern_watchers_) {
      std::vector<PatternComponent> tokens = parsePattern(subscription);
      std::vector<PathComponent> splitP = splitPath(path);
      if (patternMatchesPath(tokens, splitP)) {
        for (const auto &callback : callbacks) {
          // Use the concrete update path here.
          callback(path, extractValue(oldData, path),
                   extractValue(newData, path));
        }
      }
    }

    // Finally, trigger root watchers regardless of the path.
    for (const auto &callback : root_watchers_) {
      if (verbose_) {
        std::cout << "Triggering root watcher for: " << path << std::endl;
      }
      callback(path, extractValue(oldData, path), extractValue(newData, path));
    }
  }

  void setVerbose(bool verbose) { verbose_ = verbose; }

private:
  void updateInternalState(const std::string &path,
                           const Json::Value &new_state) {
    // If updating the root, replace entirely.
    if (path.empty()) {
      data_ = new_state;
      return;
    }

    std::vector<PathComponent> path_parts = splitPath(path);
    Json::Value *current = &data_;
    // Traverse all tokens except the last one.
    for (size_t i = 0; i < path_parts.size() - 1; ++i) {
      const auto &part = path_parts[i];
      if (part.isArrayAccess) {
        if (!current->isArray()) {
          // Do not overwrite if it exists. Only create if missing.
          *current = Json::arrayValue;
        }
        // Expand the array if needed.
        while (current->size() <= static_cast<size_t>(part.arrayIndex)) {
          current->append(Json::Value());
        }
        current = &(*current)[part.arrayIndex];
      } else {
        bool nextIsArray = false;
        if (i + 1 < path_parts.size() && path_parts[i + 1].isArrayAccess)
          nextIsArray = true;
        if (!current->isObject())
          *current = Json::objectValue;
        // Only create the member if it doesn’t exist.
        if (!current->isMember(part.key)) {
          if (nextIsArray)
            (*current)[part.key] = Json::arrayValue;
          else
            (*current)[part.key] = Json::objectValue;
        }
        current = &((*current)[part.key]);
      }
    }

    // Update the final token.
    const auto &last_part = path_parts.back();
    if (last_part.isArrayAccess) {
      if (!current->isArray())
        *current = Json::arrayValue;
      while (current->size() <= static_cast<size_t>(last_part.arrayIndex)) {
        current->append(Json::Value());
      }
      (*current)[last_part.arrayIndex] = new_state;
    } else {
      if (!current->isObject())
        *current = Json::objectValue;
      (*current)[last_part.key] = new_state;
    }
  }

  Json::Value extractValue(const Json::Value &state,
                           const std::string &path) const {
    if (path.empty())
      return state;
    std::vector<PathComponent> parts = splitPath(path);
    const Json::Value *current = &state;
    for (const auto &part : parts) {
      if (part.isArrayAccess) {
        if (!current->isArray() ||
            part.arrayIndex >= static_cast<int>(current->size()))
          return Json::nullValue;
        current = &(*current)[part.arrayIndex];
      } else {
        if (!current->isObject() || !current->isMember(part.key))
          return Json::nullValue;
        current = &(*current)[part.key];
      }
    }
    return *current;
  }

  void notifyWatchers(const std::string &path,
                      const std::vector<PathComponent> &path_parts,
                      const Json::Value &old_value,
                      const Json::Value &new_value) {
    if (verbose_) {
      std::cout << "Notifying watchers for: " << path << std::endl;
    }

    // First, trigger any exact-match watchers.
    auto it = watchers_.find(path);
    if (it != watchers_.end()) {
      for (const auto &callback : it->second) {
        callback(path, extractValue(old_value, path),
                 extractValue(new_value, path));
      }
    }

    // Next, loop over pattern watchers.
    for (const auto &[pattern, callbacks] : pattern_watchers_) {
      std::vector<PatternComponent> parsedPattern;
      try {
        parsedPattern = parsePattern(pattern);
      } catch (const std::exception &ex) {
        if (verbose_) {
          std::cerr << "Error parsing pattern \"" << pattern
                    << "\": " << ex.what() << std::endl;
        }
        continue;
      }
      if (patternMatchesPath(parsedPattern, path_parts)) {
        if (verbose_) {
          std::cout << "Pattern \"" << pattern
                    << "\" matched for path: " << path << std::endl;
        }
        for (const auto &callback : callbacks) {
          callback(path, old_value, new_value);
        }
      }
    }
    // Finally, trigger any root watchers (regardless of whether path is empty).
    for (const auto &callback : root_watchers_) {
      if (verbose_) {
        std::cout << "Triggering root watcher for: " << path << std::endl;
      }
      callback(path, old_value, new_value);
    }
  }

  std::mutex state_mutex_;
  Json::Value data_;
  bool verbose_;
  std::unordered_map<std::string, std::vector<ChangeCallback>> watchers_;
  std::unordered_map<std::string, std::vector<ChangeCallback>>
      pattern_watchers_;
  std::vector<ChangeCallback> root_watchers_;
};

class UDPValueMonitor {
public:
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

  // For testing purposes only.
  Json::Value get(const std::string &path) const {
    return jsonMonitor.get(path);
  }

private:
  std::string getTimestamp() {
    const auto now = std::chrono::system_clock::now();
    const auto now_c = std::chrono::system_clock::to_time_t(now);
    std::stringstream ss;
    ss << std::put_time(std::localtime(&now_c), "%H:%M:%S");
    return ss.str();
  }

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

  void requestInitialState() {
    Json::Value message;
    message["action"] = "get";
    Json::FastWriter writer;
    const auto jsonStr = writer.write(message);
    sendto(sockfd, jsonStr.c_str(), jsonStr.length(), 0,
           (struct sockaddr *)&serverAddr, sizeof(serverAddr));
  }

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
          return Json::nullValue;
        }
        if (part.arrayIndex >= static_cast<int>(current->size())) {
          if (verbose_) {
            std::cout << "Array index out of bounds: " << part.arrayIndex
                      << std::endl;
          }
          return Json::nullValue;
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
    return *current;
  }

  void handleUpdateMessage(const Json::Value &update) {
    if (verbose_) {
      std::cout << "Processing incoming JSON update: " << update << std::endl;
    }
    for (const auto &path : targetPaths_) {
      // If the path is a pattern (contains a wildcard), traverse the update
      // tree.
      if (path.find('*') != std::string::npos) {
        traverseAndUpdate(update, "", path);
      } else {
        // Otherwise, treat it as a concrete path.
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
  }

  void traverseAndUpdate(const Json::Value &node,
                         const std::string &currentPath,
                         const std::string &pattern) {
    if (node.isObject()) {
      for (const auto &key : node.getMemberNames()) {
        std::string newPath =
            currentPath.empty() ? key : currentPath + "." + key;
        std::vector<PathComponent> path_parts = jsonMonitor.splitPath(newPath);
        try {
          auto parsedPattern = parsePattern(pattern);
          if (patternMatchesPath(parsedPattern, path_parts)) {
            jsonMonitor.handleExternalUpdate(newPath, node[key]);
          }
        } catch (...) {
        }
        traverseAndUpdate(node[key], newPath, pattern);
      }
    } else if (node.isArray()) {
      for (Json::ArrayIndex i = 0; i < node.size(); ++i) {
        std::string newPath = currentPath + "[" + std::to_string(i) + "]";
        std::vector<PathComponent> path_parts = jsonMonitor.splitPath(newPath);
        try {
          auto parsedPattern = parsePattern(pattern);
          if (patternMatchesPath(parsedPattern, path_parts)) {
            jsonMonitor.handleExternalUpdate(newPath, node[i]);
          }
        } catch (...) {
        }
        traverseAndUpdate(node[i], newPath, pattern);
      }
    }
  }

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
          if (response.isMember("status") && response.isMember("data")) {
            if (verbose_) {
              std::cout << "Processing initial state response" << std::endl;
            }
            handleUpdateMessage(response["data"]);
          } else {
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