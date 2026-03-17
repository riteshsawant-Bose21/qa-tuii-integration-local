#include <bosepro/module.h>
#include <bosepro/periodic_task.h>

#include <algorithm>
#include <array>
#include <cctype>
#include <chrono>
#include <cstdint>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <deque>
#include <fstream>
#include <thread>
#include <sstream>
#include <mutex>
#include <string>
#include <vector>

#include <spdlog/spdlog.h>

#include <errno.h>
#include <fcntl.h>
#include <termios.h>
#include <unistd.h>

namespace {

constexpr char kUartDevice[] = "/dev/ttymxc3";

constexpr uint8_t kPreambleMsb = 0xB0;
constexpr uint8_t kPreambleLsb = 0x5E;

constexpr uint8_t kProtocolTypeBscp = 0x10;
constexpr uint8_t kProtocolVersion = 0x00;

/* Function IDs */
constexpr uint8_t kBlockProtocol        = 0x00;
constexpr uint8_t kBlockPlatform        = 0x01;
constexpr uint8_t kBlockAudio           = 0x02;
constexpr uint8_t kBlockManufacturing   = 0x04;

/* Protocol Function IDs */
constexpr uint16_t kPropertyProtocolVersion =
    static_cast<uint16_t>((kBlockProtocol << 8) | 0x00);
constexpr uint16_t kPropertyProtocolHeartbeat =
    static_cast<uint16_t>((kBlockProtocol << 8) | 0x01);

/* Platform Function IDs */
constexpr uint16_t kPropertyPlatformFirmwareVersion =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x0100);
constexpr uint16_t kPropertyPlatformHardwareVersion =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x0102);
constexpr uint16_t kPropertyPlatformReset =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x0104);
constexpr uint16_t kPropertyPlatformAmpTemp =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x0105);
constexpr uint16_t kPropertyPlatformAmpStatus =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x010B);
constexpr uint16_t kPropertyPlatformSMCUStatus =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x010C);
constexpr uint16_t kPropertyPlatformBootComplete =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x010D);
constexpr uint16_t kPropertyPlatformPMCUStatus =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x010E);

/* Audio Function IDs */
constexpr uint16_t kPropertyAudioAmpNumber =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x209);
constexpr uint16_t kPropertyAudioAmpMute =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x20A);

constexpr uint8_t kIndexAmpA = 0x01;
constexpr uint8_t kIndexAmpB = 0x02;
constexpr uint8_t kIndexAmpC = 0x04;
constexpr uint8_t kIndexAmpD = 0x08;

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

    void set_device(const std::string &device)
    {
        device_path_ = device;
    }

    bool open()
    {
        if (fd_ >= 0) {
            return true;
        }

        fd_ = ::open(device_path_.c_str(), O_RDWR | O_NOCTTY | O_NONBLOCK);
        if (fd_ < 0) {
            SPDLOG_ERROR("BDIF: failed to open {}: {}", device_path_, strerror(errno));
            return false;
        }

        if (!configure()) {
            SPDLOG_ERROR("BDIF: failed to configure {}", device_path_);
            close();
            return false;
        }

        SPDLOG_INFO("BDIF: opened {}", device_path_);
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
                if (errno == EAGAIN || errno == EWOULDBLOCK) {
                    // Non-blocking write would block; back off briefly and retry.
                    std::this_thread::sleep_for(std::chrono::milliseconds(1));
                    continue;
                }
                if (errno == EIO) {
                    SPDLOG_ERROR("BDIF: write failed (EIO), closing port: {}", strerror(errno));
                    close();
                    return false;
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
    std::string device_path_{kUartDevice};
};

} // namespace

namespace {

enum class GpioType { kNone, kSysfs, kGpiod };

struct GpioPin {
    GpioType type{GpioType::kNone};
    std::string label;
    std::string path;   // sysfs path or gpiod chip
    int offset{0};      // gpiod line offset
};

std::string trim(const std::string &s)
{
    const auto begin = s.find_first_not_of(" \t\r\n");
    if (begin == std::string::npos) {
        return {};
    }
    const auto end = s.find_last_not_of(" \t\r\n");
    return s.substr(begin, end - begin + 1);
}

GpioPin parse_gpio_pin(const std::string &spec, const std::string &label)
{
    GpioPin pin;
    pin.label = label;

    if (spec.empty()) {
        return pin;
    }

    const std::string prefix = "gpiod:";
    if (spec.compare(0, prefix.size(), prefix) == 0) {
        const auto rest = spec.substr(prefix.size());
        const auto sep = rest.rfind(':');
        if (sep == std::string::npos) {
            SPDLOG_WARN("BDIF: invalid gpiod spec '{}' for {}", spec, label);
            return pin;
        }
        const auto offset_str = rest.substr(sep + 1);
        try {
            const auto off = std::stol(offset_str, nullptr, 0);
            if (off < 0 || off > 0xFFFF) {
                SPDLOG_WARN("BDIF: gpiod offset '{}' out of range for {}", offset_str, label);
                return pin;
            }
            pin.offset = static_cast<int>(off);
            pin.type = GpioType::kGpiod;
            pin.path = rest.substr(0, sep);
        } catch (const std::exception &) {
            SPDLOG_WARN("BDIF: invalid gpiod offset '{}' for {}", offset_str, label);
        }
        return pin;
    }

    pin.type = GpioType::kSysfs;
    pin.path = spec;
    return pin;
}

bool run_command(const std::string &cmd, std::string *output)
{
    std::array<char, 128> buffer{};
    if (output) {
        output->clear();
    }

    FILE *pipe = ::popen(cmd.c_str(), "r");
    if (pipe == nullptr) {
        SPDLOG_ERROR("BDIF: failed to run '{}': {}", cmd, strerror(errno));
        return false;
    }

    while (fgets(buffer.data(), static_cast<int>(buffer.size()), pipe) != nullptr) {
        if (output) {
            output->append(buffer.data());
        }
    }
    const int status = ::pclose(pipe);
    if (status != 0) {
        SPDLOG_ERROR("BDIF: command '{}' exited with {}", cmd, status);
        return false;
    }

    return true;
}

bool read_sysfs_gpio(const std::string &path, bool &value)
{
    std::ifstream in(path);
    if (!in.is_open()) {
        SPDLOG_ERROR("BDIF: failed to open GPIO sysfs path '{}'", path);
        return false;
    }
    int v = 0;
    in >> v;
    if (in.fail()) {
        SPDLOG_ERROR("BDIF: failed to read GPIO sysfs value from '{}'", path);
        return false;
    }
    value = v != 0;
    return true;
}

bool write_sysfs_gpio(const std::string &path, bool value)
{
    std::ofstream out(path);
    if (!out.is_open()) {
        SPDLOG_ERROR("BDIF: failed to open GPIO sysfs path '{}'", path);
        return false;
    }
    out << (value ? 1 : 0) << std::endl;
    if (out.fail()) {
        SPDLOG_ERROR("BDIF: failed to write GPIO sysfs value to '{}'", path);
        return false;
    }
    return true;
}

bool read_gpiod_gpio(const GpioPin &pin, bool &value)
{
    const std::string &chip = pin.path;
    std::ostringstream cmd;
    cmd << "gpioget --chip " << chip << ' ' << pin.offset;

    std::string output;
    if (!run_command(cmd.str(), &output)) {
        return false;
    }

    const auto cleaned = trim(output);
    if (cleaned == "1") {
        value = true;
        return true;
    }
    if (cleaned == "0") {
        value = false;
        return true;
    }

    SPDLOG_ERROR("BDIF: unexpected gpioget output '{}' for {}", cleaned, pin.label);
    return false;
}

bool write_gpiod_gpio(const GpioPin &pin, bool value)
{
    const std::string &chip = pin.path;
    std::ostringstream cmd;
    cmd << "gpioset --mode=exit --chip " << chip << ' ' << pin.offset << '=' << (value ? 1 : 0);
    return run_command(cmd.str(), nullptr);
}

[[maybe_unused]] bool get_gpio_value(const GpioPin &pin, bool &value)
{
    switch (pin.type) {
    case GpioType::kSysfs:
        return read_sysfs_gpio(pin.path, value);
    case GpioType::kGpiod:
        return read_gpiod_gpio(pin, value);
    case GpioType::kNone:
    default:
        SPDLOG_DEBUG("BDIF: GPIO '{}' not configured", pin.label);
        return false;
    }
}

[[maybe_unused]] bool set_gpio_value(const GpioPin &pin, bool value)
{
    switch (pin.type) {
    case GpioType::kSysfs:
        return write_sysfs_gpio(pin.path, value);
    case GpioType::kGpiod:
        return write_gpiod_gpio(pin, value);
    case GpioType::kNone:
    default:
        SPDLOG_DEBUG("BDIF: GPIO '{}' not configured", pin.label);
        return false;
    }
}

class BDIFClient : public bosepro::Module
{
public:
    BDIFClient(const bosepro::BlockConfiguration &configuration);
    ~BDIFClient() override = default;

    void process() override;

private:
    using Clock = std::chrono::steady_clock;

    // UART handling
    bool ensure_port();
    void poll_rx_port();
    void drain_rx_frames();
    void handle_rx_frame(const std::vector<uint8_t> &frame);

    // Send helpers
    bool send_frame(Operator op, uint16_t property_id, const std::vector<uint8_t> &value);

    bool enqueue_tx(Operator op, uint16_t property_id, const std::vector<uint8_t> &value);
    void drain_tx_queue();

    void maybe_send_heartbeat();

    void handle_set_post_func();
    void handle_get_post_func();
    void handle_setget_post_func();

    bool parse_command(const std::string &cmd, uint16_t &property_id, std::vector<uint8_t> &value);
    bool send_command_from_param(const std::string &cmd, Operator op);
    bool build_named_command(const std::string &name, const std::vector<std::string> &args,
                             Operator op, uint16_t &property_id, std::vector<uint8_t> &value);
    static std::string to_lower(const std::string &s);
    static bool parse_bool_token(const std::string &token, bool &out);

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

    // Protocol parameters
    std::string protocol_ver;

    // Platform parameters
    std::string platform_fw_ver;
    int_fast32_t platform_hw_ver;
    std::vector<int_fast32_t> platform_amp_temp;
    std::vector<int_fast32_t> platform_amp_status;
    int_fast32_t platform_smcu_status;
    int_fast32_t platform_get_pmcu_status;

    // Audio parameters
    int_fast32_t audio_amp_number;
    std::vector<bool> audio_amp_mute;

    // GPIO controls
    GpioPin reset_pin_;
    GpioPin mute_pin_;
    GpioPin boot_pin_;

    // Command parameters (observer-driven)
    std::string set_cmd_;
    std::string get_cmd_;
    std::string setget_cmd_;

    int num_amps{0};
    std::string uart_device_;

    SerialPort port_;
    std::mutex tx_mutex_;

    std::vector<uint8_t> rx_buffer_;
    size_t rx_offset_{0};

    Clock::time_point last_poll_{Clock::now()};
    Clock::time_point last_heartbeat_sent_{Clock::now()};
    Clock::time_point last_heartbeat_ack_{};
    uint32_t heartbeat_counter_{0};
    bool link_ready_{false};
    bool boot_complete_acked_{false};

    struct TxRequest {
        Operator op;
        uint16_t property_id;
        std::vector<uint8_t> value;
    };

    static constexpr size_t kMaxTxQueue = 64;
    static constexpr size_t kDrainBatch = 8;
    std::deque<TxRequest> tx_queue_;

    MODULE_DECLARE(BDIFClient);
};

MODULE_REGISTER(BDIFClient, "bdif_client");

BDIFClient::BDIFClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration)
{
    std::string reset_pin_spec;
    std::string mute_pin_spec;
    std::string boot_pin_spec;

    get_property("uart_device", uart_device_);
    int_fast32_t num_amps_value;
    get_property("num_amps", num_amps_value);
    num_amps = static_cast<int>(num_amps_value);
    get_property("reset_pin", reset_pin_spec);
    get_property("mute_pin", mute_pin_spec);
    get_property("boot_pin", boot_pin_spec);

    reset_pin_ = parse_gpio_pin(reset_pin_spec, "reset_pin");
    mute_pin_ = parse_gpio_pin(mute_pin_spec, "mute_pin");
    boot_pin_ = parse_gpio_pin(boot_pin_spec, "boot_pin");

    port_.set_device(uart_device_);
    SPDLOG_INFO("BDIF: configured uart_device='{}' num_amps={} reset_pin='{}' mute_pin='{}' boot_pin='{}'",
                uart_device_, num_amps, reset_pin_spec, mute_pin_spec, boot_pin_spec);

    platform_amp_temp.resize(static_cast<size_t>(std::max(0, num_amps)));
    platform_amp_status.resize(static_cast<size_t>(std::max(0, num_amps)));
    audio_amp_mute.resize(static_cast<size_t>(std::max(0, num_amps)));

    assign_parameter("set", &set_cmd_, POST_FUNCTION_SCALAR(handle_set_post_func));
    assign_parameter("get", &get_cmd_, POST_FUNCTION_SCALAR(handle_get_post_func));
    assign_parameter("setget", &setget_cmd_, POST_FUNCTION_SCALAR(handle_setget_post_func));
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
    boot_complete_acked_ = false;

    return port_.open();
}

void BDIFClient::poll_rx_port()
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
        drain_rx_frames();
    }
}

void BDIFClient::drain_rx_frames()
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

            handle_rx_frame(frame);
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

void BDIFClient::handle_rx_frame(const std::vector<uint8_t> &frame)
{
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
    
    uint32_t heartbeat_ack = 0; 

    if (version != kProtocolVersion) {
        SPDLOG_WARN("BDIF: version mismatch {} != {}", version, kProtocolVersion);
    }

    if (is_response(op) && result != 0) {
        SPDLOG_WARN("BDIF: response error {} for property 0x{:04x}", result, property);
        return;
    }

    if (op == Operator::kEvent) {
        SPDLOG_INFO("BDIF: event property 0x{:04x} payload {}", property,
                    hex_string(value_ptr, value_len));
        return;
    }

    SPDLOG_TRACE("BDIF: op {} property 0x{:04x} payload {}", static_cast<int>(op),
                 property, hex_string(value_ptr, value_len));

    auto read_u32 = [&](size_t offset, size_t count) -> uint32_t {
        uint32_t v = 0;
        for (size_t i = 0; i < count && offset + i < value_len; ++i) {
            v = static_cast<uint32_t>((v << 8) | value_ptr[offset + i]);
        }
        return v;
    };

    const bool value_valid = (op == Operator::kGetResponse || op == Operator::kSetGetResponse);

    switch (property) {
    case kPropertyProtocolHeartbeat:
        if (value_valid && value_len >= sizeof(uint32_t)) {
            for (size_t i = 0; i < sizeof(uint32_t); ++i) {
                heartbeat_ack = static_cast<uint32_t>((heartbeat_ack << 8) | value_ptr[i]);
            }
            last_heartbeat_ack_ = Clock::now();
            link_ready_ = true;
            SPDLOG_DEBUG("BDIF: heartbeat ack {}", heartbeat_ack);
        } else {
            SPDLOG_DEBUG("BDIF: heartbeat ack");
        }
        break;
    case kPropertyProtocolVersion:
        if (value_valid) {
            protocol_ver = std::string(reinterpret_cast<const char*>(value_ptr), value_len);
            SPDLOG_DEBUG("BDIF: ack protocol version '{}'", protocol_ver);
        } else {
            SPDLOG_DEBUG("BDIF: ack protocol version");
        }
        break;
    case kPropertyPlatformFirmwareVersion:
        if (value_valid) {
            platform_fw_ver = std::string(reinterpret_cast<const char*>(value_ptr), value_len);
            SPDLOG_DEBUG("BDIF: ack platform fw '{}'", platform_fw_ver);
        } else {
            SPDLOG_DEBUG("BDIF: ack platform fw");
        }
        break;
    case kPropertyPlatformHardwareVersion:
        if (value_valid) {
            platform_hw_ver = read_u32(0, value_len);
            SPDLOG_DEBUG("BDIF: ack platform hw 0x{:08x}", platform_hw_ver);
        } else {
            SPDLOG_DEBUG("BDIF: ack platform hw");
        }
        break;
    case kPropertyPlatformAmpTemp:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            if (idx >= 0 && idx < num_amps) {
                platform_amp_temp[idx] = static_cast<int_fast32_t>(read_u32(1, value_len - 1));
                SPDLOG_DEBUG("BDIF: ack amp temp[{}]={}", idx, platform_amp_temp[idx]);
            }
        } else {
            SPDLOG_DEBUG("BDIF: ack amp temp");
        }
        break;
    case kPropertyPlatformAmpStatus:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            if (idx >= 0 && idx < num_amps) {
                platform_amp_status[idx] = static_cast<int_fast32_t>(read_u32(1, value_len - 1));
                SPDLOG_DEBUG("BDIF: ack amp status[{}]=0x{:08x}", idx, platform_amp_status[idx]);
            }
        } else {
            SPDLOG_DEBUG("BDIF: ack amp status");
        }
        break;
    case kPropertyPlatformSMCUStatus:
        if (value_valid) {
            platform_smcu_status = read_u32(0, value_len);
            SPDLOG_DEBUG("BDIF: ack smcu status 0x{:08x}", platform_smcu_status);
        } else {
            SPDLOG_DEBUG("BDIF: ack smcu status");
        }
        break;
    case kPropertyPlatformBootComplete:
        if (value_valid) {
            boot_complete_acked_ = value_len > 0 ? value_ptr[0] != 0 : false;
            SPDLOG_DEBUG("BDIF: ack boot complete {}", boot_complete_acked_);
        } else {
            boot_complete_acked_ = true; // Treat SET ack as success without value.
            SPDLOG_DEBUG("BDIF: ack boot complete");
        }
        break;
    case kPropertyPlatformPMCUStatus:
        if (value_valid) {
            platform_get_pmcu_status = read_u32(0, value_len);
            SPDLOG_DEBUG("BDIF: ack pmcu status 0x{:08x}", platform_get_pmcu_status);
        } else {
            SPDLOG_DEBUG("BDIF: ack pmcu status");
        }
        break;
    case kPropertyAudioAmpNumber:
        if (value_valid) {
            audio_amp_number = read_u32(0, value_len);
            SPDLOG_DEBUG("BDIF: ack amp number {}", audio_amp_number);
        } else {
            SPDLOG_DEBUG("BDIF: ack amp number");
        }
        break;
    case kPropertyAudioAmpMute:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            if (idx >= 0 && idx < num_amps) {
                audio_amp_mute[idx] = value_ptr[1] != 0;
                const bool mute = static_cast<bool>(audio_amp_mute[idx]);
                SPDLOG_DEBUG("BDIF: ack amp mute[{}]={}", idx, mute);
            }
        } else {
            SPDLOG_DEBUG("BDIF: ack amp mute");
        }
        break;
    default:
        break;
    }
}

bool BDIFClient::enqueue_tx(Operator op, uint16_t property_id, const std::vector<uint8_t> &value)
{
    if (tx_queue_.size() >= kMaxTxQueue) {
        SPDLOG_WARN("BDIF: tx queue full ({}), dropping property 0x{:04x}", tx_queue_.size(), property_id);
        return false;
    }
    tx_queue_.push_back(TxRequest{op, property_id, value});
    return true;
}

void BDIFClient::drain_tx_queue()
{
    size_t sent = 0;
    while (!tx_queue_.empty() && sent < kDrainBatch) {
        const auto &req = tx_queue_.front();
        if (!send_frame(req.op, req.property_id, req.value)) {
            SPDLOG_WARN("BDIF: failed to send property 0x{:04x}; will retry", req.property_id);
            break;
        }
        tx_queue_.pop_front();
        ++sent;
    }
}

bool BDIFClient::parse_command(const std::string &cmd, uint16_t &property_id, std::vector<uint8_t> &value)
{
    std::istringstream iss(cmd);
    std::string token;
    if (!(iss >> token)) {
        return false;
    }

    std::vector<std::string> tokens;
    tokens.push_back(token);
    while (iss >> token) {
        tokens.push_back(token);
    }

    // If first token is alphabetic, delegate to named command builder (caller will resend with op).
    // The caller (send_command_from_param) will re-tokenize and call build_named_command.
    // Fallback to numeric form here.
    try {
        property_id = static_cast<uint16_t>(std::stoul(tokens[0], nullptr, 0));
    } catch (const std::exception &) {
        SPDLOG_WARN("BDIF: failed to parse property id from '{}'", tokens[0]);
        return false;
    }

    value.clear();
    for (size_t i = 1; i < tokens.size(); ++i) {
        try {
            const auto byte = std::stoul(tokens[i], nullptr, 0);
            if (byte > 0xFF) {
                SPDLOG_WARN("BDIF: payload byte '{}' out of range", tokens[i]);
                return false;
            }
            value.push_back(static_cast<uint8_t>(byte));
        } catch (const std::exception &) {
            SPDLOG_WARN("BDIF: failed to parse payload byte '{}'", tokens[i]);
            return false;
        }
    }

    return true;
}

bool BDIFClient::send_command_from_param(const std::string &cmd, Operator op)
{
    uint16_t property_id = 0;
    std::vector<uint8_t> payload;
    if (cmd.empty()) {
        return false;
    }
    std::istringstream iss(cmd);
    std::string token;
    std::vector<std::string> tokens;
    while (iss >> token) {
        tokens.push_back(token);
    }
    if (tokens.empty()) {
        return false;
    }

    if (std::isalpha(tokens[0][0])) {
        if (!build_named_command(tokens[0], std::vector<std::string>(tokens.begin() + 1, tokens.end()),
                                op, property_id, payload)) {
            return false;
        }
    } else {
        if (!parse_command(cmd, property_id, payload)) {
            return false;
        }
    }
    return enqueue_tx(op, property_id, payload);
}

std::string BDIFClient::to_lower(const std::string &s)
{
    std::string out;
    out.reserve(s.size());
    for (char c : s) {
        out.push_back(static_cast<char>(std::tolower(static_cast<unsigned char>(c))));
    }
    return out;
}

bool BDIFClient::parse_bool_token(const std::string &token, bool &out)
{
    const auto t = to_lower(token);
    if (t == "1" || t == "true" || t == "on" || t == "yes") {
        out = true;
        return true;
    }
    if (t == "0" || t == "false" || t == "off" || t == "no") {
        out = false;
        return true;
    }
    return false;
}

bool BDIFClient::build_named_command(const std::string &name, const std::vector<std::string> &args,
                                     Operator op, uint16_t &property_id, std::vector<uint8_t> &value)
{
    enum class ArgKind { kNone, kIndex, kBool, kIndexBool };

    struct Spec {
        const char *name;
        uint16_t property;
        ArgKind get_args;
        ArgKind set_args;
        ArgKind setget_args;
    };

    static const Spec kSpecs[] = {
        {"protocolversion", kPropertyProtocolVersion, ArgKind::kNone, ArgKind::kNone, ArgKind::kNone},
        {"platformfwversion", kPropertyPlatformFirmwareVersion, ArgKind::kNone, ArgKind::kNone, ArgKind::kNone},
        {"platformhwversion", kPropertyPlatformHardwareVersion, ArgKind::kNone, ArgKind::kNone, ArgKind::kNone},
        {"platformampstatus", kPropertyPlatformAmpStatus, ArgKind::kIndex, ArgKind::kIndex, ArgKind::kIndex},
        {"platformamptemp", kPropertyPlatformAmpTemp, ArgKind::kIndex, ArgKind::kIndex, ArgKind::kIndex},
        {"platformsmcustatus", kPropertyPlatformSMCUStatus, ArgKind::kNone, ArgKind::kNone, ArgKind::kNone},
        {"platformpmcustatus", kPropertyPlatformPMCUStatus, ArgKind::kNone, ArgKind::kNone, ArgKind::kNone},
        {"platformreset", kPropertyPlatformReset, ArgKind::kNone, ArgKind::kBool, ArgKind::kBool},
        {"audioampnumber", kPropertyAudioAmpNumber, ArgKind::kNone, ArgKind::kNone, ArgKind::kNone},
        {"audioampmute", kPropertyAudioAmpMute, ArgKind::kIndex, ArgKind::kIndexBool, ArgKind::kIndexBool},
    };

    const auto name_lc = to_lower(name);
    const Spec *spec = nullptr;
    for (const auto &s : kSpecs) {
        if (name_lc == s.name) {
            spec = &s;
            break;
        }
    }

    if (spec == nullptr) {
        SPDLOG_WARN("BDIF: unknown command '{}'", name);
        return false;
    }

    auto arg_kind_for_op = [&](Operator oper) -> ArgKind {
        switch (oper) {
        case Operator::kGet: return spec->get_args;
        case Operator::kSet: return spec->set_args;
        case Operator::kSetGet: return spec->setget_args;
        default: return ArgKind::kNone;
        }
    };

    const ArgKind kind = arg_kind_for_op(op);
    property_id = spec->property;
    value.clear();

    auto parse_index = [&](const std::string &tok, uint8_t &out_idx) -> bool {
        try {
            const auto v = std::stoul(tok, nullptr, 0);
            if (v == 0 || v > 0xFF) {
                SPDLOG_WARN("BDIF: index '{}' out of range", tok);
                return false;
            }
            out_idx = static_cast<uint8_t>(v);
            return true;
        } catch (const std::exception &) {
            SPDLOG_WARN("BDIF: failed to parse index '{}'", tok);
            return false;
        }
    };

    switch (kind) {
    case ArgKind::kNone:
        if (!args.empty()) {
            SPDLOG_WARN("BDIF: command '{}' takes no args", name);
            return false;
        }
        break;
    case ArgKind::kIndex: {
        if (args.size() != 1) {
            SPDLOG_WARN("BDIF: command '{}' expects index arg", name);
            return false;
        }
        uint8_t idx = 0;
        if (!parse_index(args[0], idx)) {
            return false;
        }
        value.push_back(idx);
        break;
    }
    case ArgKind::kBool: {
        if (args.size() != 1) {
            SPDLOG_WARN("BDIF: command '{}' expects bool arg", name);
            return false;
        }
        bool b = false;
        if (!parse_bool_token(args[0], b)) {
            SPDLOG_WARN("BDIF: command '{}' expects bool arg, got '{}'", name, args[0]);
            return false;
        }
        value.push_back(static_cast<uint8_t>(b ? 1 : 0));
        break;
    }
    case ArgKind::kIndexBool: {
        if (args.size() != 2) {
            SPDLOG_WARN("BDIF: command '{}' expects <index> <bool>", name);
            return false;
        }
        uint8_t idx = 0;
        if (!parse_index(args[0], idx)) {
            return false;
        }
        bool b = false;
        if (!parse_bool_token(args[1], b)) {
            SPDLOG_WARN("BDIF: command '{}' expects bool arg, got '{}'", name, args[1]);
            return false;
        }
        value.push_back(idx);
        value.push_back(static_cast<uint8_t>(b ? 1 : 0));
        break;
    }
    default:
        SPDLOG_WARN("BDIF: unsupported arg kind for '{}'", name);
        return false;
    }

    return true;
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

    return true;
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

void BDIFClient::handle_set_post_func()
{
    if (!send_command_from_param(set_cmd_, Operator::kSet)) {
        SPDLOG_WARN("BDIF: failed to enqueue set command '{}'", set_cmd_);
    }
}

void BDIFClient::handle_get_post_func()
{
    if (!send_command_from_param(get_cmd_, Operator::kGet)) {
        SPDLOG_WARN("BDIF: failed to enqueue get command '{}'", get_cmd_);
    }
}

void BDIFClient::handle_setget_post_func()
{
    if (!send_command_from_param(setget_cmd_, Operator::kSetGet)) {
        SPDLOG_WARN("BDIF: failed to enqueue setget command '{}'", setget_cmd_);
    }
}

void BDIFClient::process()
{
    if (!ensure_port()) {
        return;
    }

    poll_rx_port();

    if (!boot_complete_acked_) {
        std::vector<uint8_t> payload = {1};
        send_frame(Operator::kSet, kPropertyPlatformBootComplete, payload);
    }

    maybe_send_heartbeat();

    const auto now = Clock::now();
    // Detect missing heartbeat ACK even if we haven't yet marked link_ready_.
    const bool ack_missing = (last_heartbeat_sent_ > last_heartbeat_ack_) &&
                             (now - last_heartbeat_sent_ > kHeartbeatTimeout);
    if (ack_missing || (link_ready_ && last_heartbeat_ack_.time_since_epoch().count() > 0 &&
                        now - last_heartbeat_ack_ > kHeartbeatTimeout)) {
        SPDLOG_ERROR("BDIF: heartbeat timeout");
        tx_queue_.clear();
        last_heartbeat_sent_ = Clock::now();
        last_heartbeat_ack_ = Clock::time_point{};
        link_ready_ = false;
    }

    if (!boot_complete_acked_ || !link_ready_) {
        return;
    }

    drain_tx_queue();
}

} // namespace
