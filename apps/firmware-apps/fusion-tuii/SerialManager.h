/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description : SerialManager - boost::asio-based serial port I/O
 */

#ifndef SERIALMANAGER_H
#define SERIALMANAGER_H

#include <atomic>
#include <cstddef>
#include <cstdint>
#include <functional>
#include <mutex>
#include <string>
#include <thread>

#include <boost/asio.hpp>

// Frame format (little-endian): SOF(4) | CRC16(2) | LEN(1) | PAYLOAD(LEN)
static constexpr std::size_t HEADER_SIZE = 7;

class SerialManager
{
public:
    using ReceiveCallback = std::function<void(const char *buf, std::size_t len)>;

    static SerialManager &getInstance();

    bool initialize(const std::string &device);
    void shutdown();

    // Returns false if not initialized, payload exceeds 255 bytes, or a write error occurs.
    bool send(const char *buf, std::size_t len);
    void setReceiveCallback(ReceiveCallback callback);

    bool isInitialized() const noexcept;

private:
    SerialManager();
    ~SerialManager() noexcept;

    // Two-phase frame reader: 7-byte header then LEN-byte payload
    void startReadHeader();
    void handleHeaderRead(const boost::system::error_code &ec);
    void processHeader();
    void startReadPayload(uint16_t expectedCrc, uint8_t len);
    void handlePayloadRead(const boost::system::error_code &ec, uint16_t expectedCrc, uint8_t len);

    // Bad-SOF recovery: byte-by-byte sliding-window scan for the SOF pattern
    void startResync();
    void handleResyncByte(const boost::system::error_code &ec);

    // Called for each validated frame; stub out the body in SerialManager.cc
    void handleSerialData(const char *buf, std::size_t bytesRead);

    // CRC-16/CCITT-FALSE (poly=0x1021, init=0xFFFF, no reflection, no final XOR).
    // Pass a running crc to chain over multiple buffers.
    static uint16_t crc16Ccitt(const uint8_t *data, std::size_t len,
                               uint16_t crc = 0xFFFFU) noexcept;

    boost::asio::io_context                                              m_ioContext;
    boost::asio::serial_port                                             m_serialPort;
    boost::asio::executor_work_guard<boost::asio::io_context::executor_type> m_workGuard;
    std::thread                                                          m_ioThread;
    uint8_t                                                              m_headerBuf[HEADER_SIZE]{};
    uint8_t                                                              m_payloadBuf[256]{};
    uint8_t                                                              m_resyncByte{};
    uint8_t                                                              m_resyncFill{};
    std::mutex                                                           m_callbackMutex;
    ReceiveCallback                                                      m_receiveCallback;
    std::atomic<bool>                                                    m_initialized;
    std::string                                                          m_device;

    SerialManager(const SerialManager &) = delete;
    SerialManager &operator=(const SerialManager &) = delete;
};

#endif // SERIALMANAGER_H
