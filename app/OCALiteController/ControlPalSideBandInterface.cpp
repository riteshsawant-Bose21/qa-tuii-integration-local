/**
 * Wall Controller Simulator (C++)
 *
 * This C++ program simulates a wall controller that connects to the Fusion Server
 * on port 7950 and implements the JSON protocol with identification and wink commands.
 *
 * Compilation:
 *   g++ -std=c++17 -o wall_controller_simulator wall_controller_simulator.cpp -pthread
 *
 * Usage:
 *   ./wall_controller_simulator [controller_id] [host] [port]
 *
 * Protocol:
 * - Server sends: {"action": "identify", "payload": {"timestamp": 123456}}
 * - Controller responds: {"action": "identity", "payload": {"id": "WC001", "deviceType": "WallController", "firmwareVersion": "1.0.0"}}
 * - Server sends: {"action": "performWink", "payload": {"duration": 5000, "timestamp": 123456}}
 * - Controller responds: {"action": "winkResponse", "payload": {"status": "starting"}}
 * - Controller responds: {"action": "winkResponse", "payload": {"status": "done"}}
 */

#include <iostream>
#include <string>
#include <thread>
#include <atomic>
#include <chrono>
#include <sstream>
#include <vector>
#include <signal.h>
#include <unistd.h>
#include <sys/socket.h>
//#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <cstring>
#include <iomanip>
#include "HostInterface/CommandInterface/CommandInterface.h"
#include "ControlPalMsgInterface.h"
#include "ControlPalSideBandInterface.h"


// C interface for mDNS service discovery
extern "C" {
#ifdef STM32H7S7xx
#include "dnssd.h"
#endif
}

bool SidebandInterface::sendMessage(const std::string& json)
{
    try {
        std::string message = json + "\n";
        ssize_t sent = send(socket_fd, message.c_str(), message.length(), 0);

        if (sent < 0) {
            error("❌ Failed to send message: " + std::string(strerror(errno)));
            return false;
        }
        return true;

    } catch (const std::exception& e) {
        error("❌ Failed to send message: " + std::string(e.what()));
        return false;
    }
}

std::string SidebandInterface::parseJson(const std::string& json, const std::string& key) {
    // Simple JSON parser for our specific use case
    std::string search = "\"" + key + "\":";
    size_t pos = json.find(search);
    if (pos == std::string::npos) return "";

    pos += search.length();
    while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t')) pos++;

    if (pos >= json.length()) return "";

    if (json[pos] == '"') {
        // String value
        pos++;
        size_t end = json.find('"', pos);
        if (end == std::string::npos) return "";
        return json.substr(pos, end - pos);
    } else {
        // Number value
        size_t end = pos;
        while (end < json.length() && (isdigit(json[end]) || json[end] == '.')) end++;
        return json.substr(pos, end - pos);
    }
}

std::string SidebandInterface::parseJsonObject(const std::string& json, const std::string& key) {
    // Extract object value
    std::string search = "\"" + key + "\":";
    size_t pos = json.find(search);
    if (pos == std::string::npos) return "";

    pos += search.length();
    while (pos < json.length() && (json[pos] == ' ' || json[pos] == '\t')) pos++;

    if (pos >= json.length() || json[pos] != '{') return "";

    int brace_count = 1;
    size_t start = pos;
    pos++;

    while (pos < json.length() && brace_count > 0) {
        if (json[pos] == '{') brace_count++;
        else if (json[pos] == '}') brace_count--;
        pos++;
    }

    return json.substr(start, pos - start);
}

void SidebandInterface::handleMessage(const std::string& message_str) {
    try {
        info("📥 Received: " + message_str);

        std::string action = parseJson(message_str, "action");
        std::string payload = parseJsonObject(message_str, "payload");

        if (action == "identify") {
            handleIdentify(payload);
        } else if (action == "performWink") {
            handleWink(payload);
        } else {
            warning("⚠️  Unknown action: " + action);
        }

    } catch (const std::exception& e) {
        error("❌ Error handling message: " + std::string(e.what()));
    }
}

void SidebandInterface::handleIdentify(const std::string& /* payload */) {
    info("🔍 Server requested identification");

    // Send identity response
    std::ostringstream response;
    response << "{"
        << "\"action\": \"identity\", "
        << "\"payload\": {"
        << "\"id\": \"" << device_info.id << "\", "
        << "\"deviceType\": \"" << device_info.deviceType << "\", "
        << "\"firmwareVersion\": \"" << device_info.firmwareVersion << "\""
        << "}"
        << "}";

    if (sendMessage(response.str())) {
        identified = true;
        info("✅ Sent identification: " + controller_id);
    }
}

void SidebandInterface::handleWink(const std::string& payload) {
    std::string duration_str = parseJson(payload, "duration");
    int duration = duration_str.empty() ? 5000 : std::stoi(duration_str);

    info("💡 Received wink command (duration: " + std::to_string(duration) + "ms)");

    // Send starting response
    std::string start_response = "{\"action\": \"winkResponse\", \"payload\": {\"status\": \"starting\"}}";

    if (sendMessage(start_response)) {
        info("💡 Winking started...");

        ControllerCmdIntfc msg;
        msg.cmd         = CTRL_CMD_WINK_SET;
        msg.val.int_val = duration;
        msg.ono         = 0;  // Don't care

        SetUiMsg(msg);
        SendValue(); // Send frontend wink message
    }
}

void SidebandInterface::messageHandler() {
    std::string buffer;
    char recv_buffer[1024];

    try {
        //while (running && connected) {
        if (running && connected) {
            // Set timeout for recv
            struct timeval timeout;
            timeout.tv_sec = 0;
            timeout.tv_usec = 100;

            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(socket_fd, &read_fds);

            int result = select(socket_fd + 1, &read_fds, nullptr, nullptr, &timeout);

            if (result < 0) {
                error("❌ Select error: " + std::string(strerror(errno)));
            }
            else if (result > 0) {

                ssize_t bytes_received = recv(socket_fd, recv_buffer,
                        sizeof(recv_buffer) - 1, 0);

                if (bytes_received < 0) {
                    error("❌ Error receiving message: " + std::string(strerror(errno)));
                } else if (bytes_received > 0) {

                    recv_buffer[bytes_received] = '\0';
                    buffer += std::string(recv_buffer);

                    // Process complete lines
                    size_t pos;
                    while ((pos = buffer.find('\n')) != std::string::npos) {
                        std::string line = buffer.substr(0, pos);
                        buffer = buffer.substr(pos + 1);

                        // Trim whitespace
                        line.erase(0, line.find_first_not_of(" \t\r\n"));
                        line.erase(line.find_last_not_of(" \t\r\n") + 1);

                        if (!line.empty()) {
                            handleMessage(line);
                        }
                    }
                }
            }
        }

    } catch (const std::exception& e) {
        error("❌ Message handler error: " + std::string(e.what()));
    }
}

bool SidebandInterface::sideBandDiscovery(OcaServiceDiscovery &discovery) {

    bool retVal(false);

    // Start service discovery
    if (discovery.StartDiscovery())
    {
        // Wait for devices to be discovered
        size_t deviceCount(0);
        uint8_t retry_cnt(0);

        // Retry loop
        while ( (deviceCount <= 0 ) && (retry_cnt++ < 100))
        {
            deviceCount = discovery.WaitForDevices(100);
        }

        if (deviceCount > 0)
            retVal = true;
    }

    return retVal;
}

bool SidebandInterface::sideBandConnect() {

    OcaServiceDiscovery discovery;

    if (sideBandDiscovery(discovery)) {
        try {
            // Create socket
            socket_fd = socket(AF_INET, SOCK_STREAM, 0);
            if (socket_fd < 0) {
                error("❌ Failed to create socket: " + std::string(strerror(errno)));
                return false;
            }

            // Set socket timeout
            struct timeval timeout;
            timeout.tv_sec = 10;
            timeout.tv_usec = 0;
            setsockopt(socket_fd, SOL_SOCKET, SO_RCVTIMEO, &timeout, sizeof(timeout));
            setsockopt(socket_fd, SOL_SOCKET, SO_SNDTIMEO, &timeout, sizeof(timeout));

            // Setup server address
            struct sockaddr_in server_addr;
            memset(&server_addr, 0, sizeof(server_addr));
            server_addr.sin_family = AF_INET;

#ifndef STM32H7S7xx
            auto discoveredDevices = discovery.GetDiscoveredDevices();
            const auto &selectedDevice = discoveredDevices[0];
            //server_addr.sin_port = htons(selectedDevice.port); // TODO: Replace after device advertising
            server_addr.sin_port = htons(7950); // TODO: Replace after device advertising
                                                //       is enabled.

            const char *hostOrIp = selectedDevice.hostname.c_str();
            struct hostent *hostEntry = gethostbyname(hostOrIp);
            if (hostEntry == nullptr)
            {
                // Try to treat it as an IP address directly
                if (inet_aton(hostOrIp, &server_addr.sin_addr) == 0)
                {
                    error("❌ Failed to resolve hostname: " + selectedDevice.hostname);
                    return false;
                }
            }
            else
            {
                // Use the first IP address from the host entry
                memcpy(&server_addr.sin_addr, hostEntry->h_addr_list[0], hostEntry->h_length);
            }
#else
            // Get discovered OCA service IP from mDNS
            oca_service_info_t service_info;
            if (get_oca_service_info(&service_info)) {
                server_addr.sin_addr.s_addr = inet_addr(service_info.ip_address);
                server_addr.sin_port = htons(7950); // TODO: Replace after device advertising
                                                    //       is enabled.
                //server_addr.sin_port = htons(service_info.port); // Use discovered port
                host = std::string(service_info.ip_address);
                info("Using mDNS discovered service: " + host + ":" + std::to_string(port));
            } else {
                // Fallback to hardcoded IP if mDNS discovery not complete
                server_addr.sin_addr.s_addr = inet_addr("192.168.0.167");
                info("mDNS not complete, using fallback: " + host + ":" + std::to_string(port));
            }
#endif

            discovery.StopDiscovery();
            info("Connecting to Fusion Server at " + host + ":" + std::to_string(port) + "...");

            // Connect
            if (::connect(socket_fd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
                error("❌ Failed to connect: " + std::string(strerror(errno)));
                close(socket_fd);
                return false;
            }

            connected = true;
            running = true;
            info("✅ Connected to Fusion Server successfully!");

        } catch (const std::exception& e) {
            error("❌ Failed to connect: " + std::string(e.what()));
            return false;
        }
        return true;
    }
    return false;
}

void SidebandInterface::sideBandDisconnect() {
    running = false;
    connected = false;

    if (socket_fd >= 0) {
        close(socket_fd);
        info("🔌 Disconnected from server");
        socket_fd = -1;
    }
}

