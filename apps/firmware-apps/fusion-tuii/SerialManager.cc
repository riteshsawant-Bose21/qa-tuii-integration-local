/*
 *  By downloading or using this file, the user agrees to be bound by the terms of the license
 *  agreement located in the LICENSE file in the root of this project
 *  as an original contracting party.
 *
 *  Description : SerialManager - boost::asio-based serial port I/O
 */

#include <array>
#include <cstdint>
#include <utility>

#include <spdlog/spdlog.h>
#include <spdlog/fmt/bin_to_hex.h>

#include "SerialManager.h"

// ---- Singleton ----

SerialManager &SerialManager::getInstance()
{
    static SerialManager instance;
    return instance;
}

// ---- Constructor / Destructor ----

SerialManager::SerialManager()
    : m_serialPort(m_ioContext),
      m_workGuard(boost::asio::make_work_guard(m_ioContext)),
      m_initialized(false)
{
}

SerialManager::~SerialManager() noexcept
{
    shutdown();
}

// ---- Public API ----

bool SerialManager::initialize(const std::string &device)
{
    if (m_initialized.load())
    {
        spdlog::info("[SerialManager] Already initialized");
        return true;
    }

    m_device = device;

    try
    {
        m_serialPort.open(device);

        m_serialPort.set_option(boost::asio::serial_port_base::baud_rate(115200));
        m_serialPort.set_option(boost::asio::serial_port_base::character_size(8));
        m_serialPort.set_option(boost::asio::serial_port_base::parity(
            boost::asio::serial_port_base::parity::none));
        m_serialPort.set_option(boost::asio::serial_port_base::stop_bits(
            boost::asio::serial_port_base::stop_bits::one));
        m_serialPort.set_option(boost::asio::serial_port_base::flow_control(
            boost::asio::serial_port_base::flow_control::none));

        m_initialized.store(true);

        // Arm the first header read before the io_context thread starts
        startReadHeader();

        // Run io_context on a dedicated thread
        m_ioThread = std::thread([this]() {
            m_ioContext.run();
        });

        spdlog::info("[SerialManager] Initialized on {} at 115200 8N1", device);
        return true;
    }
    catch (const boost::system::system_error &e)
    {
        spdlog::error("[SerialManager] Failed to open {}: {}", device, e.what());
        return false;
    }
}

void SerialManager::shutdown()
{
    if (!m_initialized.load())
        return;

    m_initialized.store(false);

    // Release the work guard so io_context can finish
    m_workGuard.reset();

    boost::system::error_code ec;
    m_serialPort.close(ec);
    if (ec)
    {
        spdlog::warn("[SerialManager] Warning: error closing serial port: {}", ec.message());
    }

    m_ioContext.stop();

    if (m_ioThread.joinable())
    {
        m_ioThread.join();
    }

    spdlog::info("[SerialManager] Shutdown complete");
}

bool SerialManager::send(const char *buf, std::size_t len)
{
    if (!m_initialized.load())
    {
        spdlog::warn("[SerialManager] Not initialized - cannot send");
        return false;
    }

    if (len > 255)
    {
        spdlog::error("[SerialManager] Payload too large ({} bytes, max 255)", len);
        return false;
    }

    // ---- Build framed packet: SOF(4 LE) | CRC16(2 LE) | LEN(1) | PAYLOAD ----
    //
    // CRC-16/CCITT-FALSE is computed over [LEN, PAYLOAD].
    // All multi-byte fields are little-endian on the wire.

    constexpr uint32_t SOF = 0xA5B5C5D5U;
    const uint8_t lenByte  = static_cast<uint8_t>(len);

    uint16_t crc = crc16Ccitt(&lenByte, 1);
    crc          = crc16Ccitt(reinterpret_cast<const uint8_t *>(buf), len, crc);

    uint8_t header[7];
    header[0] = static_cast<uint8_t>( SOF        & 0xFFU);
    header[1] = static_cast<uint8_t>((SOF >>  8) & 0xFFU);
    header[2] = static_cast<uint8_t>((SOF >> 16) & 0xFFU);
    header[3] = static_cast<uint8_t>((SOF >> 24) & 0xFFU);
    header[4] = static_cast<uint8_t>( crc        & 0xFFU);
    header[5] = static_cast<uint8_t>((crc >>  8) & 0xFFU);
    header[6] = lenByte;

    try
    {
        const std::array<boost::asio::const_buffer, 2> scatter = {{
            boost::asio::buffer(header, sizeof(header)),
            boost::asio::buffer(buf, len)
        }};
        boost::asio::write(m_serialPort, scatter);
    }
    catch (const boost::system::system_error &e)
    {
        spdlog::error("[SerialManager] Send failed: {}", e.what());
        return false;
    }

    return true;
}

void SerialManager::setReceiveCallback(ReceiveCallback callback)
{
    std::lock_guard<std::mutex> lock(m_callbackMutex);
    m_receiveCallback = std::move(callback);
}

bool SerialManager::isInitialized() const noexcept
{
    return m_initialized.load();
}

// ---- Private helpers ----

namespace {
// SOF 0xA5B5C5D5 serialised little-endian: first byte on wire is 0xD5
constexpr uint8_t SOF_WIRE[4] = {0xD5U, 0xC5U, 0xB5U, 0xA5U};
} // namespace

// --- Phase 1: read the 7-byte header ---

void SerialManager::startReadHeader()
{
    boost::asio::async_read(
        m_serialPort,
        boost::asio::buffer(m_headerBuf, HEADER_SIZE),
        [this](const boost::system::error_code &ec, std::size_t) {
            handleHeaderRead(ec);
        });
}

void SerialManager::handleHeaderRead(const boost::system::error_code &ec)
{
    if (ec)
    {
        if (!m_initialized.load())
            return;
        spdlog::warn("[SerialManager] Header read error: {} - retrying", ec.message());
        startReadHeader();
        return;
    }

    if (m_headerBuf[0] != SOF_WIRE[0] || m_headerBuf[1] != SOF_WIRE[1] ||
        m_headerBuf[2] != SOF_WIRE[2] || m_headerBuf[3] != SOF_WIRE[3])
    {
        spdlog::error("[SerialManager] Bad SOF {:02X}{:02X}{:02X}{:02X} - resyncing",
                      m_headerBuf[0], m_headerBuf[1], m_headerBuf[2], m_headerBuf[3]);
        m_resyncFill = 0;
        startResync();
        return;
    }

    //DEBUG
    spdlog::debug("[SerialManager] SOF {:02X}{:02X}{:02X}{:02X}",
                 m_headerBuf[0], m_headerBuf[1], m_headerBuf[2], m_headerBuf[3]);
    //DEBUG
    processHeader();
}

// Called once m_headerBuf holds a header with a validated SOF.
void SerialManager::processHeader()
{
    const uint16_t expectedCrc = static_cast<uint16_t>(m_headerBuf[4])
                               | (static_cast<uint16_t>(m_headerBuf[5]) << 8);
    const uint8_t  len         = m_headerBuf[6];

    if (len == 0)
    {
        spdlog::error("[SerialManager] Invalid frame: length is 0");
        startReadHeader();
        return;
    }

    startReadPayload(expectedCrc, len);
}

// --- Phase 2: read LEN payload bytes ---

void SerialManager::startReadPayload(uint16_t expectedCrc, uint8_t len)
{
    boost::asio::async_read(
        m_serialPort,
        boost::asio::buffer(m_payloadBuf, len),
        [this, expectedCrc, len](const boost::system::error_code &ec, std::size_t) {
            handlePayloadRead(ec, expectedCrc, len);
        });
}

void SerialManager::handlePayloadRead(const boost::system::error_code &ec,
                                       uint16_t expectedCrc, uint8_t len)
{
    if (ec)
    {
        if (!m_initialized.load())
            return;
        spdlog::warn("[SerialManager] Payload read error: {} - restarting", ec.message());
        startReadHeader();
        return;
    }

    // CRC-16/CCITT-FALSE over [LEN byte, then payload] — same coverage as transmit
    uint16_t crc = crc16Ccitt(&len, 1);
    crc          = crc16Ccitt(m_payloadBuf, len, crc);

    if (crc != expectedCrc)
    {
        spdlog::error("[SerialManager] CRC mismatch: expected 0x{:04X} computed 0x{:04X}",
                      expectedCrc, crc);
        startReadHeader();
        return;
    }

    //DEBUG
    spdlog::debug("[SerialManager] CRC : expected 0x{:04X} computed 0x{:04X}",
                      expectedCrc, crc);
    //DEBUG

    handleSerialData(reinterpret_cast<const char *>(m_payloadBuf), len);
    startReadHeader();
}

// --- Bad-SOF recovery: slide a 4-byte window until SOF_WIRE is matched ---

void SerialManager::startResync()
{
    boost::asio::async_read(
        m_serialPort,
        boost::asio::buffer(&m_resyncByte, 1),
        [this](const boost::system::error_code &ec, std::size_t) {
            handleResyncByte(ec);
        });
}

void SerialManager::handleResyncByte(const boost::system::error_code &ec)
{
    if (ec)
    {
        if (!m_initialized.load())
            return;
        spdlog::warn("[SerialManager] Resync read error: {}", ec.message());
        startResync();
        return;
    }

    //DEBUG
    spdlog::debug("[SerialManager] Resync read : {:02X}", m_resyncByte );
    //DEBUG

    if (m_resyncByte == SOF_WIRE[m_resyncFill])
    {
        ++m_resyncFill;
        if (m_resyncFill == 4)
        {
            // Full SOF pattern confirmed; read the remaining 3 header bytes (CRC16 + LEN)
            m_resyncFill    = 0;
            m_headerBuf[0]  = SOF_WIRE[0];
            m_headerBuf[1]  = SOF_WIRE[1];
            m_headerBuf[2]  = SOF_WIRE[2];
            m_headerBuf[3]  = SOF_WIRE[3];
            spdlog::info("[SerialManager] SOF re-acquired; resuming normal framing");
            boost::asio::async_read(
                m_serialPort,
                boost::asio::buffer(m_headerBuf + 4, 3),
                [this](const boost::system::error_code &ec2, std::size_t) {
                    if (ec2)
                    {
                        if (!m_initialized.load())
                            return;
                        spdlog::warn("[SerialManager] Header tail read error after resync: {}",
                                     ec2.message());
                        startReadHeader();
                        return;
                    }
                    processHeader();
                });
            return;
        }
    }
    else
    {
        // Mismatch: restart window; this byte may itself begin a new SOF sequence
        m_resyncFill = (m_resyncByte == SOF_WIRE[0]) ? 1U : 0U;
    }

    startResync();
}

void SerialManager::handleSerialData(const char *buf, std::size_t bytesRead)
{
    ReceiveCallback callback;
    {
        std::lock_guard<std::mutex> lock(m_callbackMutex);
        callback = m_receiveCallback;
    }

    //DEBUG
    spdlog::debug("[SerialManager] Received {} bytes", bytesRead);
    spdlog::info("[SerialManager] String: {} ", buf);
    spdlog::debug("[SerialManager] Hex: {} ", spdlog::to_hex(buf, (buf+bytesRead)));
    //DEBUG

    if (callback)
    {
        callback(buf, bytesRead);
        return;
    }

    spdlog::debug("[SerialManager] Received {} bytes (no callback registered)", bytesRead);
}

// ---- CRC-16/CCITT-FALSE ----
// Poly=0x1021  Init=0xFFFF  RefIn=false  RefOut=false  XorOut=0x0000

uint16_t SerialManager::crc16Ccitt(const uint8_t *data, std::size_t len,
                                    uint16_t crc) noexcept
{
    for (std::size_t i = 0; i < len; ++i)
    {
        crc ^= static_cast<uint16_t>(data[i]) << 8;
        for (int bit = 0; bit < 8; ++bit)
        {
            if (crc & 0x8000U)
                crc = static_cast<uint16_t>((crc << 1) ^ 0x1021U);
            else
                crc = static_cast<uint16_t>(crc << 1);
        }
    }
    return crc;
}
