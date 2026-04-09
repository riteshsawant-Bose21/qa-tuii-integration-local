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

TEST(UDPValueMonitorTest, AsynchronousUpdatesAndNetworking) {

  const int serverPort = 54321;
  std::atomic<bool> serverRunning{true};

  // Start a fake UDP server in a separate thread.
  std::thread serverThread([&serverRunning]() {
    // Create the UDP socket for the server.
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    ASSERT_NE(sock, -1) << "Server failed to create socket";

    struct sockaddr_in serverAddr;
    memset(&serverAddr, 0, sizeof(serverAddr));
    serverAddr.sin_family = AF_INET;
    serverAddr.sin_addr.s_addr = htonl(INADDR_ANY);
    serverAddr.sin_port = htons(serverPort);

    int rc = bind(sock, (struct sockaddr *)&serverAddr, sizeof(serverAddr));
    ASSERT_EQ(rc, 0) << "Server failed to bind socket";

    char buffer[1024];
    struct sockaddr_in clientAddr;
    socklen_t clientLen = sizeof(clientAddr);
    Json::CharReaderBuilder readerBuilder;
    readerBuilder["collectComments"] = false;

    // 1) Expect device-info request.
    ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                         (struct sockaddr *)&clientAddr, &clientLen);
    if (n > 0) {
      buffer[n] = '\0';

      Json::Value request;
      std::string errs;
      std::istringstream reqStream{std::string(buffer)};
      if (!Json::parseFromStream(readerBuilder, reqStream, &request, &errs)) {
        close(sock);
        return;
      }
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
    }

    // 2) Expect state request.
    n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                 (struct sockaddr *)&clientAddr, &clientLen);
    if (n > 0) {
      buffer[n] = '\0';

      Json::Value request;
      std::string errs;
      std::istringstream reqStream{std::string(buffer)};
      if (!Json::parseFromStream(readerBuilder, reqStream, &request, &errs)) {
        close(sock);
        return;
      }
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
    }

    while (serverRunning.load()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    close(sock);
  });

  UDPValueMonitor monitorUDP("127.0.0.1", serverPort);
  monitorUDP.watch("test.value", [](const std::string &, const Json::Value &, const Json::Value &) {});

  // Allow some time for asynchronous processing (the receive thread picks up
  // the response).
  std::this_thread::sleep_for(std::chrono::milliseconds(300));

  // Verify that the update has been applied: "test.value" should now be 42.
  Json::Value val = monitorUDP.get("test.value");
  EXPECT_EQ(val.asInt(), 42);

  // Cleanup: stop the UDPValueMonitor and shut down the fake server.
  monitorUDP.stop();
  serverRunning.store(false);
  if (serverThread.joinable()) {
    serverThread.join();
  }
}

TEST(UDPValueMonitorTest, GetLocalDeviceInformationCallback) {
  const int serverPort = 54322;
  std::atomic<bool> serverRunning{true};

  std::thread serverThread([&serverRunning]() {
    int sock = socket(AF_INET, SOCK_DGRAM, 0);
    if (sock == -1) {
      return;
    }

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

    ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                         (struct sockaddr *)&clientAddr, &clientLen);
    if (n > 0) {
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
    }

    while (serverRunning.load()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    close(sock);
  });

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
  if (serverThread.joinable()) {
    serverThread.join();
  }
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
  update["action"] = "set";
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
