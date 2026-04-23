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

bool sendExternalUDPPatchProcess(const std::string &host, int port, bool mute) {
  const pid_t pid = fork();
  if (pid < 0) {
    return false;
  }

  if (pid == 0) {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      _exit(2);
    }

    timeval timeout{};
    timeout.tv_sec = 2;
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));

    sockaddr_in serverAddr;
    std::memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_port = htons(port);
    if (inet_pton(AF_INET, host.c_str(), &serverAddr.sin_addr) <= 0) {
      close(sock);
      _exit(3);
    }

    Json::Value update;
    update["action"] = "patch";
    update["payload"]["audio"]["settings"]["gain_block"]["mute"] = mute;

    Json::StreamWriterBuilder writerBuilder;
    writerBuilder["indentation"] = "";
    const std::string payload = Json::writeString(writerBuilder, update);
    const ssize_t sent =
        sendto(sock, payload.c_str(), payload.size(), 0,
               reinterpret_cast<const sockaddr *>(&serverAddr),
               sizeof(serverAddr));
    if (sent != static_cast<ssize_t>(payload.size())) {
      close(sock);
      _exit(4);
    }

    char buffer[1024];
    const ssize_t received = recvfrom(sock, buffer, sizeof(buffer), 0, nullptr, nullptr);
    close(sock);
    if (received <= 0) {
      _exit(5);
    }

    const std::string response(buffer, static_cast<size_t>(received));
    if (response.find("\"status\":\"success\"") == std::string::npos) {
      _exit(6);
    }

    _exit(0);
  }

  int status = 0;
  if (waitpid(pid, &status, 0) != pid) {
    return false;
  }
  return WIFEXITED(status) && WEXITSTATUS(status) == 0;
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

  UDPValueMonitor monitorUDP(host, port, false);
  monitorUDP.watch("observer_test.value", [](const std::string &, const Json::Value &, const Json::Value &) {});
  monitorUDP.start();

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

TEST(UDPValueMonitorTest, IntegrationExternalUDPPatchPropagationWithFusionServer) {
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

  ASSERT_TRUE(sendExternalUDPPatchProcess(host, port, false))
      << "Failed to set baseline mute=false through external UDP process";

  std::mutex updateMutex;
  std::condition_variable updateCv;
  bool truePatchReceived = false;

  UDPValueMonitor monitorUDP(host, port, false);
  monitorUDP.watch("audio.settings.gain_block.mute",
                   [&](const std::string &, const Json::Value &, const Json::Value &newValue) {
                     if (newValue.isBool() && newValue.asBool()) {
                       std::lock_guard<std::mutex> lock(updateMutex);
                       truePatchReceived = true;
                       updateCv.notify_one();
                     }
                   });
  monitorUDP.start();

  Json::Value baseline;
  const auto baselineDeadline =
      std::chrono::steady_clock::now() + std::chrono::seconds(3);
  while (std::chrono::steady_clock::now() < baselineDeadline) {
    baseline = monitorUDP.get("audio.settings.gain_block.mute");
    if (baseline.isBool() && !baseline.asBool()) {
      break;
    }
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
  }

  ASSERT_TRUE(baseline.isBool()) << "Timed out waiting for initial mute baseline";
  ASSERT_FALSE(baseline.asBool()) << "Expected mute=false baseline before true patch";

  ASSERT_TRUE(sendExternalUDPPatchProcess(host, port, true))
      << "Failed to send mute=true patch through external UDP process";

  {
    std::unique_lock<std::mutex> lock(updateMutex);
    EXPECT_TRUE(updateCv.wait_for(lock, std::chrono::seconds(3), [&] {
      return truePatchReceived;
    })) << "Timed out waiting for observer to receive external UDP patch";
  }

  Json::Value val = monitorUDP.get("audio.settings.gain_block.mute");
  ASSERT_TRUE(val.isBool());
  EXPECT_TRUE(val.asBool());
  monitorUDP.stop();
}
