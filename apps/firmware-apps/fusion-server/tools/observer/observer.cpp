#include <sys/socket.h>
#include <sys/un.h>
#include <json/json.h>
#include <functional>
#include <map>
#include <string>
#include <iostream>
#include <thread>
#include <unistd.h>
#include <cstring>
#include <atomic>

// Define callback type for key/value changes
using KeyValueCallback = std::function<void(const std::string&, 
                                          const std::string&, 
                                          const std::string&)>;

class KeyValueMonitor {
public:
    KeyValueMonitor() : running_(false), sock_fd_(-1) {}

    ~KeyValueMonitor() {
        stop();
    }

    // Register a callback for a specific key
    void watchKey(const std::string& key, const KeyValueCallback& callback) {
        callbacks_[key] = callback;
    }

    // Remove a callback for a specific key
    void unwatchKey(const std::string& key) {
        callbacks_.erase(key);
    }

    // Connect to the Unix domain socket
    bool connect(const std::string& socket_path) {
        sock_fd_ = socket(AF_UNIX, SOCK_STREAM, 0);
        if (sock_fd_ == -1) {
            std::cerr << "Failed to create socket: " << strerror(errno) << std::endl;
            return false;
        }

        struct sockaddr_un addr;
        memset(&addr, 0, sizeof(addr));
        addr.sun_family = AF_UNIX;
        strncpy(addr.sun_path, socket_path.c_str(), sizeof(addr.sun_path) - 1);

        if (::connect(sock_fd_, (struct sockaddr*)&addr, sizeof(addr)) == -1) {
            std::cerr << "Failed to connect: " << strerror(errno) << std::endl;
            close(sock_fd_);
            return false;
        }

        std::cout << "Connected to Unix domain socket" << std::endl;
        return true;
    }

    // Start monitoring for messages
    void run() {
        running_ = true;
        read_thread_ = std::thread(&KeyValueMonitor::readLoop, this);
    }

    // Gracefully stop monitoring
    void stop() {
        running_ = false;
        if (sock_fd_ != -1) {
            close(sock_fd_);
            sock_fd_ = -1;
        }
        if (read_thread_.joinable()) {
            read_thread_.join();
        }
    }

private:
    void readLoop() {
        char buffer[4096];
        while (running_) {
            ssize_t bytes_read = read(sock_fd_, buffer, sizeof(buffer) - 1);
            
            if (bytes_read <= 0) {
                if (bytes_read == 0) {
                    std::cout << "Server closed connection" << std::endl;
                } else {
                    std::cerr << "Read error: " << strerror(errno) << std::endl;
                }
                
                // Attempt to reconnect
                if (running_) {
                    std::cout << "Connection lost. Attempting to reconnect..." << std::endl;
                    close(sock_fd_);
                    // Wait before attempting to reconnect
                    std::this_thread::sleep_for(std::chrono::seconds(5));
                }
                break;
            }

            buffer[bytes_read] = '\0';
            handleMessage(std::string(buffer, bytes_read));
        }
    }

    void handleMessage(const std::string& payload) {
        Json::Value root;
        Json::Reader reader;

        if (!reader.parse(payload, root)) {
            std::cout << "Failed to parse message: " << payload << std::endl;
            return;
        }

        // Expect message format: {"key": "somekey", "oldValue": "...", "newValue": "..."}
        const auto key = root["key"].asString();
        const auto oldValue = root["oldValue"].asString();
        const auto newValue = root["newValue"].asString();

        if (const auto it = callbacks_.find(key); it != callbacks_.end()) {
            it->second(key, oldValue, newValue);
        }
    }

    std::atomic<bool> running_;
    int sock_fd_;
    std::thread read_thread_;
    std::map<std::string, KeyValueCallback> callbacks_;
};

// Example usage
int main() {
    KeyValueMonitor monitor;

    // Register a callback for the "status" key
    monitor.watchKey("status", [](const std::string& key, 
                                const std::string& oldValue, 
                                const std::string& newValue) {
        std::cout << key << "status changed from " << oldValue << " to " << newValue << std::endl;
        
        if (newValue == "error") {
            // Handle error state
            std::cout << "System entered error state!" << std::endl;
        } else if (newValue == "active") {
            // Handle active state
            std::cout << "System is now active" << std::endl;
        }
    });

    // Register a callback for the "volume" key
    monitor.watchKey("volume", [](const std::string& key, 
                                     const std::string& oldValue, 
                                     const std::string& newValue) {
        const auto previous = std::stod(oldValue);
        const auto current = std::stod(newValue);
        std::cout << key << "previous: " << previous << "current: " << current << std::endl;
    });

    // Connect to the Unix domain socket
    if (!monitor.connect("/tmp/kvmonitor.sock")) {
        return 1;
    }

    // Run the monitoring loop
    monitor.run();

    // Wait for signal to quit
    std::cout << "Press Enter to quit..." << std::endl;
    std::cin.get();

    monitor.stop();
    return 0;
}