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

class WallControllerSimulator {
private:
    std::string controller_id;
    std::string host;
    int port;
    int socket_fd;
    std::atomic<bool> connected;
    std::atomic<bool> identified;
    std::atomic<bool> running;
    
    struct DeviceInfo {
        std::string id;
        std::string deviceType;
        std::string firmwareVersion;
    } device_info;

public:
    WallControllerSimulator(const std::string& id = "WC001", 
                           const std::string& h = "localhost", 
                           int p = 7950) 
        : controller_id(id), host(h), port(p), socket_fd(-1),
          connected(false), identified(false), running(false) {
        
        device_info.id = id;
        device_info.deviceType = "WallController";
        device_info.firmwareVersion = "1.0.0";
    }
    
    ~WallControllerSimulator() {
        disconnect();
    }

private:
    void log(const std::string& level, const std::string& message) {
        auto now = std::chrono::system_clock::now();
        auto time_t = std::chrono::system_clock::to_time_t(now);
        auto ms = std::chrono::duration_cast<std::chrono::milliseconds>(
            now.time_since_epoch()) % 1000;
        
        std::cout << std::put_time(std::localtime(&time_t), "%Y-%m-%d %H:%M:%S");
        std::cout << "." << std::setfill('0') << std::setw(3) << ms.count();
        std::cout << " - WallController-" << controller_id << " - " 
                  << level << " - " << message << std::endl;
    }
    
    void info(const std::string& message) { log("INFO", message); }
    void error(const std::string& message) { log("ERROR", message); }
    void warning(const std::string& message) { log("WARNING", message); }

    std::string parseJson(const std::string& json, const std::string& key) {
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
    
    std::string parseJsonObject(const std::string& json, const std::string& key) {
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

    bool sendMessage(const std::string& json) {
        try {
            std::string message = json + "\n";
            ssize_t sent = send(socket_fd, message.c_str(), message.length(), 0);
            
            if (sent < 0) {
                error("❌ Failed to send message: " + std::string(strerror(errno)));
                return false;
            }
            
            info("📤 Sent: " + json);
            return true;
            
        } catch (const std::exception& e) {
            error("❌ Failed to send message: " + std::string(e.what()));
            return false;
        }
    }

    void handleMessage(const std::string& message_str) {
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

    void handleIdentify(const std::string& /* payload */) {
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

    void handleWink(const std::string& payload) {
        std::string duration_str = parseJson(payload, "duration");
        int duration = duration_str.empty() ? 5000 : std::stoi(duration_str);
        
        info("💡 Received wink command (duration: " + std::to_string(duration) + "ms)");
        
        // Send starting response
        std::string start_response = "{\"action\": \"winkResponse\", \"payload\": {\"status\": \"starting\"}}";
        
        if (sendMessage(start_response)) {
            info("💡 Winking started...");
            
            // Start wink thread
            std::thread wink_thread([this, duration]() {
                std::this_thread::sleep_for(std::chrono::milliseconds(duration));
                
                std::string done_response = "{\"action\": \"winkResponse\", \"payload\": {\"status\": \"done\"}}";
                
                if (sendMessage(done_response)) {
                    info("✅ Winking completed!");
                }
            });
            
            wink_thread.detach();
        }
    }

    void messageHandler() {
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
                
                ssize_t bytes_received = recv(socket_fd, recv_buffer, sizeof(recv_buffer) - 1, 0);
                
                if (bytes_received < 0) {
                    error("❌ Error receiving message: " + std::string(strerror(errno)));
                    break;
                } else if (bytes_received == 0) {
                    warning("⚠️  Server closed connection");
                    break;
                }
                
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
            
        } catch (const std::exception& e) {
            error("❌ Message handler error: " + std::string(e.what()));
        }
        
        disconnect();
    }

public:
    bool connect() {
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
            struct hostent* server = gethostbyname(host.c_str());
            if (server == nullptr) {
                error("❌ Failed to resolve hostname: " + host);
                close(socket_fd);
                return false;
            }
            
            // Setup server address
            struct sockaddr_in server_addr;
            memset(&server_addr, 0, sizeof(server_addr));
            server_addr.sin_family = AF_INET;
            server_addr.sin_port = htons(port);
            memcpy(&server_addr.sin_addr.s_addr, server->h_addr, server->h_length);
            
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
            
            // Start message handler thread
            std::thread handler_thread(&WallControllerSimulator::messageHandler, this);
            handler_thread.detach();
            
            return true;
            
        } catch (const std::exception& e) {
            error("❌ Failed to connect: " + std::string(e.what()));
            return false;
        }
    }
    
    void disconnect() {
        running = false;
        connected = false;
        
        if (socket_fd >= 0) {
            close(socket_fd);
            info("🔌 Disconnected from server");
            socket_fd = -1;
        }
    }
    
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
};

// Global simulator instance for signal handler
WallControllerSimulator* g_simulator = nullptr;

void signalHandler(int /* sig */) {
    std::cout << "\n🛑 Shutting down..." << std::endl;
    if (g_simulator) {
        g_simulator->disconnect();
    }
    exit(0);
}

int main(int argc, char* argv[]) {
    // Register signal handler
    signal(SIGINT, signalHandler);
    signal(SIGTERM, signalHandler);
    
    // Parse command line arguments
    std::string controller_id = (argc > 1) ? argv[1] : "WC001";
    std::string host = (argc > 2) ? argv[2] : "localhost";
    int port = (argc > 3) ? std::stoi(argv[3]) : 7950;
    
    std::cout << "🚀 Starting Wall Controller Simulator (C++)" << std::endl;
    std::cout << "   Controller ID: " << controller_id << std::endl;
    std::cout << "   Target: " << host << ":" << port << std::endl;
    std::cout << "   Protocol: JSON over TCP" << std::endl;
    std::cout << std::endl;
    
    // Create and run simulator
    WallControllerSimulator simulator(controller_id, host, port);
    g_simulator = &simulator;
    
    bool success = simulator.run();
    
    if (success) {
        std::cout << "✅ Simulator completed successfully" << std::endl;
    } else {
        std::cout << "❌ Simulator failed" << std::endl;
        return 1;
    }
    
    return 0;
}