#include "observer.h"
#include <arpa/inet.h>
#include <atomic>
#include <chrono>
#include <cstring>
#include <gtest/gtest.h>
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

    ssize_t n = recvfrom(sock, buffer, sizeof(buffer) - 1, 0,
                         (struct sockaddr *)&clientAddr, &clientLen);
    if (n > 0) {
      buffer[n] = '\0';

      Json::Value response;
      Json::Value nested;
      nested["value"] = 42;
      response["test"] = nested;

      // Send as "initial state" envelope so version checks are skipped.
      Json::Value envelope;
      envelope["status"] = "ok";
      envelope["data"] = response;
      Json::FastWriter writer;
      std::string responseStr = writer.write(envelope);

      sendto(sock, responseStr.c_str(), responseStr.size(), 0,
             (struct sockaddr *)&clientAddr, clientLen);
    }

    while (serverRunning.load()) {
      std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }
    close(sock);
  });

  std::vector<std::string> targetPaths = {"test.value"};
  UDPValueMonitor monitorUDP("127.0.0.1", serverPort, targetPaths, false);

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
