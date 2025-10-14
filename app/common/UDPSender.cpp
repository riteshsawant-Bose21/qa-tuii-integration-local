/*  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 */

#include "UDPSender.h"
#include <boost/asio.hpp>
#include <iostream>

// Include OCA logging macros - OcfLiteHostInterface.h contains the OCA_LOG_* macros
#include "../../common/HostInterfaceLite/OCA/OCF/OcfLiteHostInterface.h"

using udp = boost::asio::ip::udp;

UDPSender::UDPSender()
    : m_ioContext(nullptr),
      m_workGuard(std::nullopt),
      m_socket(nullptr),
      m_serverEndpoint(),
      m_remoteEndpoint()
{
    // Constructor is private for singleton pattern
}

UDPSender::~UDPSender()
{
    shutdown();
}

UDPSender &UDPSender::getInstance()
{
    static UDPSender instance;
    return instance;
}

bool UDPSender::initialize(const std::string &serverIP,
                           unsigned int serverPort)
{
    if (m_initialized.load())
    {
        OCA_LOG_INFO("UDPSender already initialized");
        return true;
    }

    try
    {
        // Create ASIO components + work guard to keep run() alive
        m_ioContext = std::make_unique<boost::asio::io_context>();
        m_workGuard.emplace(boost::asio::make_work_guard(*m_ioContext));

        // Create and open socket
        m_socket = std::make_unique<udp::socket>(*m_ioContext);
        m_socket->open(udp::v4());

        // Bind to an ephemeral local port so receives work immediately
        m_socket->bind(udp::endpoint(udp::v4(), 0));

        // Resolve server endpoint
        udp::resolver resolver(*m_ioContext);
        auto results = resolver.resolve(serverIP, std::to_string(serverPort));
        if (results.begin() == results.end())
        {
            OCA_LOG_ERROR("Failed to resolve server host/port");
            shutdown();
            return false;
        }
        m_serverEndpoint = *results.begin();

        // Start async receive before pumping the IO thread
        startAsyncReceive();

        // Dedicated IO thread to drive handlers
        m_ioThread = std::make_unique<std::thread>([this]
                                                   {
            try
            {
                m_ioContext->run();
            }
            catch (const std::exception &e)
            {
                OCA_LOG_ERROR_PARAMS("io_context::run() error: %s", e.what());
            } });

        // Worker for the send queue
        m_running = true;
        m_workerThread = std::make_unique<std::thread>(&UDPSender::workerThreadFunction, this);

        m_initialized = true;
        OCA_LOG_INFO_PARAMS("✓ UDPSender initialized successfully (server: %s:%d)",
                            m_serverEndpoint.address().to_string().c_str(),
                            static_cast<int>(m_serverEndpoint.port()));
        return true;
    }
    catch (const std::exception &e)
    {
        OCA_LOG_ERROR_PARAMS("✗ UDPSender initialization failed: %s", e.what());
        shutdown();
        return false;
    }
}

void UDPSender::shutdown()
{
    if (!m_initialized.load())
    {
        return;
    }

    OCA_LOG_INFO("Shutting down UDPSender...");

    // Stop the worker thread (queue producer/consumer)
    m_running = false;
    m_queueCondition.notify_all();

    // Cancel outstanding async ops, then close the socket
    if (m_socket)
    {
        boost::system::error_code ec;
        m_socket->cancel(ec);
        if (ec)
        {
            OCA_LOG_ERROR_PARAMS("Error cancelling UDP ops: %s", ec.message().c_str());
        }
        m_socket->close(ec);
        if (ec)
        {
            OCA_LOG_ERROR_PARAMS("Error closing UDP socket: %s", ec.message().c_str());
        }
    }

    // Let io_context finish naturally and then stop
    if (m_workGuard)
    {
        m_workGuard.reset(); // allow run() to exit when there’s no more work
    }
    if (m_ioContext)
    {
        m_ioContext->stop();
    }

    // Join threads
    if (m_workerThread && m_workerThread->joinable())
    {
        m_workerThread->join();
    }
    if (m_ioThread && m_ioThread->joinable())
    {
        m_ioThread->join();
    }

    // Clean up
    m_workerThread.reset();
    m_ioThread.reset();
    m_socket.reset();
    m_ioContext.reset();

    m_initialized = false;
    OCA_LOG_INFO("UDPSender shutdown complete");
}

void UDPSender::sendMessage(const std::string &jsonMessage)
{
    if (!m_initialized.load())
    {
        OCA_LOG_ERROR("UDPSender not initialized - cannot send message");
        return;
    }

    if (jsonMessage.empty())
    {
        OCA_LOG_ERROR("Cannot send empty message");
        return;
    }

    // Thread-safe message queuing
    {
        std::lock_guard<std::mutex> lock(m_queueMutex);
        m_messageQueue.push(jsonMessage);
    }

    // Notify worker thread
    m_queueCondition.notify_one();

    OCA_LOG_INFO_PARAMS("Message queued for sending (%zu bytes)", jsonMessage.length());
}

bool UDPSender::isInitialized() const
{
    return m_initialized.load();
}

void UDPSender::workerThreadFunction()
{
    OCA_LOG_INFO("UDPSender worker thread started");

    while (m_running.load())
    {
        // Wait for messages or shutdown signal
        std::unique_lock<std::mutex> lock(m_queueMutex);
        m_queueCondition.wait(lock, [this]
                              { return !m_messageQueue.empty() || !m_running.load(); });

        // Process all queued messages
        while (!m_messageQueue.empty() && m_running.load())
        {
            std::string message = std::move(m_messageQueue.front());
            m_messageQueue.pop();
            lock.unlock();

            // Enqueue async send onto the io_context thread
            doAsyncSend(message);

            lock.lock();
        }
    }

    OCA_LOG_INFO("UDPSender worker thread stopped");
}

void UDPSender::doAsyncSend(const std::string &message)
{
    if (!m_socket || !m_socket->is_open())
    {
        OCA_LOG_ERROR("UDP socket not open - cannot send");
        return;
    }

    // Keep message buffer alive until handler completes
    auto buf = std::make_shared<std::string>(message);

    // Log the actual message content being sent
    OCA_LOG_INFO_PARAMS("UDP message content: %s", message.c_str());

    // Ensure initiation happens on the io_context thread
    boost::asio::post(*m_ioContext, [this, buf]()
                      { m_socket->async_send_to(
                            boost::asio::buffer(*buf), m_serverEndpoint,
                            [this, buf](const boost::system::error_code &ec, std::size_t bytesSent)
                            {
                                if (!ec)
                                {
                                    OCA_LOG_INFO_PARAMS("UDP message sent (%zu bytes to %s:%d)",
                                                        bytesSent,
                                                        m_serverEndpoint.address().to_string().c_str(),
                                                        static_cast<int>(m_serverEndpoint.port()));
                                }
                                else
                                {
                                    OCA_LOG_ERROR_PARAMS("UDP async send error: %s", ec.message().c_str());
                                }
                            }); });
}

void UDPSender::startAsyncReceive()
{
    if (!m_socket || !m_socket->is_open())
    {
        return;
    }

    m_socket->async_receive_from(
        boost::asio::buffer(m_receiveBuffer.data(), m_receiveBuffer.size()),
        m_remoteEndpoint,
        [this](const boost::system::error_code ec, std::size_t bytesReceived)
        {
            if (!ec && m_running.load())
            {
                handleAckReceived(m_receiveBuffer, bytesReceived, m_remoteEndpoint);
                // Continue receiving
                startAsyncReceive();
            }
            else if (ec && m_running.load())
            {
                OCA_LOG_ERROR_PARAMS("UDP receive error: %s", ec.message().c_str());
                // Try to restart receive operation
                startAsyncReceive();
            }
        });
}

void UDPSender::handleAckReceived(const std::array<char, 1024> &buffer,
                                  std::size_t bytesReceived,
                                  const udp::endpoint &from)
{
    // Basic logging of ACK receipt and source
    OCA_LOG_INFO_PARAMS("ACK received (%zu bytes) from %s:%d",
                        bytesReceived,
                        from.address().to_string().c_str(),
                        static_cast<int>(from.port()));

    // Optional: parse/validate ACK payload
    // std::string_view ack(buffer.data(), bytesReceived);
    // OCA_LOG_INFO_PARAMS("ACK payload: %.*s", (int)ack.size(), ack.data());

    (void)buffer;
    (void)bytesReceived;
}
