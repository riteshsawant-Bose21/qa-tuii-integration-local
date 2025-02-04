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
      Json::FastWriter writer;
      std::string responseStr = writer.write(response);

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

void testReceiveLoop() {
  // We want to watch the "test.value" path.
  std::vector<std::string> targetPaths = {"test.value"};
  // Create the monitor.
  // For this test, we set the server IP to "127.0.0.1" and an arbitrary port
  // (e.g., 12345).
  UDPValueMonitor monitor("127.0.0.1", 12345, targetPaths, true);

  // Retrieve the local port assigned to the monitor.
  int localPort = monitor.getLocalPort();
  std::cout << "Monitor is bound to local port: " << localPort << std::endl;
  assert(localPort > 0);

  // Create a separate UDP socket to send a test message.
  int testSock = socket(AF_INET, SOCK_DGRAM, 0);
  if (testSock < 0) {
    std::cerr << "Failed to create test socket." << std::endl;
    return;
  }

  // Set up the destination address (the monitor's local address).
  sockaddr_in destAddr;
  std::memset(&destAddr, 0, sizeof(destAddr));
  destAddr.sin_family = AF_INET;
  destAddr.sin_port = htons(localPort);
  if (inet_pton(AF_INET, "127.0.0.1", &destAddr.sin_addr) <= 0) {
    std::cerr << "Invalid destination address." << std::endl;
    close(testSock);
    return;
  }

  // Construct a JSON update message. For instance, update "test.value" to 42.
  Json::Value update;
  update["test"]["value"] = 42;
  Json::StreamWriterBuilder writer;
  std::string jsonStr = Json::writeString(writer, update);
  std::cout << "Sending JSON update: " << jsonStr << std::endl;

  // Send the JSON update via UDP.
  ssize_t sent = sendto(testSock, jsonStr.c_str(), jsonStr.size(), 0,
                        (struct sockaddr *)&destAddr, sizeof(destAddr));
  assert(sent == static_cast<ssize_t>(jsonStr.size()));
  // Prevent unused variable warning in release builds where assert
  // may be disabled.
  (void)sent;

  // Wait a short time to allow the receive loop to pick up the message.
  std::this_thread::sleep_for(std::chrono::milliseconds(200));

  // Retrieve the updated value from the monitor's JSON state.
  Json::Value result = monitor.get("test.value");
  std::cout << "Retrieved update for 'test.value': " << result << std::endl;

  // Verify that the update was processed correctly.
  assert(result.asInt() == 42);

  // Clean up the test socket and stop the monitor.
  close(testSock);
  monitor.stop();
}
