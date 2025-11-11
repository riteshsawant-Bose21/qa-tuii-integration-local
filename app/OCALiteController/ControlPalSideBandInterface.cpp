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
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <cstring>
#include <iomanip>
#include "HostInterface/CommandInterface/CommandInterface.h"
#include "ControlPalMsgInterface.h"
#include "ControlPalSideBandInterface.h"

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
        while (running && connected) {
            // Set timeout for recv
            struct timeval timeout;
            timeout.tv_sec = 1;
            timeout.tv_usec = 0;

            fd_set read_fds;
            FD_ZERO(&read_fds);
            FD_SET(socket_fd, &read_fds);

            int result = select(socket_fd + 1, &read_fds, nullptr, nullptr, &timeout);

            if (result < 0) {
                error("❌ Select error: " + std::string(strerror(errno)));
                break;
            } else if (result == 0) {
                // Timeout, continue
                continue;
            }

            ssize_t bytes_received = recv(socket_fd, recv_buffer,
                                          sizeof(recv_buffer) - 1, 0);

            if (bytes_received < 0) {
                error("❌ Error receiving message: " + std::string(strerror(errno)));
                break;
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

    } catch (const std::exception& e) {
        error("❌ Message handler error: " + std::string(e.what()));
    }

    disconnect();
}

bool SidebandInterface::connect() {
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

        // Resolve hostname
#if 0   // TODO: Resolve support needed
        struct hostent* server = gethostbyname(host.c_str());
        if (server == nullptr) {
            error("❌ Failed to resolve hostname: " + host);
            close(socket_fd);
            return false;
        }
#endif

        char *addr = {"192.168.0.167"}; // DEBUG

        // Setup server address
        struct sockaddr_in server_addr;
        memset(&server_addr, 0, sizeof(server_addr));
        server_addr.sin_family = AF_INET;
        server_addr.sin_port = htons(port);
        //memcpy(&server_addr.sin_addr.s_addr, server->h_addr, server->h_length);
        memcpy(&server_addr.sin_addr.s_addr, addr, sizeof(addr));

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

#if 0
        // Start message handler thread
        std::thread handler_thread(&SidebandInterface::messageHandler, this);
        handler_thread.detach();
#endif

        return true;

    } catch (const std::exception& e) {
        error("❌ Failed to connect: " + std::string(e.what()));
        return false;
    }
}

void SidebandInterface::disconnect() {
    running = false;
    connected = false;

    if (socket_fd >= 0) {
        close(socket_fd);
        info("🔌 Disconnected from server");
        socket_fd = -1;
    }
}

#if 0
bool run() {
    if (!connect()) {
        return false;
    }

    try {
        info("🎯 Controller simulator running. Press Ctrl+C to exit...");

        // Keep the main thread alive
        while (running && connected) {
            std::this_thread::sleep_for(std::chrono::seconds(1));
        }

    } catch (const std::exception& e) {
        error("❌ Runtime error: " + std::string(e.what()));
    }

    disconnect();
    return true;
}
#endif


