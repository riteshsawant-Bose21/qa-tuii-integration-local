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
 * @brief Monitors and manages JSON data with support for path-based access and
 * change notifications
 *
 * This class provides functionality to watch specific paths within a JSON
 * structure and receive notifications when values change at those paths.
 */
class JsonMonitor {
public:
  /// Function type for change notification callbacks
  using ChangeCallback = std::function<void(
      const std::string &, const Json::Value &, const Json::Value &)>;

  /**
   * @brief Constructs a JsonMonitor with optional initial data
   * @param initial_data Initial JSON data (defaults to empty object)
   */
  JsonMonitor(Json::Value initial_data = Json::objectValue)
      : data_(initial_data) {}

  /**
   * @brief Registers a callback for changes at a specific path
   * @param path The JSON path to watch
   * @param callback Function to call when the value changes
   */
  void watch(const std::string &path, ChangeCallback callback) {
    watchers_[path].push_back(callback);
  }

  /**
   * @brief Updates the value at a specific path
   * @param path The JSON path to update
   * @param new_value The new value to set
   *
   * Triggers registered callbacks for the path and all parent paths
   * if the value actually changes.
   */
  void update(const std::string &path, const Json::Value &new_value) {
    std::vector<PathComponent> path_parts = split_path(path);
    Json::Value *current = &data_;
    Json::Value old_value;

    // Navigate to the target location and store the old value
    for (const auto &part : path_parts) {
      if (current->isObject()) {
        if (!current->isMember(part.key)) {
          (*current)[part.key] =
              part.isArrayAccess ? Json::arrayValue : Json::objectValue;
        }
        current = &(*current)[part.key];
      }

      if (part.isArrayAccess) {
        if (!current->isArray()) {
          *current = Json::arrayValue;
        }
        if (static_cast<Json::ArrayIndex>(part.arrayIndex) >= current->size()) {
          current->resize(static_cast<Json::ArrayIndex>(part.arrayIndex + 1));
        }
        current = &(*current)[part.arrayIndex];
      }
    }

    old_value = *current;

    // Only proceed with update and notifications if the value has changed
    if (old_value != new_value) {
      *current = new_value;

      // Build path progressively for notifications
      std::string current_path;
      for (const auto &part : path_parts) {
        if (!current_path.empty()) {
          current_path += ".";
        }
        current_path += part.key;
        if (part.isArrayAccess) {
          current_path += "[" + std::to_string(part.arrayIndex) + "]";
        }

        auto it = watchers_.find(current_path);
        if (it != watchers_.end()) {
          for (const auto &callback : it->second) {
            callback(current_path, old_value, new_value);
          }
        }
      }
    }
  }

  /**
   * @brief Retrieves the value at a specific path
   * @param path The JSON path to query
   * @return The value at the specified path, or null if the path doesn't exist
   */
  Json::Value get(const std::string &path) const {
    std::vector<PathComponent> path_parts = split_path(path);
    const Json::Value *current = &data_;

    for (const auto &part : path_parts) {
      if (current->isObject() && current->isMember(part.key)) {
        current = &(*current)[part.key];
        if (part.isArrayAccess) {
          if (current->isArray() &&
              part.arrayIndex < static_cast<int>(current->size())) {
            current = &(*current)[part.arrayIndex];
          } else {
            return Json::nullValue;
          }
        }
      } else {
        return Json::nullValue;
      }
    }

    return *current;
  }

  /**
   * @brief Splits a path string into PathComponent objects
   * @param path The path string to split (e.g., "root.child[0].value")
   * @return Vector of PathComponent objects representing the path
   */
  std::vector<PathComponent> split_path(const std::string &path) const {
    std::vector<PathComponent> parts;
    std::string current;

    for (size_t i = 0; i < path.length(); ++i) {
      char c = path[i];
      if (c == '.') {
        if (!current.empty()) {
          parts.push_back(PathComponent(current));
          current.clear();
        }
      } else if (c == '[') {
        if (!current.empty()) {
          // Find the matching closing bracket
          size_t end = path.find(']', i);
          if (end != std::string::npos) {
            std::string index_str = path.substr(i + 1, end - i - 1);
            try {
              int index = std::stoi(index_str);
              parts.push_back(PathComponent(current, index));
              i = end;
              current.clear();
            } catch (const std::exception &e) {
              // Handle invalid index
              std::cerr << "Invalid array index: " << index_str << std::endl;
              parts.push_back(PathComponent(current));
            }
          }
        }
      } else {
        current += c;
      }
    }

    if (!current.empty()) {
      parts.push_back(PathComponent(current));
    }

    return parts;
  }

private:
  Json::Value data_;
  std::unordered_map<std::string, std::vector<ChangeCallback>> watchers_;
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
   * @param targetPath The JSON path to monitor
   * @throw std::runtime_error if socket creation or binding fails
   */
  UDPValueMonitor(const std::string &serverIP, int port,
                  const std::string &targetPath)
      : targetPath_(targetPath), debug_(false) {
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

    jsonMonitor.watch(targetPath_, [this](const std::string &path,
                                          const Json::Value &old_val,
                                          const Json::Value &new_val) {
      handleValueChange(path, old_val, new_val);
    });

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

      std::cout << getTimestamp() << " " << path << " changed from: ";
      std::cout << Json::writeString(builder, old_val);
      std::cout << " to: " << Json::writeString(builder, new_val) << std::endl;
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
      if (!current->isObject() || !current->isMember(part.key)) {
        return Json::nullValue;
      }
      current = &(*current)[part.key];

      if (part.isArrayAccess) {
        if (!current->isArray() ||
            part.arrayIndex >= static_cast<int>(current->size())) {
          return Json::nullValue;
        }
        current = &(*current)[part.arrayIndex];
      }
    }
    return *current;
  }

  /**
   * @brief Processes incoming JSON update messages
   * @param update The received JSON update
   */
  void handleUpdateMessage(const Json::Value &update) {
    if (debug_) {
      Json::StyledWriter writer;
      std::cout << "Processing update: " << writer.write(update) << std::endl;
    }

    // Get the path parts we're looking for
    std::vector<PathComponent> path_parts = jsonMonitor.split_path(targetPath_);

    // Extract the value at the target path
    Json::Value value = getValueAtPath(update, path_parts);

    if (!value.isNull()) {
      jsonMonitor.update(targetPath_, value);
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

        if (debug_) {
          std::cout << "Received data: " << buffer << std::endl;
        }

        Json::Value response;
        Json::Reader reader;
        if (reader.parse(buffer, response)) {
          // Handle initial state response
          if (response.isMember("status") && response.isMember("data")) {
            if (debug_) {
              std::cout << "Processing initial state response" << std::endl;
            }
            handleUpdateMessage(response["data"]);
          } else {
            // Handle direct update
            if (debug_) {
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

  std::string targetPath_;
  JsonMonitor jsonMonitor;
  bool debug_;

  static constexpr size_t BUFFER_SIZE = 65535;
};

int main(int argc, char *argv[]) {
  try {
    if (argc != 4) {
      std::cerr << "Usage: " << argv[0] << " <server_ip> <port> <path>\n";
      std::cerr << "Example: " << argv[0]
                << " 127.0.0.1 7947 audio.settings.peq1.gain[2]\n";
      return 1;
    }

    const std::string serverIP = argv[1];
    const int port = std::stoi(argv[2]);
    const std::string targetPath = argv[3];

    std::cout << "Starting UDPValueMonitor\n";
    std::cout << "Server: " << serverIP << ":" << port << "\n";
    std::cout << "Monitoring path: " << targetPath << "\n";

    UDPValueMonitor client(serverIP, port, targetPath);
    std::cin.get();
    client.stop();
  } catch (const std::exception &e) {
    std::cerr << "Error: " << e.what() << std::endl;
    return 1;
  }

  return 0;
}