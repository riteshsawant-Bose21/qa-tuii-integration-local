// nc -6 -ul 7948
// {"vip":"192.168.64.100/24","host":"192.168.64.2","cluster":["192.168.64.2","192.168.64.5","192.168.64.4"],"ts":1759455527}
// {"vip":"192.168.64.100/24","host":"192.168.64.2","cluster":["192.168.64.4","192.168.64.2","192.168.64.5"],"ts":1759455557}

#include <iostream>
#include <string>
#include <array>
#include <csignal>
#include <unistd.h>
#include <arpa/inet.h>
#include <netinet/in.h>

#include "nlohmann/json.hpp"

using json = nlohmann::json;

static bool keepRunning = true;
void signalHandler(int) { keepRunning = false; }

int main(int argc, char* argv[])
{
    int port = 7948;
    if (argc > 1) port = std::stoi(argv[1]);

    // Create IPv6 UDP socket
    int sock = socket(AF_INET6, SOCK_DGRAM, 0);
    if (sock < 0) {
        perror("socket");
        return 1;
    }

    // Allow both IPv6 and IPv4-mapped addresses
    int off = 0;
    if (setsockopt(sock, IPPROTO_IPV6, IPV6_V6ONLY, &off, sizeof(off)) < 0)
        perror("setsockopt(IPV6_V6ONLY)");

    // Bind to all IPv6 addresses (and IPv4 via v4-mapped)
    sockaddr_in6 addr{};
    addr.sin6_family = AF_INET6;
    addr.sin6_addr = in6addr_any;
    addr.sin6_port = htons(port);

    if (bind(sock, (struct sockaddr*)&addr, sizeof(addr)) < 0) {
        perror("bind");
        close(sock);
        return 1;
    }

    struct timeval tv{1, 0};
    setsockopt(sock, SOL_SOCKET, SO_RCVTIMEO, &tv, sizeof(tv));

    std::cout << "Listening for IPv6 (and IPv4) heartbeats on UDP port "
              << port << "..." << std::endl;

    std::signal(SIGINT, signalHandler);

    while (keepRunning) {
        std::array<char, 2048> buffer{};
        sockaddr_in6 srcAddr{};
        socklen_t srcLen = sizeof(srcAddr);

        ssize_t len = recvfrom(sock, buffer.data(), buffer.size() - 1, 0,
                               (struct sockaddr*)&srcAddr, &srcLen);
        if (len < 0) {
            if (errno == EWOULDBLOCK || errno == EAGAIN)
                continue;
            if (keepRunning)
                perror("recvfrom");
            break;
        }

        buffer[len] = '\0';
        std::string payload(buffer.data());

        char srcIP[INET6_ADDRSTRLEN];
        inet_ntop(AF_INET6, &srcAddr.sin6_addr, srcIP, sizeof(srcIP));

        try {
            auto j = json::parse(payload);
            std::cout << "From [" << srcIP << "]:" << ntohs(srcAddr.sin6_port) << std::endl;
            std::cout << j.dump(4) << std::endl;
        } catch (const std::exception& e) {
            std::cerr << "Invalid JSON: " << payload << std::endl;
        }
    }

    close(sock);
    std::cout << "Shutting down." << std::endl;
    return 0;
}
