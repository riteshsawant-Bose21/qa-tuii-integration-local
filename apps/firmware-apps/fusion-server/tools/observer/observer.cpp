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
#include <sstream>
#include <string>
#include <sys/socket.h>
#include <thread>
#include <unistd.h>
#include <unordered_map>

class JsonMonitor {
public:
  using ChangeCallback = std::function<void(
      const std::string &, const Json::Value &, const Json::Value &)>;

  JsonMonitor(Json::Value initial_data = Json::objectValue)
      : data_(initial_data) {}

  void watch(const std::string &path, ChangeCallback callback) {
    watchers_[path].push_back(callback);
  }

  void update(const std::string &path, const Json::Value &new_value) {
    std::vector<std::string> path_parts = split_path(path);
    Json::Value *current = &data_;
    Json::Value old_value;

    // Navigate to the target location and store the old value
    for (const auto &part : path_parts) {
      if (current->isObject()) {
        if (!current->isMember(part)) {
          (*current)[part] = Json::objectValue;
        }
        current = &(*current)[part];
      } else if (current->isArray()) {
        Json::ArrayIndex index =
            static_cast<Json::ArrayIndex>(std::stoul(part));
        if (index >= current->size()) {
          current->resize(static_cast<Json::ArrayIndex>(index + 1));
        }
        current = &(*current)[index];
      }
    }

    old_value = *current;

    // Only proceed with update and notifications if the value has changed
    if (old_value != new_value) {
      *current = new_value;

      std::string current_path;
      for (const auto &part : path_parts) {
        current_path += current_path.empty() ? part : "." + part;
        auto it = watchers_.find(current_path);
        if (it != watchers_.end()) {
          for (const auto &callback : it->second) {
            callback(current_path, old_value, new_value);
          }
        }
      }
    }
  }

  Json::Value get(const std::string &path) const {
    std::vector<std::string> path_parts = split_path(path);
    const Json::Value *current = &data_;

    for (const auto &part : path_parts) {
      if (current->isObject() && current->isMember(part)) {
        current = &(*current)[part];
      } else {
        return Json::nullValue;
      }
    }

    return *current;
  }

  std::vector<std::string> split_path(const std::string &path) const {
    std::vector<std::string> parts;
    std::string current;

    for (char c : path) {
      if (c == '.') {
        if (!current.empty()) {
          parts.push_back(current);
          current.clear();
        }
      } else {
        current += c;
      }
    }

    if (!current.empty()) {
      parts.push_back(current);
    }

    return parts;
  }

private:
  Json::Value data_;
  std::unordered_map<std::string, std::vector<ChangeCallback>> watchers_;
};

class UDPValueMonitor {
public:
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

      std::cout << getTimestamp() << " " << path << " changed from: ";
      std::cout << Json::writeString(builder, old_val);
      std::cout << " to: " << Json::writeString(builder, new_val) << std::endl;
    }
  }

  void requestInitialState() {
    Json::Value message;
    message["action"] = "get";
    const auto jsonStr = writer.write(message);
    sendto(sockfd, jsonStr.c_str(), jsonStr.length(), 0,
           (struct sockaddr *)&serverAddr, sizeof(serverAddr));
  }

  Json::Value getValueAtPath(const Json::Value &root,
                             const std::vector<std::string> &path_parts) {
    const Json::Value *current = &root;
    for (const auto &part : path_parts) {
      if (!current->isObject() || !current->isMember(part)) {
        return Json::nullValue;
      }
      current = &(*current)[part];
    }
    return *current;
  }

  void handleUpdateMessage(const Json::Value &update) {
    if (debug_) {
      Json::StyledWriter writer;
      std::cout << "Processing update: " << writer.write(update) << std::endl;
    }

    // Get the path parts we're looking for
    std::vector<std::string> path_parts = jsonMonitor.split_path(targetPath_);

    // Extract the value at the target path
    Json::Value value = getValueAtPath(update, path_parts);

    if (!value.isNull()) {
      jsonMonitor.update(targetPath_, value);
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

        if (debug_) {
          std::cout << "Received data: " << buffer << std::endl;
        }

        Json::Value response;
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
  Json::FastWriter writer;
  Json::Reader reader;

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
                << " 127.0.0.1 7947 audio.settings.volume\n";
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
