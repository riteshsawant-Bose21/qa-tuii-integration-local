/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

#ifndef UDPSENDER_H
#define UDPSENDER_H

#include <string>
#include <queue>
#include <mutex>
#include <condition_variable>
#include <thread>
#include <atomic>
#include <memory>
#include <array>
#include <optional>

#include <boost/asio.hpp>

/**
 * @brief Singleton UDP sender class for sending JSON messages to a server and receiving ACKs.
 *
 * Key points:
 *  - Binds the UDP socket to an ephemeral local port so async receives work immediately.
 *  - Runs a dedicated io_context thread with a work guard so handlers are always serviced.
 *  - Maintains a separate worker thread for a thread-safe send queue.
 *  - Uses async_send_to and async_receive_from; no polling needed.
 */
class UDPSender
{
public:
    /**
     * @brief Get the singleton instance
     * @return Reference to the singleton instance
     */
    static UDPSender &getInstance();

    /**
     * @brief Send a JSON message asynchronously
     *
     * Thread-safe and non-blocking. The message is queued and sent by the worker thread.
     * ACK receipt is logged automatically.
     *
     * @param jsonMessage The JSON string to send
     */
    void sendMessage(const std::string &jsonMessage);

    /**
     * @brief Initialize the UDP sender (call during startup)
     * @return true if initialization successful, false otherwise
     */
    bool initialize(const std::string &serverIP,
                    unsigned int serverPort);

    /**
     * @brief Check if the UDP sender is initialized
     * @return true if initialized and ready to send, false otherwise
     */
    bool isInitialized() const;

    /**
     * @brief Shutdown the UDP sender (call during cleanup)
     */
    void shutdown();

private:
    // Singleton pattern - private constructor/destructor
    UDPSender();
    ~UDPSender();

    // Delete copy constructor and assignment operator
    UDPSender(const UDPSender &) = delete;
    UDPSender &operator=(const UDPSender &) = delete;

    /**
     * @brief Worker thread function that processes the message queue
     */
    void workerThreadFunction();

    /**
     * @brief Enqueue an async UDP send operation on the io_context thread
     * @param message The message to send
     */
    void doAsyncSend(const std::string &message);

    /**
     * @brief Start receiving ACKs asynchronously
     */
    void startAsyncReceive();

    /**
     * @brief Handle received ACK data
     * @param buffer The received data buffer
     * @param bytesReceived Number of bytes received
     * @param from Endpoint the datagram came from
     */
    void handleAckReceived(const std::array<char, 1024> &buffer,
                           std::size_t bytesReceived,
                           const boost::asio::ip::udp::endpoint &from);

private:
    static constexpr std::size_t BUFFER_SIZE = 1024;

    // Asio types
    using udp = boost::asio::ip::udp;
    using work_guard_t = boost::asio::executor_work_guard<boost::asio::io_context::executor_type>;

    // Network components
    std::unique_ptr<boost::asio::io_context> m_ioContext;
    std::optional<work_guard_t> m_workGuard;
    std::unique_ptr<udp::socket> m_socket;
    udp::endpoint m_serverEndpoint;
    udp::endpoint m_remoteEndpoint;
    std::array<char, BUFFER_SIZE> m_receiveBuffer{};

    // Message queue and threading
    std::queue<std::string> m_messageQueue;
    std::mutex m_queueMutex;
    std::condition_variable m_queueCondition;

    std::atomic<bool> m_running{false};
    std::atomic<bool> m_initialized{false};

    std::unique_ptr<std::thread> m_workerThread;
    std::unique_ptr<std::thread> m_ioThread;
};

#endif // UDPSENDER_H
