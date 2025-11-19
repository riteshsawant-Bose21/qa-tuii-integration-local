#include <bosepro/module.h>
#include <bosepro/periodic_task.h>

#include <algorithm>
#include <array>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <mutex>
#include <string>
#include <vector>

#include <spdlog/spdlog.h>

#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

namespace {

constexpr char kUartDevice[] = "/dev/ttymxc2";
constexpr uint8_t kPreambleMsb = 0xB0;
constexpr uint8_t kPreambleLsb = 0x5E;
constexpr uint8_t kProtocolTypeBscp = 0x10;
constexpr uint8_t kProtocolVersion = 0x00;

constexpr uint8_t kBlockProtocol = 0x00;
constexpr uint8_t kBlockAudio = 0x02;

constexpr uint16_t kPropertyProtocolHeartbeat =
    static_cast<uint16_t>((kBlockProtocol << 8) | 0x01);
constexpr uint16_t kPropertyAudioGain =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x00);
constexpr uint16_t kPropertyAudioPhantom =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x06);

constexpr std::chrono::milliseconds kHeartbeatPeriod{2000};
constexpr std::chrono::milliseconds kHeartbeatTimeout{6000};

constexpr size_t kMinFrameLength = 6;   // total bytes including preamble
constexpr size_t kMaxFrameLength = 257; // 255 byte payload + preamble

enum class Operator : uint8_t {
    kSet = 0x01,
    kGet = 0x02,
    kSetGet = 0x03,
    kEvent = 0x04,
    kSetResponse = 0x08,
    kGetResponse = 0x09,
    kSetGetResponse = 0x0A,
};

constexpr bool is_response(Operator op)
{
    return op == Operator::kSetResponse ||
           op == Operator::kGetResponse ||
           op == Operator::kSetGetResponse;
}

uint16_t crc16_ccitt(const uint8_t *data, size_t length)
{
    constexpr uint16_t kPoly = 0x1021;
    uint16_t crc = 0xFFFF;

    for (size_t i = 0; i < length; ++i) {
        crc ^= static_cast<uint16_t>(data[i]) << 8;
        for (int bit = 0; bit < 8; ++bit) {
            if (crc & 0x8000) {
                crc = static_cast<uint16_t>((crc << 1) ^ kPoly);
            } else {
                crc <<= 1;
            }
        }
    }

    return crc;
}

std::string hex_string(const uint8_t *data, size_t length)
{
    static const char *kHex = "0123456789ABCDEF";
    std::string result;
    result.reserve(length * 2);
    for (size_t i = 0; i < length; ++i) {
        result.push_back(kHex[(data[i] >> 4) & 0x0F]);
        result.push_back(kHex[data[i] & 0x0F]);
        if (i + 1 != length) {
            result.push_back(' ');
        }
    }
    return result;
}

class SerialPort
{
public:
    SerialPort() = default;
    ~SerialPort()
    {
        close();
    }

    bool open()
    {
        if (fd_ >= 0) {
            return true;
        }

        fd_ = ::open(kUartDevice, O_RDWR | O_NOCTTY | O_NONBLOCK);
        if (fd_ < 0) {
            SPDLOG_ERROR("BDIF: failed to open {}: {}", kUartDevice, strerror(errno));
            return false;
        }

        if (!configure()) {
            SPDLOG_ERROR("BDIF: failed to configure {}", kUartDevice);
            close();
            return false;
        }

        SPDLOG_INFO("BDIF: opened {}", kUartDevice);
        return true;
    }

    void close()
    {
        if (fd_ >= 0) {
            ::close(fd_);
            fd_ = -1;
        }
    }

    bool is_open() const
    {
        return fd_ >= 0;
    }

    bool write_all(const uint8_t *data, size_t length)
    {
        if (fd_ < 0) {
            return false;
        }

        size_t offset = 0;
        while (offset < length) {
            ssize_t written = ::write(fd_, data + offset, length - offset);
            if (written < 0) {
                if (errno == EINTR) {
                    continue;
                }
                SPDLOG_ERROR("BDIF: write failed: {}", strerror(errno));
                return false;
            }
            offset += static_cast<size_t>(written);
        }
        return true;
    }

    ssize_t read_some(uint8_t *buffer, size_t capacity)
    {
        if (fd_ < 0) {
            return -1;
        }

        for (;;) {
            ssize_t ret = ::read(fd_, buffer, capacity);
            if (ret < 0) {
                if (errno == EINTR) {
                    continue;
                }
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    return 0;
                }
                SPDLOG_ERROR("BDIF: read failed: {}", strerror(errno));
            }
            return ret;
        }
    }

private:
    bool configure()
    {
        struct termios options;
        if (tcgetattr(fd_, &options) != 0) {
            SPDLOG_ERROR("BDIF: tcgetattr failed: {}", strerror(errno));
            return false;
        }

        cfmakeraw(&options);
        options.c_cflag |= (CLOCAL | CREAD);
        options.c_cflag &= ~CRTSCTS;
        options.c_cflag &= ~CSTOPB;
        options.c_cflag &= ~PARENB;
        options.c_cflag &= ~CSIZE;
        options.c_cflag |= CS8;
        options.c_cc[VMIN] = 0;
        options.c_cc[VTIME] = 0;

        if (cfsetispeed(&options, B115200) != 0 ||
            cfsetospeed(&options, B115200) != 0) {
            SPDLOG_ERROR("BDIF: failed to set baud rate: {}", strerror(errno));
            return false;
        }

        if (tcsetattr(fd_, TCSANOW, &options) != 0) {
            SPDLOG_ERROR("BDIF: tcsetattr failed: {}", strerror(errno));
            return false;
        }

        tcflush(fd_, TCIOFLUSH);
        return true;
    }

    int fd_{-1};
};

} // namespace

namespace {

class BDIFClient : public bosepro::Module
{
public:
    BDIFClient(const bosepro::BlockConfiguration &configuration);
    ~BDIFClient() override = default;

    void process() override;

private:
    using Clock = std::chrono::steady_clock;

    bool ensure_port();
    void poll_port();
    void drain_frames();
    void handle_frame(const std::vector<uint8_t> &frame);

    bool send_frame(Operator op, uint16_t property_id, const std::vector<uint8_t> &value);
    bool send_channel_level(uint16_t property_id, int channel, int value);
    bool send_switch_state(uint16_t property_id, int channel, bool enabled);
    void maybe_send_heartbeat();

    void change_gain_post_func(int index);
    void change_php_post_func(int index);

    template <typename T>
    static std::vector<uint8_t> to_big_endian(T value)
    {
        std::vector<uint8_t> out(sizeof(T));
        const auto temp = static_cast<uint64_t>(value);
        for (size_t i = 0; i < sizeof(T); ++i) {
            out[sizeof(T) - 1 - i] =
                static_cast<uint8_t>((temp >> (i * 8)) & 0xFF);
        }
        return out;
    }

    bosepro::DspParamMemory<int_fast32_t[]> gain_;
    bosepro::DspParamMemory<bool[]> php_;

    int num_gain_chs_{0};
    int num_php_chs_{0};

    SerialPort port_;
    std::mutex tx_mutex_;

    std::vector<uint8_t> rx_buffer_;
    size_t rx_offset_{0};

    Clock::time_point last_poll_{Clock::now()};
    Clock::time_point last_heartbeat_sent_{Clock::now()};
    Clock::time_point last_heartbeat_ack_{};
    uint32_t heartbeat_counter_{0};
    bool link_ready_{false};

    MODULE_DECLARE(BDIFClient);
};

MODULE_REGISTER(BDIFClient, "bdif_client");

BDIFClient::BDIFClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration)
{
    get_property("num_gain_chs", num_gain_chs_);
    get_property("num_php_chs", num_php_chs_);

    assign_parameter("gain", gain_, POST_FUNCTION_VECTOR(change_gain_post_func));
    assign_parameter("php", php_, POST_FUNCTION_VECTOR(change_php_post_func));
}

bool BDIFClient::ensure_port()
{
    if (port_.is_open()) {
        return true;
    }

    rx_buffer_.clear();
    rx_offset_ = 0;
    link_ready_ = false;
    heartbeat_counter_ = 0;
    last_heartbeat_sent_ = Clock::now();
    last_heartbeat_ack_ = Clock::time_point{};

    return port_.open();
}

void BDIFClient::poll_port()
{
    if (!port_.is_open()) {
        return;
    }

    std::array<uint8_t, 256> buffer{};
    for (;;) {
        ssize_t nread = port_.read_some(buffer.data(), buffer.size());
        if (nread <= 0) {
            break;
        }

        rx_buffer_.insert(rx_buffer_.end(), buffer.begin(), buffer.begin() + nread);
        drain_frames();
    }
}

void BDIFClient::drain_frames()
{
    bool progress = true;
    while (progress) {
        progress = false;

        while (rx_buffer_.size() - rx_offset_ >= 3) {
            const uint8_t *data = rx_buffer_.data() + rx_offset_;
            if (data[0] != kPreambleMsb || data[1] != kPreambleLsb) {
                ++rx_offset_;
                continue;
            }

            const uint8_t length = data[2];
            const size_t total_frame = static_cast<size_t>(length) + 2;

            if (total_frame < kMinFrameLength || total_frame > kMaxFrameLength) {
                SPDLOG_WARN("BDIF: invalid frame length {}", total_frame);
                ++rx_offset_;
                continue;
            }

            if (rx_buffer_.size() - rx_offset_ < total_frame) {
                break;
            }

            std::vector<uint8_t> frame(total_frame);
            std::copy_n(data, total_frame, frame.begin());

            rx_offset_ += total_frame;
            progress = true;

            const uint16_t crc = crc16_ccitt(frame.data(), frame.size());
            if (crc != 0) {
                SPDLOG_WARN("BDIF: CRC error on frame {}", hex_string(frame.data(), frame.size()));
                continue;
            }

            handle_frame(frame);
        }

        if (rx_offset_ > 0) {
            if (rx_offset_ >= rx_buffer_.size()) {
                rx_buffer_.clear();
                rx_offset_ = 0;
            } else if (rx_offset_ > rx_buffer_.size() / 2) {
                rx_buffer_.erase(rx_buffer_.begin(), rx_buffer_.begin() + rx_offset_);
                rx_offset_ = 0;
            }
        }
    }
}

void BDIFClient::handle_frame(const std::vector<uint8_t> &frame)
{
    if (frame.size() < 10) {
        SPDLOG_WARN("BDIF: short frame {}", hex_string(frame.data(), frame.size()));
        return;
    }

    const uint8_t protocol = frame[3];
    if (protocol != kProtocolTypeBscp) {
        SPDLOG_WARN("BDIF: unsupported protocol type 0x{:02x}", protocol);
        return;
    }

    const uint8_t version = frame[4] >> 4;
    const Operator op = static_cast<Operator>(frame[4] & 0x0F);
    const uint8_t result = frame[5];
    const uint16_t property = static_cast<uint16_t>((frame[6] << 8) | frame[7]);
    const uint8_t *value_ptr = frame.data() + 8;
    const size_t value_len = frame.size() - 10;

    if (version != kProtocolVersion) {
        SPDLOG_WARN("BDIF: version mismatch {} != {}", version, kProtocolVersion);
    }

    if (property == kPropertyProtocolHeartbeat &&
        op == Operator::kSetGetResponse && result == 0 && value_len == sizeof(uint32_t)) {
        uint32_t heartbeat = 0;
        for (size_t i = 0; i < sizeof(uint32_t); ++i) {
            heartbeat = static_cast<uint32_t>((heartbeat << 8) | value_ptr[i]);
        }
        last_heartbeat_ack_ = Clock::now();
        link_ready_ = true;
        SPDLOG_TRACE("BDIF: heartbeat ack {}", heartbeat);
        return;
    }

    if (is_response(op) && result != 0) {
        SPDLOG_WARN("BDIF: response error {} for property 0x{:04x}", result, property);
        return;
    }

    if (op == Operator::kEvent) {
        SPDLOG_INFO("BDIF: event property 0x{:04x} payload {}", property,
                    hex_string(value_ptr, value_len));
    } else {
        SPDLOG_DEBUG("BDIF: op {} property 0x{:04x} payload {}", static_cast<int>(op),
                     property, hex_string(value_ptr, value_len));
    }
}

bool BDIFClient::send_frame(Operator op, uint16_t property_id,
                            const std::vector<uint8_t> &value)
{
    if (!ensure_port()) {
        return false;
    }

    std::vector<uint8_t> payload;
    payload.reserve(2 + value.size());
    payload.push_back(static_cast<uint8_t>((property_id >> 8) & 0xFF));
    payload.push_back(static_cast<uint8_t>(property_id & 0xFF));
    payload.insert(payload.end(), value.begin(), value.end());

    if (payload.size() + 6 > 255) {
        SPDLOG_ERROR("BDIF: payload too large {}", payload.size());
        return false;
    }

    const uint8_t length_field = static_cast<uint8_t>(payload.size() + 6);
    std::vector<uint8_t> frame;
    frame.reserve(static_cast<size_t>(length_field) + 2);
    frame.push_back(kPreambleMsb);
    frame.push_back(kPreambleLsb);
    frame.push_back(length_field);
    frame.push_back(kProtocolTypeBscp);
    frame.push_back(static_cast<uint8_t>((kProtocolVersion << 4) |
                                         (static_cast<uint8_t>(op) & 0x0F)));
    frame.push_back(0x00);

    frame.insert(frame.end(), payload.begin(), payload.end());

    const uint16_t crc = crc16_ccitt(frame.data(), frame.size());
    frame.push_back(static_cast<uint8_t>((crc >> 8) & 0xFF));
    frame.push_back(static_cast<uint8_t>(crc & 0xFF));

    std::lock_guard<std::mutex> lock(tx_mutex_);
    if (!port_.write_all(frame.data(), frame.size())) {
        return false;
    }

    SPDLOG_DEBUG("BDIF: tx {}", hex_string(frame.data(), frame.size()));
    return true;
}

bool BDIFClient::send_channel_level(uint16_t property_id, int channel, int value)
{
    std::vector<uint8_t> payload = {
        static_cast<uint8_t>(channel & 0xFF),
        static_cast<uint8_t>(value & 0xFF),
    };
    return send_frame(Operator::kSet, property_id, payload);
}

bool BDIFClient::send_switch_state(uint16_t property_id, int channel, bool enabled)
{
    std::vector<uint8_t> payload = {
        static_cast<uint8_t>(channel & 0xFF),
        static_cast<uint8_t>(enabled ? 1 : 0),
    };
    return send_frame(Operator::kSet, property_id, payload);
}

void BDIFClient::maybe_send_heartbeat()
{
    const auto now = Clock::now();
    if (!port_.is_open()) {
        return;
    }

    if (now - last_heartbeat_sent_ < kHeartbeatPeriod) {
        return;
    }

    last_heartbeat_sent_ = now;
    ++heartbeat_counter_;

    auto payload = to_big_endian<uint32_t>(heartbeat_counter_);
    if (!send_frame(Operator::kSetGet, kPropertyProtocolHeartbeat, payload)) {
        SPDLOG_WARN("BDIF: failed to send heartbeat");
    }
}

void BDIFClient::change_gain_post_func(int index)
{
    if (index < 0 || index >= num_gain_chs_) {
        SPDLOG_ERROR("BDIF: gain index {} out of range", index);
        return;
    }

    int value = gain_[index];
    if (value < 0) value = 0;
    if (value > 3) value = 3;

    if (!send_channel_level(kPropertyAudioGain, index + 1, value)) {
        SPDLOG_ERROR("BDIF: failed to send gain channel {}", index);
    }
}

void BDIFClient::change_php_post_func(int index)
{
    if (index < 0 || index >= num_php_chs_) {
        SPDLOG_ERROR("BDIF: php index {} out of range", index);
        return;
    }

    if (!send_switch_state(kPropertyAudioPhantom, index + 1, php_[index])) {
        SPDLOG_ERROR("BDIF: failed to send phantom channel {}", index);
    }
}

void BDIFClient::process()
{
    if (!ensure_port()) {
        return;
    }

    poll_port();
    maybe_send_heartbeat();

    const auto now = Clock::now();
    if (link_ready_ && last_heartbeat_ack_.time_since_epoch().count() > 0) {
        if (now - last_heartbeat_ack_ > kHeartbeatTimeout) {
            SPDLOG_WARN("BDIF: heartbeat timeout");
            link_ready_ = false;
        }
    }
}

} // namespace
