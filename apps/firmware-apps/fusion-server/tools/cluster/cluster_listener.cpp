// nc -4 -kul 127.0.0.1 7948
//{"event":"gained","host":"192.168.64.4","timestamp":1760577087,"vip":"192.168.2.100"}

#include "nlohmann/json.hpp"
#include <arpa/inet.h>
#include <array>
#include <csignal>
#include <iostream>
#include <netinet/in.h>
#include <string>
#include <unistd.h>

using json = nlohmann::json;

static bool keepRunning = true;
void signalHandler(int) { keepRunning = false; }

int main(int argc, char *argv[]) {
  int port = 7948;
  if (argc > 1)
    port = std::stoi(argv[1]);

  // Create IPv4 UDP socket
  int sock = socket(AF_INET, SOCK_DGRAM, 0);
  if (sock < 0) {
    perror("socket");
    return 1;
  }

  sockaddr_in addr{};
  addr.sin_family = AF_INET;
  addr.sin_addr.s_addr = inet_addr("127.0.0.1");
  addr.sin_port = htons(port);

  if (bind(sock, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
    perror("bind");
    close(sock);
    return 1;
  }

  struct timeval tv{1, 0};
  setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

  std::cout << "Listening for IPv4 heartbeats on UDP port " << port << "..."
            << std::endl;

  std::signal(SIGINT, signalHandler);

  while (keepRunning) {
    std::array<char, 2048> buffer{};
    sockaddr_in srcAddr{};
    socklen_t srcLen = sizeof(srcAddr);

    ssize_t len = recvfrom(sock, buffer.data(), buffer.size() - 1, 0,
                           (struct sockaddr *)&srcAddr, &srcLen);
    if (len < 0) {
      if (errno == EWOULDBLOCK || errno == EAGAIN)
        continue;
      if (keepRunning)
        perror("recvfrom");
      break;
    }

    buffer[len] = '\0';
    std::string payload(buffer.data());

    char srcIP[INET_ADDRSTRLEN];
    inet_ntop(AF_INET, &srcAddr.sin_addr, srcIP, sizeof(srcIP));

    try {
      auto j = json::parse(payload);
      std::cout << "From [" << srcIP << "]:" << ntohs(srcAddr.sin_port)
                << std::endl;
      std::cout << j.dump(4) << std::endl;
    } catch (const std::exception &) {
      std::cerr << "Invalid JSON: " << payload << std::endl;
    }
  }

  close(sock);
  std::cout << "Shutting down." << std::endl;
  return 0;
}
