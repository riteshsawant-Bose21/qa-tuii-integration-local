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

  // Start a fake UDP server in a separate thread.
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

  // Cleanup: stop the UDPValueMonitor and shut down the fake server.
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

  UDPValueMonitor monitorUDP("127.0.0.1", serverPort);

  std::mutex callbackMutex;
  std::condition_variable callbackCv;
  bool callbackCalled = false;
  std::string callbackDeviceID;

  monitorUDP.watchDeviceID([&](const std::string &deviceID) {
    std::lock_guard<std::mutex> lock(callbackMutex);
    callbackCalled = true;
    callbackDeviceID = deviceID;
    callbackCv.notify_one();
  });

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
} // namespace

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

  UDPValueMonitor monitorUDP(host, port);
  monitorUDP.watch("observer_test.value", [](const std::string &, const Json::Value &, const Json::Value &) {});

  const int expected = 42;
  Json::Value update;
  update["action"] = "put";
  update["payload"]["observer_test"]["value"] = expected;

  int sock = socket(AF_INET, SOCK_DGRAM, 0);
  ASSERT_NE(sock, -1) << "Failed to create UDP client socket";

  sockaddr_in serverAddr;
  std::memset(&serverAddr, 0, sizeof(serverAddr));
  serverAddr.sin_family = AF_INET;
  serverAddr.sin_port = htons(port);
  ASSERT_GT(inet_pton(AF_INET, host.c_str(), &serverAddr.sin_addr), 0)
      << "Invalid server address: " << host;

  Json::StreamWriterBuilder writerBuilder;
  writerBuilder["indentation"] = "";
  const std::string payload = Json::writeString(writerBuilder, update);
  const ssize_t sent =
      sendto(sock, payload.c_str(), payload.size(), 0,
             reinterpret_cast<const sockaddr *>(&serverAddr),
             sizeof(serverAddr));
  close(sock);
  ASSERT_EQ(sent, static_cast<ssize_t>(payload.size()))
      << "Failed to send UDP update";

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
