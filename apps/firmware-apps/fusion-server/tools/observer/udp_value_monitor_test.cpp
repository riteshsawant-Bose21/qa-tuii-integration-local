#include "observer.h"
#include <arpa/inet.h>
#include <atomic>
#include <chrono>
#include <condition_variable>
#include <cstdlib>
#include <cstring>
#include <gtest/gtest.h>
#include <mutex>
#include <sstream>
#include <sys/wait.h>
#include <thread>
#include <unistd.h>

namespace {
int reserveUDPPort() {
  int sock = socket(AF_INET, SOCK_DGRAM, 0);
  if (sock == -1) {
    return -1;
  }

  sockaddr_in addr;
  std::memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons(0);

  if (bind(sock, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) != 0) {
    close(sock);
    return -1;
  }

  socklen_t addrLen = sizeof(addr);
  if (getsockname(sock, reinterpret_cast<sockaddr *>(&addr), &addrLen) != 0) {
    close(sock);
    return -1;
  }

  const int port = ntohs(addr.sin_port);
  close(sock);
  return port;
}

int reserveTCPPort() {
  int sock = socket(AF_INET, SOCK_STREAM, 0);
  if (sock == -1) {
    return -1;
  }

  sockaddr_in addr;
  std::memset(&addr, 0, sizeof(addr));
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = htonl(INADDR_ANY);
  addr.sin_port = htons(0);

  if (bind(sock, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) != 0) {
    close(sock);
    return -1;
  }

  socklen_t addrLen = sizeof(addr);
  if (getsockname(sock, reinterpret_cast<sockaddr *>(&addr), &addrLen) != 0) {
    close(sock);
    return -1;
  }

  const int port = ntohs(addr.sin_port);
  close(sock);
  return port;
}

struct ThreadJoiner {
  explicit ThreadJoiner(std::thread &thread) : thread_(thread) {}
  ~ThreadJoiner() {
    if (thread_.joinable()) {
      thread_.join();
    }
  }

  std::thread &thread_;
};
} // namespace

TEST(UDPValueMonitorTest, AsynchronousUpdatesAndNetworking) {

  const int serverPort = reserveUDPPort();
  if (serverPort <= 0) {
    GTEST_SKIP() << "Failed to reserve UDP port for local test server";
  }
  std::atomic<bool> serverReady{false};
  std::atomic<bool> serverFailed{false};
  std::string serverError;
  std::mutex serverErrorMutex;

  // Start a local UDP server in a separate thread.
  std::thread serverThread([&]() {
    // Create the UDP socket for the server.
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      std::lock_guard<std::mutex> lock(serverErrorMutex);
      serverFailed.store(true);
      serverError = "Server failed to create socket";
      return;
    }

    const int reuseAddr = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, sizeof(reuseAddr));
    timeval timeout{.tv_sec = 0, .tv_usec = 100000};
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(serverPort);

    int rc = bind(sock, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
    if (rc != 0) {
      std::lock_guard<std::mutex> lock(serverErrorMutex);
      serverFailed.store(true);
      serverError = "Server failed to bind socket";
      close(sock);
      return;
    }
    serverReady.store(true);

    char buffer[1024];
    struct sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);
    Json::CharReaderBuilder readerBuilder;
    readerBuilder["collectComments"] = false;

    auto receiveJson = [&](Json::Value *request) -> bool {
      for (int attempts = 0; attempts < 20; ++attempts) {
        ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                             (struct sockaddr *)&clientAddr, &clientLen);
        if (n < 0) {
          if (errno == EAGAIN || errno == EWOULDBLOCK) {
            continue;
          }
          return false;
        }

        buffer[n] = '\0';
        std::string errs;
        std::istringstream reqStream{std::string(buffer)};
        return Json::parseFromStream(readerBuilder, reqStream, request, &errs);
      }
      return false;
    };

    // 1) Expect device-info request.
    Json::Value request;
    if (receiveJson(&request)) {
      if (!request.isMember("action") ||
          request["action"].asString() != "get_local_device_information") {
        close(sock);
        return;
      }

      Json::Value deviceInfoEnvelope;
      deviceInfoEnvelope["_fusion_op"] = "get_local_device_information";
      deviceInfoEnvelope["status"] = "success";
      deviceInfoEnvelope["payload"]["id"] = "test-device";
      Json::StreamWriterBuilder writer;
      writer["indentation"] = "";
      std::string responseStr = Json::writeString(writer, deviceInfoEnvelope);

      sendto(sock, responseStr.c_str(), responseStr.size(), 0,
             (struct sockaddr *)&clientAddr, clientLen);
    } else {
      close(sock);
      return;
    }

    // 2) Expect state request.
    request.clear();
    if (receiveJson(&request)) {
      if (!request.isMember("action") || request["action"].asString() != "get") {
        close(sock);
        return;
      }

      Json::Value stateEnvelope;
      stateEnvelope["_fusion_op"] = "get";
      stateEnvelope["status"] = "success";
      stateEnvelope["payload"]["test"]["value"] = 42;
      Json::StreamWriterBuilder writer;
      writer["indentation"] = "";
      std::string responseStr = Json::writeString(writer, stateEnvelope);

      sendto(sock, responseStr.c_str(), responseStr.size(), 0,
             (struct sockaddr *)&clientAddr, clientLen);
    } else {
      close(sock);
      return;
    }
    close(sock);
  });
  ThreadJoiner joinServerThread(serverThread);

  for (int i = 0; i < 50 && !serverReady.load() && !serverFailed.load(); ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  const bool failedToStart = serverFailed.load();
  const bool ready = serverReady.load();
  const std::string startupError = serverError;
  ASSERT_FALSE(failedToStart) << startupError;
  ASSERT_TRUE(ready) << "Server did not become ready";

  std::mutex updateMutex;
  std::condition_variable updateCv;
  bool updateReceived = false;

  UDPValueMonitor monitorUDP("127.0.0.1", serverPort);
  monitorUDP.watch("test.value", [&](const std::string &, const Json::Value &, const Json::Value &newValue) {
    if (newValue.isInt() && newValue.asInt() == 42) {
      std::lock_guard<std::mutex> lock(updateMutex);
      updateReceived = true;
      updateCv.notify_one();
    }
  });

  {
    std::unique_lock<std::mutex> lock(updateMutex);
    EXPECT_TRUE(updateCv.wait_for(lock, std::chrono::seconds(2), [&] {
      return updateReceived;
    })) << "Timed out waiting for test.value update";
  }

  // Verify that the update has been applied: "test.value" should now be 42.
  Json::Value val = monitorUDP.get("test.value");
  EXPECT_EQ(val.asInt(), 42);

  // Cleanup: stop the UDPValueMonitor and shut down the local server.
  monitorUDP.stop();
}

TEST(UDPValueMonitorTest, GetLocalDeviceInformationCallback) {
  const int serverPort = reserveUDPPort();
  if (serverPort <= 0) {
    GTEST_SKIP() << "Failed to reserve UDP port for local test server";
  }
  std::atomic<bool> serverRunning{true};

  std::thread serverThread([&serverRunning, serverPort]() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      return;
    }

    const int reuseAddr = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, sizeof(reuseAddr));
    timeval timeout{.tv_sec = 0, .tv_usec = 100000};
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(serverPort);

    int rc = bind(sock, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
    if (rc != 0) {
      close(sock);
      return;
    }

    char buffer[1024];
    struct sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);

    while (serverRunning.load()) {
      ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                           (struct sockaddr *)&clientAddr, &clientLen);
      if (n < 0) {
        if (errno == EAGAIN || errno == EWOULDBLOCK) {
          continue;
        }
        break;
      }
      buffer[n] = '\0';

      Json::Value deviceInfoEnvelope;
      deviceInfoEnvelope["_fusion_op"] = "get_local_device_information";
      deviceInfoEnvelope["status"] = "success";
      deviceInfoEnvelope["payload"]["id"] = "device-42";
      Json::StreamWriterBuilder writer;
      writer["indentation"] = "";
      std::string responseStr = Json::writeString(writer, deviceInfoEnvelope);

      std::this_thread::sleep_for(std::chrono::milliseconds(100));
      sendto(sock, responseStr.c_str(), responseStr.size(), 0,
             (struct sockaddr *)&clientAddr, clientLen);
      break;
    }

    while (serverRunning.load()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    close(sock);
  });
  ThreadJoiner joinServerThread(serverThread);

  std::mutex callbackMutex;
  std::condition_variable callbackCv;
  bool callbackCalled = false;
  std::string callbackDeviceID;

  UDPValueMonitor monitorUDP("127.0.0.1", serverPort, false);
  monitorUDP.watchDeviceID([&](const std::string &deviceID) {
    std::lock_guard<std::mutex> lock(callbackMutex);
    callbackCalled = true;
    callbackDeviceID = deviceID;
    callbackCv.notify_one();
  });
  monitorUDP.start();

  {
    std::unique_lock<std::mutex> lock(callbackMutex);
    EXPECT_TRUE(callbackCv.wait_for(lock, std::chrono::seconds(2),
                                    [&] { return callbackCalled; }));
    EXPECT_EQ(callbackDeviceID, "device-42");
  }

  monitorUDP.stop();
  serverRunning.store(false);
}

namespace {
bool isEnvEnabled(const char *name) {
  const char *value = std::getenv(name);
  return value != nullptr && value[0] != '\0' && std::string(value) != "0";
}

TEST(UDPValueMonitorTest, ConfigPullRequiredPullsFullConfigOverHTTP) {
  const int udpPort = reserveUDPPort();
  const int httpPort = reserveTCPPort();
  if (udpPort <= 0 || httpPort <= 0) {
    GTEST_SKIP() << "Failed to reserve local ports";
  }

  std::atomic<bool> udpReady{false};
  std::atomic<bool> httpReady{false};

  std::thread httpThread([&]() {
    int sock = socket(AF_INET, SOCK_STREAM, 0);
    if (sock == -1) {
      return;
    }
    const int reuseAddr = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, sizeof(reuseAddr));

    sockaddr_in addr;
    std::memset(&addr, 0, sizeof(addr));
    addr.sin_family = AF_INET;
    addr.sin_addr.s_addr = htonl(INADDR_ANY);
    addr.sin_port = htons(httpPort);
    if (bind(sock, reinterpret_cast<sockaddr *>(&addr), sizeof(addr)) != 0 ||
        listen(sock, 1) != 0) {
      close(sock);
      return;
    }
    httpReady.store(true);

    int client = accept(sock, nullptr, nullptr);
    if (client >= 0) {
      char request[512];
      recv(client, request, sizeof(request), 0);
      const std::string body = "{\"large\":{\"value\":99}}\n";
      std::ostringstream response;
      response << "HTTP/1.0 200 OK\r\n"
               << "Content-Type: application/json\r\n"
               << "Content-Length: " << body.size() << "\r\n\r\n"
               << body;
      const std::string responseStr = response.str();
      send(client, responseStr.c_str(), responseStr.size(), 0);
      close(client);
    }
    close(sock);
  });
  ThreadJoiner joinHTTPThread(httpThread);

  std::thread udpThread([&]() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      return;
    }
    const int reuseAddr = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, sizeof(reuseAddr));
    timeval timeout{.tv_sec = 0, .tv_usec = 100000};
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

    sockaddr_in serverAddr;
    std::memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(udpPort);
    if (bind(sock, reinterpret_cast<sockaddr *>(&serverAddr),
             sizeof(serverAddr)) != 0) {
      close(sock);
      return;
    }
    udpReady.store(true);

    char buffer[1024];
    sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);
    Json::CharReaderBuilder readerBuilder;

    auto receiveJson = [&](Json::Value *request) -> bool {
      for (int attempts = 0; attempts < 30; ++attempts) {
        ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                             reinterpret_cast<sockaddr *>(&clientAddr),
                             &clientLen);
        if (n < 0) {
          if (errno == EAGAIN || errno == EWOULDBLOCK) {
            continue;
          }
          return false;
        }
        buffer[n] = '\0';
        std::string errs;
        std::istringstream stream{std::string(buffer)};
        return Json::parseFromStream(readerBuilder, stream, request, &errs);
      }
      return false;
    };

    Json::Value request;
    if (!receiveJson(&request)) {
      close(sock);
      return;
    }
    Json::Value deviceInfo;
    deviceInfo["_fusion_op"] = "get_local_device_information";
    deviceInfo["status"] = "success";
    deviceInfo["payload"]["id"] = "pull-required-device";
    Json::StreamWriterBuilder writer;
    writer["indentation"] = "";
    const std::string deviceInfoStr = Json::writeString(writer, deviceInfo);
    sendto(sock, deviceInfoStr.c_str(), deviceInfoStr.size(), 0,
           reinterpret_cast<sockaddr *>(&clientAddr), clientLen);

    request.clear();
    if (!receiveJson(&request)) {
      close(sock);
      return;
    }
    Json::Value initialState;
    initialState["_fusion_op"] = "get";
    initialState["status"] = "success";
    initialState["payload"]["small"]["value"] = 1;
    const std::string initialStateStr = Json::writeString(writer, initialState);
    sendto(sock, initialStateStr.c_str(), initialStateStr.size(), 0,
           reinterpret_cast<sockaddr *>(&clientAddr), clientLen);

    Json::Value pullRequired;
    pullRequired["_fusion_op"] = "config_pull_required";
    pullRequired["_fusion_epoch"] = 1;
    pullRequired["_fusion_version"] = 2;
    pullRequired["_fusion_msg_id"] = "pull-required-test";
    const std::string pullRequiredStr = Json::writeString(writer, pullRequired);
    sendto(sock, pullRequiredStr.c_str(), pullRequiredStr.size(), 0,
           reinterpret_cast<sockaddr *>(&clientAddr), clientLen);
    close(sock);
  });
  ThreadJoiner joinUDPThread(udpThread);

  for (int i = 0; i < 50 &&
                  (!udpReady.load() || !httpReady.load()); ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  ASSERT_TRUE(udpReady.load());
  ASSERT_TRUE(httpReady.load());

  std::mutex updateMutex;
  std::condition_variable updateCv;
  bool updateReceived = false;

  UDPValueMonitor monitorUDP("127.0.0.1", udpPort, false, {}, httpPort);
  monitorUDP.watch("large.value", [&](const std::string &, const Json::Value &,
                                      const Json::Value &newValue) {
    if (newValue.isInt() && newValue.asInt() == 99) {
      std::lock_guard<std::mutex> lock(updateMutex);
      updateReceived = true;
      updateCv.notify_one();
    }
  });
  monitorUDP.start();

  {
    std::unique_lock<std::mutex> lock(updateMutex);
    EXPECT_TRUE(updateCv.wait_for(lock, std::chrono::seconds(2), [&] {
      return updateReceived;
    })) << "Timed out waiting for HTTP config pull";
  }

  EXPECT_EQ(monitorUDP.get("large.value").asInt(), 99);
  monitorUDP.stop();
}

TEST(UDPValueMonitorTest, ConfigUpdateClearRemovesWatchedValues) {
  const int serverPort = reserveUDPPort();
  if (serverPort <= 0) {
    GTEST_SKIP() << "Failed to reserve UDP port for local test server";
  }

  std::atomic<bool> serverReady{false};

  std::thread serverThread([&]() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      return;
    }

    const int reuseAddr = 1;
    setsockopt(sock, SOL_SOCKET, SO_REUSEADDR, &reuseAddr, sizeof(reuseAddr));
    timeval timeout{.tv_sec = 0, .tv_usec = 100000};
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

    sockaddr_in serverAddr;
    std::memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(serverPort);
    if (bind(sock, reinterpret_cast<sockaddr *>(&serverAddr),
             sizeof(serverAddr)) != 0) {
      close(sock);
      return;
    }
    serverReady.store(true);

    char buffer[1024];
    sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);
    Json::CharReaderBuilder readerBuilder;

    auto receiveJson = [&](Json::Value *request) -> bool {
      for (int attempts = 0; attempts < 30; ++attempts) {
        ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                             reinterpret_cast<sockaddr *>(&clientAddr),
                             &clientLen);
        if (n < 0) {
          if (errno == EAGAIN || errno == EWOULDBLOCK) {
            continue;
          }
          return false;
        }
        buffer[n] = '\0';
        std::string errs;
        std::istringstream stream{std::string(buffer)};
        return Json::parseFromStream(readerBuilder, stream, request, &errs);
      }
      return false;
    };

    Json::Value request;
    if (!receiveJson(&request) || !request.isMember("action") ||
        request["action"].asString() != "get_local_device_information") {
      close(sock);
      return;
    }

    Json::Value deviceInfoEnvelope;
    deviceInfoEnvelope["_fusion_op"] = "get_local_device_information";
    deviceInfoEnvelope["status"] = "success";
    deviceInfoEnvelope["payload"]["id"] = "test-device";
    Json::StreamWriterBuilder writer;
    writer["indentation"] = "";
    std::string responseStr = Json::writeString(writer, deviceInfoEnvelope);
    sendto(sock, responseStr.c_str(), responseStr.size(), 0,
           reinterpret_cast<sockaddr *>(&clientAddr), clientLen);

    request.clear();
    if (!receiveJson(&request) || !request.isMember("action") ||
        request["action"].asString() != "get") {
      close(sock);
      return;
    }

    Json::Value stateEnvelope;
    stateEnvelope["_fusion_op"] = "get";
    stateEnvelope["status"] = "success";
    stateEnvelope["payload"]["test"]["value"] = 42;
    responseStr = Json::writeString(writer, stateEnvelope);
    sendto(sock, responseStr.c_str(), responseStr.size(), 0,
           reinterpret_cast<sockaddr *>(&clientAddr), clientLen);

    std::this_thread::sleep_for(std::chrono::milliseconds(50));

    Json::Value clearEnvelope;
    clearEnvelope["_fusion_op"] = "config_update";
    clearEnvelope["_fusion_epoch"] = 0;
    clearEnvelope["_fusion_version"] = 1;
    clearEnvelope["_fusion_clear"] = true;
    responseStr = Json::writeString(writer, clearEnvelope);
    sendto(sock, responseStr.c_str(), responseStr.size(), 0,
           reinterpret_cast<sockaddr *>(&clientAddr), clientLen);

    close(sock);
  });
  ThreadJoiner joinServerThread(serverThread);

  for (int i = 0; i < 50 && !serverReady.load(); ++i) {
    std::this_thread::sleep_for(std::chrono::milliseconds(10));
  }
  ASSERT_TRUE(serverReady.load()) << "Server did not become ready";

  std::mutex updateMutex;
  std::condition_variable updateCv;
  bool initialReceived = false;
  bool clearReceived = false;

  UDPValueMonitor monitorUDP("127.0.0.1", serverPort);
  monitorUDP.watch("test.value", [&](const std::string &, const Json::Value &,
                                     const Json::Value &newValue) {
    std::lock_guard<std::mutex> lock(updateMutex);
    if (newValue.isInt() && newValue.asInt() == 42) {
      initialReceived = true;
    }
    if (newValue.isNull()) {
      clearReceived = true;
    }
    updateCv.notify_all();
  });

  {
    std::unique_lock<std::mutex> lock(updateMutex);
    EXPECT_TRUE(updateCv.wait_for(lock, std::chrono::seconds(2),
                                  [&] { return initialReceived; }));
    EXPECT_TRUE(updateCv.wait_for(lock, std::chrono::seconds(2),
                                  [&] { return clearReceived; }));
  }

  EXPECT_TRUE(monitorUDP.get("test.value").isNull());
  EXPECT_TRUE(monitorUDP.get("").empty());

  monitorUDP.stop();
}

bool parseJsonMessage(const char *buffer, ssize_t size, Json::Value *message) {
  Json::CharReaderBuilder readerBuilder;
  readerBuilder["collectComments"] = false;
  std::string errs;
  std::istringstream stream(std::string(buffer, static_cast<size_t>(size)));
  return Json::parseFromStream(readerBuilder, stream, message, &errs);
}

void sendJsonMessage(int sock, const sockaddr_in &clientAddr, socklen_t clientLen,
                     const Json::Value &message) {
  Json::StreamWriterBuilder writer;
  writer["indentation"] = "";
  const std::string response = Json::writeString(writer, message);
  sendto(sock, response.c_str(), response.size(), 0,
         reinterpret_cast<const sockaddr *>(&clientAddr), clientLen);
}

bool parseHostPort(const std::string &addr, std::string *host, int *port) {
  const auto pos = addr.rfind(':');
  if (pos == std::string::npos) {
    return false;
  }
  *host = addr.substr(0, pos);
  if (host->empty()) {
    return false;
  }
  try {
    *port = std::stoi(addr.substr(pos + 1));
  } catch (...) {
    return false;
  }
  return *port > 0;
}

std::string httpBaseForIntegrationHost(const std::string &host) {
  const char *httpAddrEnv = std::getenv("FUSION_HTTP_ADDR");
  if (httpAddrEnv != nullptr && httpAddrEnv[0] != '\0') {
    std::string httpAddr = httpAddrEnv;
    if (httpAddr.rfind("http://", 0) == 0 ||
        httpAddr.rfind("https://", 0) == 0) {
      return httpAddr;
    }
    return "http://" + httpAddr;
  }
  return "http://" + host + ":9090";
}

bool httpPatchJSON(const std::string &host, int httpPort,
                   const std::string &path, const std::string &body,
                   std::string *detail = nullptr) {
  int sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) {
    if (detail != nullptr) {
      *detail = "socket() failed";
    }
    return false;
  }

  timeval timeout{};
  timeout.tv_sec = 5;
  setsockopt(sockfd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
  setsockopt(sockfd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));

  sockaddr_in serverAddr{};
  serverAddr.sin_family = AF_INET;
  serverAddr.sin_port = htons(static_cast<uint16_t>(httpPort));
  if (inet_pton(AF_INET, host.c_str(), &serverAddr.sin_addr) <= 0) {
    if (detail != nullptr) {
      *detail = "inet_pton failed for host " + host;
    }
    close(sockfd);
    return false;
  }
  if (connect(sockfd, reinterpret_cast<sockaddr *>(&serverAddr),
              sizeof(serverAddr)) != 0) {
    if (detail != nullptr) {
      *detail = "connect failed: " + std::string(strerror(errno));
    }
    close(sockfd);
    return false;
  }

  std::ostringstream request;
  request << "PATCH " << path << " HTTP/1.0\r\n"
          << "Host: " << host << ":" << httpPort << "\r\n"
          << "Content-Type: application/json\r\n"
          << "Content-Length: " << body.size() << "\r\n"
          << "Connection: close\r\n\r\n"
          << body;
  const std::string requestStr = request.str();

  size_t sentTotal = 0;
  while (sentTotal < requestStr.size()) {
    ssize_t sent = send(sockfd, requestStr.data() + sentTotal,
                        requestStr.size() - sentTotal, 0);
    if (sent < 0) {
      if (errno == EINTR) {
        continue;
      }
      if (detail != nullptr) {
        *detail = "send failed: " + std::string(strerror(errno));
      }
      close(sockfd);
      return false;
    }
    sentTotal += static_cast<size_t>(sent);
  }

  std::string response;
  char buffer[1024];
  while (true) {
    ssize_t n = recv(sockfd, buffer, sizeof(buffer), 0);
    if (n == 0) {
      break;
    }
    if (n < 0) {
      if (errno == EINTR) {
        continue;
      }
      if (detail != nullptr) {
        *detail = "recv failed: " + std::string(strerror(errno));
      }
      close(sockfd);
      return false;
    }
    response.append(buffer, static_cast<size_t>(n));
    if (response.size() >= 32 && response.find("\r\n") != std::string::npos) {
      break;
    }
  }
  close(sockfd);

  const std::string statusLine = response.substr(0, response.find("\r\n"));
  const bool ok = statusLine.find(" 200 ") != std::string::npos;
  if (!ok && detail != nullptr) {
    *detail = "unexpected HTTP status: " + statusLine;
  }
  return ok;
}

std::string jsonStringLiteral(const std::string &value) {
  Json::Value json(value);
  Json::StreamWriterBuilder writer;
  writer["indentation"] = "";
  return Json::writeString(writer, json);
}
} // namespace

TEST(UDPValueMonitorTest, SendsKeepaliveWhileIdle) {
  const int serverPort = 54323;
  std::atomic<bool> sawKeepalive{false};

  std::thread serverThread([&]() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      return;
    }

    timeval timeout{};
    timeout.tv_sec = 5;
    if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) != 0) {
      close(sock);
      return;
    }

    sockaddr_in serverAddr{};
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(serverPort);
    if (bind(sock, reinterpret_cast<sockaddr *>(&serverAddr), sizeof(serverAddr)) != 0) {
      close(sock);
      return;
    }

    char buffer[1024];
    sockaddr_in clientAddr{};
    socklen_t clientLen = sizeof(clientAddr);

    ssize_t n = recvfrom(sock, buffer, sizeof(buffer), 0,
                         reinterpret_cast<sockaddr *>(&clientAddr), &clientLen);
    if (n <= 0) {
      close(sock);
      return;
    }
    Json::Value request;
    if (!parseJsonMessage(buffer, n, &request) ||
        request["action"].asString() != "get_local_device_information") {
      close(sock);
      return;
    }

    Json::Value deviceInfo;
    deviceInfo["_fusion_op"] = "get_local_device_information";
    deviceInfo["status"] = "success";
    deviceInfo["payload"]["id"] = "keepalive-device";
    sendJsonMessage(sock, clientAddr, clientLen, deviceInfo);

    n = recvfrom(sock, buffer, sizeof(buffer), 0,
                 reinterpret_cast<sockaddr *>(&clientAddr), &clientLen);
    if (n <= 0 || !parseJsonMessage(buffer, n, &request) ||
        request["action"].asString() != "get") {
      close(sock);
      return;
    }

    Json::Value state;
    state["_fusion_op"] = "get";
    state["status"] = "success";
    state["payload"]["test"]["value"] = 1;
    sendJsonMessage(sock, clientAddr, clientLen, state);

    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(3);
    while (std::chrono::steady_clock::now() < deadline && !sawKeepalive.load()) {
      n = recvfrom(sock, buffer, sizeof(buffer), 0,
                   reinterpret_cast<sockaddr *>(&clientAddr), &clientLen);
      if (n <= 0) {
        continue;
      }
      if (!parseJsonMessage(buffer, n, &request)) {
        continue;
      }
      if (request.isMember("action") && request["action"].asString() == "no_op") {
        sawKeepalive.store(true);
        Json::Value noopAck;
        noopAck["_fusion_op"] = "no_op";
        noopAck["status"] = "ok";
        sendJsonMessage(sock, clientAddr, clientLen, noopAck);
      }
    }

    close(sock);
  });

  UDPValueMonitor monitorUDP(
      "127.0.0.1", serverPort, false,
      UDPValueMonitor::TimingConfig{1, 2});
  monitorUDP.watch("test.value",
                   [](const std::string &, const Json::Value &, const Json::Value &) {});
  monitorUDP.start();

  serverThread.join();
  monitorUDP.stop();

  EXPECT_TRUE(sawKeepalive.load());
}

TEST(UDPValueMonitorTest, ReHandshakesAfterKeepaliveAckGap) {
  const int serverPort = 54324;
  std::atomic<bool> reHandshakeObserved{false};

  std::thread serverThread([&]() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      return;
    }

    timeval timeout{};
    timeout.tv_sec = 8;
    if (setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout)) != 0) {
      close(sock);
      return;
    }

    sockaddr_in serverAddr{};
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(serverPort);
    if (bind(sock, reinterpret_cast<sockaddr *>(&serverAddr), sizeof(serverAddr)) != 0) {
      close(sock);
      return;
    }

    char buffer[1024];
    sockaddr_in clientAddr{};
    socklen_t clientLen = sizeof(clientAddr);
    Json::Value request;

    auto recvRequest = [&](const char *expectedAction) {
      const ssize_t n = recvfrom(sock, buffer, sizeof(buffer), 0,
                                 reinterpret_cast<sockaddr *>(&clientAddr), &clientLen);
      if (n <= 0 || !parseJsonMessage(buffer, n, &request) ||
          !request.isMember("action") ||
          request["action"].asString() != expectedAction) {
        request = Json::Value();
      }
    };

    recvRequest("get_local_device_information");
    if (request.isNull()) {
      close(sock);
      return;
    }
    Json::Value deviceInfo;
    deviceInfo["_fusion_op"] = "get_local_device_information";
    deviceInfo["status"] = "success";
    deviceInfo["payload"]["id"] = "rehydrate-device";
    sendJsonMessage(sock, clientAddr, clientLen, deviceInfo);

    recvRequest("get");
    if (request.isNull()) {
      close(sock);
      return;
    }
    Json::Value state;
    state["_fusion_op"] = "get";
    state["status"] = "success";
    state["payload"]["test"]["value"] = 1;
    sendJsonMessage(sock, clientAddr, clientLen, state);

    bool firstNoopAckSent = false;
    bool delayedNoopAckSent = false;
    auto firstAckAt = std::chrono::steady_clock::now();
    const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(6);

    while (std::chrono::steady_clock::now() < deadline) {
      const ssize_t n = recvfrom(sock, buffer, sizeof(buffer), 0,
                                 reinterpret_cast<sockaddr *>(&clientAddr), &clientLen);
      if (n <= 0 || !parseJsonMessage(buffer, n, &request) || !request.isMember("action")) {
        continue;
      }

      const std::string action = request["action"].asString();
      if (action == "no_op") {
        if (!firstNoopAckSent) {
          Json::Value noopAck;
          noopAck["_fusion_op"] = "no_op";
          noopAck["status"] = "ok";
          sendJsonMessage(sock, clientAddr, clientLen, noopAck);
          firstNoopAckSent = true;
          firstAckAt = std::chrono::steady_clock::now();
        } else if (!delayedNoopAckSent &&
                   std::chrono::steady_clock::now() - firstAckAt >= std::chrono::seconds(3)) {
          Json::Value noopAck;
          noopAck["_fusion_op"] = "no_op";
          noopAck["status"] = "ok";
          sendJsonMessage(sock, clientAddr, clientLen, noopAck);
          delayedNoopAckSent = true;
        }
        continue;
      }

      if (delayedNoopAckSent && action == "get_local_device_information") {
        reHandshakeObserved.store(true);
        Json::Value secondDeviceInfo;
        secondDeviceInfo["_fusion_op"] = "get_local_device_information";
        secondDeviceInfo["status"] = "success";
        secondDeviceInfo["payload"]["id"] = "rehydrate-device";
        sendJsonMessage(sock, clientAddr, clientLen, secondDeviceInfo);

        recvRequest("get");
        if (request.isNull()) {
          close(sock);
          return;
        }
        Json::Value secondState;
        secondState["_fusion_op"] = "get";
        secondState["status"] = "success";
        secondState["payload"]["test"]["value"] = 99;
        sendJsonMessage(sock, clientAddr, clientLen, secondState);
        break;
      }
    }

    close(sock);
  });

  UDPValueMonitor monitorUDP(
      "127.0.0.1", serverPort, false,
      UDPValueMonitor::TimingConfig{1, 2});
  monitorUDP.watch("test.value",
                   [](const std::string &, const Json::Value &, const Json::Value &) {});
  monitorUDP.start();

  Json::Value val;
  const auto deadline = std::chrono::steady_clock::now() + std::chrono::seconds(7);
  while (std::chrono::steady_clock::now() < deadline) {
    val = monitorUDP.get("test.value");
    if (val.isInt() && val.asInt() == 99) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
  }

  serverThread.join();
  monitorUDP.stop();

  EXPECT_TRUE(reHandshakeObserved.load());
  ASSERT_TRUE(val.isInt());
  EXPECT_EQ(val.asInt(), 99);
}

TEST(UDPValueMonitorTest, IntegrationWithFusionServer) {
  if (!isEnvEnabled("FUSION_UDP_INTEGRATION")) {
    GTEST_SKIP() << "Set FUSION_UDP_INTEGRATION=1 to enable this test.";
  }

  const char *addrEnv = std::getenv("FUSION_UDP_ADDR");
  std::string addr = addrEnv ? addrEnv : "127.0.0.1:7947";

  std::string host;
  int port = 0;
  ASSERT_TRUE(parseHostPort(addr, &host, &port))
      << "Invalid FUSION_UDP_ADDR (expected host:port): " << addr;

  if (host == "localhost") {
    host = "127.0.0.1";
  }

  std::string httpHost;
  int httpPort = 0;
  std::string httpBase = httpBaseForIntegrationHost(host);
  if (httpBase.rfind("http://", 0) == 0) {
    httpBase = httpBase.substr(std::strlen("http://"));
  }
  ASSERT_TRUE(parseHostPort(httpBase, &httpHost, &httpPort))
      << "Invalid FUSION_HTTP_ADDR (expected host:port): " << httpBase;
  if (httpHost == "localhost") {
    httpHost = "127.0.0.1";
  }

  UDPValueMonitor monitorUDP(host, port, false, {}, httpPort);
  monitorUDP.watch("observer_test.value", [](const std::string &, const Json::Value &, const Json::Value &) {});
  monitorUDP.start();
  std::this_thread::sleep_for(std::chrono::milliseconds(250));

  const int expected = 42;
  const std::string body = "{\"observer_test\":{\"value\":42}}";
  std::string patchDetail;
  ASSERT_TRUE(httpPatchJSON(httpHost, httpPort, "/state", body, &patchDetail))
      << "Failed to PATCH observer_test.value via fusion-server admin state API: "
      << patchDetail;

  Json::Value val;
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(2);
  while (std::chrono::steady_clock::now() < deadline) {
    val = monitorUDP.get("observer_test.value");
    if (val.isInt() && val.asInt() == expected) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
  }

  EXPECT_EQ(val.asInt(), expected);
  monitorUDP.stop();
}

TEST(UDPValueMonitorTest, IntegrationOversizedUpdatePullsConfigFromFusionServer) {
  if (!isEnvEnabled("FUSION_UDP_INTEGRATION")) {
    GTEST_SKIP() << "Set FUSION_UDP_INTEGRATION=1 to enable this test.";
  }

  const char *addrEnv = std::getenv("FUSION_UDP_ADDR");
  std::string addr = addrEnv ? addrEnv : "127.0.0.1:7947";

  std::string host;
  int udpPort = 0;
  ASSERT_TRUE(parseHostPort(addr, &host, &udpPort))
      << "Invalid FUSION_UDP_ADDR (expected host:port): " << addr;

  if (host == "localhost") {
    host = "127.0.0.1";
  }

  std::string httpHost;
  int httpPort = 0;
  std::string httpBase = httpBaseForIntegrationHost(host);
  if (httpBase.rfind("http://", 0) == 0) {
    httpBase = httpBase.substr(std::strlen("http://"));
  }
  ASSERT_TRUE(parseHostPort(httpBase, &httpHost, &httpPort))
      << "Invalid FUSION_HTTP_ADDR (expected host:port): " << httpBase;
  if (httpHost == "localhost") {
    httpHost = "127.0.0.1";
  }
  ASSERT_EQ(httpHost, host)
      << "UDPValueMonitor HTTP pull uses the UDP host; set FUSION_UDP_ADDR and "
         "FUSION_HTTP_ADDR to the same host for this test";

  const auto unique =
      std::chrono::steady_clock::now().time_since_epoch().count();
  const std::string rootKey = "observer_pull_required_" + std::to_string(unique);
  const std::string path = rootKey + ".value";
  const std::string expectedPrefix = "pull-required-";
  const std::string expected =
      expectedPrefix + std::to_string(unique) + "-" + std::string(70 * 1024, 'x');

  UDPValueMonitor monitorUDP(host, udpPort, false, {}, httpPort);
  monitorUDP.watch(path, [](const std::string &, const Json::Value &,
                            const Json::Value &) {});
  monitorUDP.start();
  std::this_thread::sleep_for(std::chrono::milliseconds(250));

  const std::string body = "{\"" + rootKey + "\":{\"value\":" +
                           jsonStringLiteral(expected) + "}}";
  std::string patchDetail;
  ASSERT_TRUE(httpPatchJSON(httpHost, httpPort, "/state", body, &patchDetail))
      << "Failed to PATCH oversized config value: " << patchDetail;

  Json::Value val;
  const auto deadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(10);
  while (std::chrono::steady_clock::now() < deadline) {
    val = monitorUDP.get(path);
    if (val.isString() && val.asString() == expected) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  const std::string cleanupBody = "{\"" + rootKey + "\":{\"value\":\"\"}}";
  (void)httpPatchJSON(httpHost, httpPort, "/state", cleanupBody);
  monitorUDP.stop();

  ASSERT_TRUE(val.isString()) << "Observer did not receive pulled config value";
  EXPECT_EQ(val.asString(), expected);
}

TEST(UDPValueMonitorTest, IntegrationDeleteValueBroadcastClearsObserverState) {
  if (!isEnvEnabled("FUSION_UDP_INTEGRATION")) {
    GTEST_SKIP() << "Set FUSION_UDP_INTEGRATION=1 to enable this test.";
  }

  const char *addrEnv = std::getenv("FUSION_UDP_ADDR");
  std::string addr = addrEnv ? addrEnv : "127.0.0.1:7947";

  std::string host;
  int udpPort = 0;
  ASSERT_TRUE(parseHostPort(addr, &host, &udpPort))
      << "Invalid FUSION_UDP_ADDR (expected host:port): " << addr;

  if (host == "localhost") {
    host = "127.0.0.1";
  }

  std::string httpHost;
  int httpPort = 0;
  std::string httpBase = httpBaseForIntegrationHost(host);
  if (httpBase.rfind("http://", 0) == 0) {
    httpBase = httpBase.substr(std::strlen("http://"));
  }
  ASSERT_TRUE(parseHostPort(httpBase, &httpHost, &httpPort))
      << "Invalid FUSION_HTTP_ADDR (expected host:port): " << httpBase;
  if (httpHost == "localhost") {
    httpHost = "127.0.0.1";
  }
  ASSERT_EQ(httpHost, host)
      << "UDPValueMonitor HTTP pull uses the UDP host; set FUSION_UDP_ADDR and "
         "FUSION_HTTP_ADDR to the same host for this test";

  const auto unique =
      std::chrono::steady_clock::now().time_since_epoch().count();
  const std::string rootKey =
      "observer_delete_integration_" + std::to_string(unique);
  const std::string path = rootKey + ".value";
  const std::string expected = "delete-broadcast-" + std::to_string(unique);

  UDPValueMonitor monitorUDP(host, udpPort, false, {}, httpPort);
  monitorUDP.watch(path, [](const std::string &, const Json::Value &,
                            const Json::Value &) {});
  monitorUDP.start();
  std::this_thread::sleep_for(std::chrono::milliseconds(250));

  const std::string body = "{\"" + rootKey + "\":{\"value\":" +
                           jsonStringLiteral(expected) + "}}";
  std::string patchDetail;
  ASSERT_TRUE(httpPatchJSON(httpHost, httpPort, "/state", body, &patchDetail))
      << "Failed to PATCH seed value before delete: " << patchDetail;

  Json::Value val;
  const auto patchDeadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(5);
  while (std::chrono::steady_clock::now() < patchDeadline) {
    val = monitorUDP.get(path);
    if (val.isString() && val.asString() == expected) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }
  ASSERT_TRUE(val.isString()) << "Observer did not receive seeded value";
  ASSERT_EQ(val.asString(), expected);

  const std::string clearBody = "{\"" + rootKey + "\":null}";
  std::string deleteDetail;
  ASSERT_TRUE(httpPatchJSON(httpHost, httpPort, "/state", clearBody, &deleteDetail))
      << "Failed to PATCH /state null clear: " << deleteDetail;

  const auto clearDeadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(5);
  while (std::chrono::steady_clock::now() < clearDeadline) {
    val = monitorUDP.get(path);
    if (val.isNull()) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(100));
  }

  monitorUDP.stop();

  EXPECT_TRUE(val.isNull())
      << "Observer did not clear watched value after PATCH /state null clear";
}
