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
constexpr char kBdifProtocolVersion[] = "2.0.1";

constexpr char kPureModels[][16] = {
    "1990-4150",
    "1990-8300",
    "1990-41500"
};

constexpr char kSmartModels[][16] = {
    "2100-4150",
    "2100-4300",
    "2100-8300",
    "2100-4600",
    "2100-8600",
    "2100-41500",
};

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
constexpr uint16_t kPropertyPlatformHardwareVariant =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x0101);
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
constexpr uint16_t kPropertyPlatformSMPSNumber =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x010F);
constexpr uint16_t kPropertyPlatformSMPSTemp =
    static_cast<uint16_t>((kBlockPlatform << 8) | 0x0110);

/* Audio Function IDs */
constexpr uint16_t kPropertyAudioVolume =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x200);
constexpr uint16_t kPropertyAudioPhantomPower =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x206);
constexpr uint16_t kPropertyAudioAmpNumber =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x209);
constexpr uint16_t kPropertyAudioAmpMute =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x20A);
constexpr uint16_t kPropertyAudioAnalogGain =
    static_cast<uint16_t>((kBlockAudio << 8) | 0x214);

constexpr uint8_t kIndexAmpA = 0x01;
constexpr uint8_t kIndexAmpB = 0x02;
constexpr uint8_t kIndexAmpC = 0x04;
constexpr uint8_t kIndexAmpD = 0x08;

enum class ArgKind { kNone, kIndex, kBool, kIndexBool, kIndexByte };

struct Spec {
    const char *name;
    uint16_t property;
    ArgKind get_args;
    ArgKind set_args;
    ArgKind setget_args;
};

static const Spec kSpecs[] = {
    {"protocolversion",     kPropertyProtocolVersion,           ArgKind::kNone,  ArgKind::kNone,      ArgKind::kNone},
    {"platformfwversion",   kPropertyPlatformFirmwareVersion,   ArgKind::kNone,  ArgKind::kNone,      ArgKind::kNone},
    {"platformhwvariant",   kPropertyPlatformHardwareVariant,   ArgKind::kNone,  ArgKind::kNone,      ArgKind::kNone},
    {"platformhwversion",   kPropertyPlatformHardwareVersion,   ArgKind::kNone,  ArgKind::kNone,      ArgKind::kNone},
    {"platformampstatus",   kPropertyPlatformAmpStatus,         ArgKind::kIndex, ArgKind::kIndex,     ArgKind::kIndex},
    {"platformamptemp",     kPropertyPlatformAmpTemp,           ArgKind::kIndex, ArgKind::kIndex,     ArgKind::kIndex},
    {"platformsmcustatus",  kPropertyPlatformSMCUStatus,        ArgKind::kIndex, ArgKind::kIndex,     ArgKind::kIndex},
    {"platformpmcustatus",  kPropertyPlatformPMCUStatus,        ArgKind::kIndex, ArgKind::kIndex,     ArgKind::kIndex},
    {"platformsmpsnumber",  kPropertyPlatformSMPSNumber,        ArgKind::kNone,  ArgKind::kNone,      ArgKind::kNone},
    {"platformreset",       kPropertyPlatformReset,             ArgKind::kNone,  ArgKind::kBool,      ArgKind::kBool},
    {"audiovolume",         kPropertyAudioVolume,               ArgKind::kIndex, ArgKind::kIndexByte, ArgKind::kIndexByte},
    {"audiophantompower",   kPropertyAudioPhantomPower,         ArgKind::kIndex, ArgKind::kIndexBool, ArgKind::kIndexBool},
    {"audioampnumber",      kPropertyAudioAmpNumber,            ArgKind::kNone,  ArgKind::kNone,      ArgKind::kNone},
    {"audioampmute",        kPropertyAudioAmpMute,              ArgKind::kIndex, ArgKind::kIndexBool, ArgKind::kIndexBool},
    {"audioanaloggain",     kPropertyAudioAnalogGain,           ArgKind::kIndex, ArgKind::kIndexByte, ArgKind::kIndexByte},
};

constexpr std::chrono::milliseconds kHeartbeatPeriod{2000};
constexpr std::chrono::milliseconds kHeartbeatTimeout{6000};
constexpr std::chrono::milliseconds kBootCompleteRetry{1000};

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

const char *operator_name(Operator op)
{
    switch (op) {
    case Operator::kSet: return "SET";
    case Operator::kGet: return "GET";
    case Operator::kSetGet: return "SETGET";
    case Operator::kEvent: return "EVENT";
    case Operator::kSetResponse: return "SET_RESPONSE";
    case Operator::kGetResponse: return "GET_RESPONSE";
    case Operator::kSetGetResponse: return "SETGET_RESPONSE";
    default: return "UNKNOWN";
    }
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

constexpr int kInvalidGpioNum = 255;

std::string trim(const std::string &s)
{
    const auto begin = s.find_first_not_of(" \t\r\n");
    if (begin == std::string::npos) {
        return {};
    }
    const auto end = s.find_last_not_of(" \t\r\n");
    return s.substr(begin, end - begin + 1);
}

std::string gpio_sysfs_dir(int gpio_num)
{
    return "/sys/class/gpio/gpio" + std::to_string(gpio_num);
}

std::string gpio_sysfs_value_path(int gpio_num)
{
    return gpio_sysfs_dir(gpio_num) + "/value";
}

std::string gpio_sysfs_direction_path(int gpio_num)
{
    return gpio_sysfs_dir(gpio_num) + "/direction";
}

bool write_text_file(const std::string &path, const std::string &value)
{
    std::ofstream out(path);
    if (!out.is_open()) {
        SPDLOG_ERROR("BDIF: failed to open '{}'", path);
        return false;
    }
    out << value << std::endl;
    if (out.fail()) {
        SPDLOG_ERROR("BDIF: failed to write '{}' to '{}'", value, path);
        return false;
    }
    return true;
}

bool export_gpio_sysfs(int gpio_num)
{
    if (gpio_num == kInvalidGpioNum) {
        return true;
    }

    const std::string gpio_dir = gpio_sysfs_dir(gpio_num);
    if (::access(gpio_dir.c_str(), F_OK) == 0) {
        return true;
    }

    if (!write_text_file("/sys/class/gpio/export", std::to_string(gpio_num))) {
        return false;
    }

    for (int retry = 0; retry < 10; ++retry) {
        if (::access(gpio_sysfs_direction_path(gpio_num).c_str(), W_OK) == 0 &&
            ::access(gpio_sysfs_value_path(gpio_num).c_str(), W_OK) == 0) {
            return true;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    SPDLOG_ERROR("BDIF: sysfs gpio{} paths did not become ready after export", gpio_num);
    return false;
}

bool set_gpio_direction(int gpio_num, const std::string &direction)
{
    if (gpio_num == kInvalidGpioNum) {
        return true;
    }
    return write_text_file(gpio_sysfs_direction_path(gpio_num), direction);
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
    bool has_queued_property(uint16_t property_id) const;

    void maybe_send_boot_complete();
    void maybe_send_heartbeat();
    void check_heartbeat_timeout();

    void handle_set_post_func();
    void handle_get_post_func();
    void handle_setget_post_func();
    bool prepare_update_gpios();

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
    std::string platform_hw_variant;
    int_fast32_t platform_hw_ver;
    std::vector<int_fast32_t> platform_amp_temp;
    std::vector<int_fast32_t> platform_amp_status;
    std::vector<int_fast32_t> platform_smcu_status;
    std::vector<int_fast32_t> platform_smps_number;
    std::vector<int_fast32_t> platform_pmcu_status;

    // Audio parameters
    std::vector<int_fast32_t> audio_volume;
    std::vector<bool> audio_phantom_power;
    int_fast32_t audio_amp_number;
    std::vector<bool> audio_amp_mute;
    std::vector<int_fast32_t> audio_analog_gain;

    // Command parameters (observer-driven)
    std::string set_cmd_;
    std::string get_cmd_;
    std::string setget_cmd_;

    int num_amps{0};
    std::string uart_device_;
    std::string fw_file_;
    int nrst_gpio_num_{kInvalidGpioNum};
    int boot0_gpio_num_{kInvalidGpioNum};

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
    bool boot_complete_inflight_{false};
    Clock::time_point last_boot_complete_sent_{Clock::now()};

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
    get_property("uart_device", uart_device_);
    get_property("fw_file", fw_file_);
    int_fast32_t nrst_gpio_num_value = kInvalidGpioNum;
    int_fast32_t boot0_gpio_num_value = kInvalidGpioNum;
    get_property("nrst_gpio_num", nrst_gpio_num_value);
    get_property("boot0_gpio_num", boot0_gpio_num_value);
    nrst_gpio_num_ = static_cast<int>(nrst_gpio_num_value);
    boot0_gpio_num_ = static_cast<int>(boot0_gpio_num_value);

    port_.set_device(uart_device_);
    SPDLOG_INFO("BDIF: configured uart_device='{}' fw_file='{}' nrst_gpio_num={} boot0_gpio_num={}",
                uart_device_, fw_file_, nrst_gpio_num_, boot0_gpio_num_);

    prepare_update_gpios();

    const size_t amp_slots = 4;
    num_amps = static_cast<int>(amp_slots);
    platform_amp_temp.resize(amp_slots);
    platform_amp_status.resize(amp_slots);
    platform_smcu_status.resize(amp_slots);
    platform_smps_number.resize(amp_slots);
    platform_pmcu_status.resize(amp_slots);
    audio_volume.resize(amp_slots);
    audio_phantom_power.resize(amp_slots);
    audio_amp_mute.resize(amp_slots);
    audio_analog_gain.resize(amp_slots);

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
    boot_complete_inflight_ = false;

    return port_.open();
}

bool BDIFClient::prepare_update_gpios()
{
    if (!export_gpio_sysfs(boot0_gpio_num_)) {
        SPDLOG_ERROR("BDIF: failed to export BOOT0 gpio {}", boot0_gpio_num_);
        return false;
    }

    if (!export_gpio_sysfs(nrst_gpio_num_)) {
        SPDLOG_ERROR("BDIF: failed to export NRST gpio {}", nrst_gpio_num_);
        return false;
    }

    // Keep NRST released using open-drain style semantics: input releases the line,
    // while firmware update code can later drive low when it needs to assert reset.
    if (!set_gpio_direction(nrst_gpio_num_, "in")) {
        SPDLOG_ERROR("BDIF: failed to set NRST gpio {} direction to input", nrst_gpio_num_);
        return false;
    }

    SPDLOG_INFO("BDIF: prepared update gpios boot0={} nrst={} (nrst released as input/open-drain style)",
                boot0_gpio_num_, nrst_gpio_num_);
    return true;
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
        SPDLOG_ERROR("BDIF: RX {} property 0x{:04x} result={} payload={}",
                     operator_name(op), property, result, hex_string(value_ptr, value_len));
        return;
    }

    if (op == Operator::kEvent) {
        SPDLOG_INFO("BDIF: RX EVENT property 0x{:04x} payload={}",
                    property, hex_string(value_ptr, value_len));
        return;
    }
    if (is_response(op)) {
        SPDLOG_INFO("BDIF: RX {} property 0x{:04x} result={} payload={}",
                    operator_name(op), property, result, hex_string(value_ptr, value_len));
    } else {
        SPDLOG_INFO("BDIF: RX {} property 0x{:04x} payload={}",
                    operator_name(op), property, hex_string(value_ptr, value_len));
    }

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
            if (protocol_ver != kBdifProtocolVersion) {
                SPDLOG_WARN("BDIF: protocol version mismatch (expected '{}')", kBdifProtocolVersion);
            }
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
    case kPropertyPlatformHardwareVariant:
        if (value_valid) {
            platform_hw_variant = std::string(reinterpret_cast<const char*>(value_ptr), value_len);
            SPDLOG_DEBUG("BDIF: ack platform hw variant '{}'", platform_hw_variant);
        } else {
            SPDLOG_DEBUG("BDIF: ack platform hw variant");
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
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            const auto status = static_cast<int_fast32_t>(read_u32(1, value_len - 1));
            if (idx >= 0) {
                if (static_cast<size_t>(idx) >= platform_smcu_status.size()) {
                    platform_smcu_status.resize(static_cast<size_t>(idx) + 1);
                }
                platform_smcu_status[idx] = status;
            }
            SPDLOG_DEBUG("BDIF: ack smcu status[{}] 0x{:08x}", idx, status);
        } else if (value_valid) {
            const auto status = static_cast<int_fast32_t>(read_u32(0, value_len));
            platform_smcu_status.assign(1, status);
            SPDLOG_DEBUG("BDIF: ack smcu status 0x{:08x}", status);
        } else {
            SPDLOG_DEBUG("BDIF: ack smcu status");
        }
        break;
    case kPropertyPlatformBootComplete:
        boot_complete_inflight_ = false;
        if (value_valid) {
            boot_complete_acked_ = value_len > 0 ? value_ptr[0] != 0 : false;
            SPDLOG_DEBUG("BDIF: ack boot complete {}", boot_complete_acked_);
        } else {
            boot_complete_acked_ = true; // Treat SET ack as success without value.
            SPDLOG_DEBUG("BDIF: ack boot complete");
        }
        break;
    case kPropertyPlatformPMCUStatus:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            const auto status = static_cast<int_fast32_t>(read_u32(1, value_len - 1));
            if (idx >= 0) {
                if (static_cast<size_t>(idx) >= platform_pmcu_status.size()) {
                    platform_pmcu_status.resize(static_cast<size_t>(idx) + 1);
                }
                platform_pmcu_status[idx] = status;
            }
            SPDLOG_DEBUG("BDIF: ack pmcu status[{}] 0x{:08x}", idx, status);
        } else if (value_valid) {
            const auto status = static_cast<int_fast32_t>(read_u32(0, value_len));
            platform_pmcu_status.assign(1, status);
            SPDLOG_DEBUG("BDIF: ack pmcu status 0x{:08x}", status);
        } else {
            SPDLOG_DEBUG("BDIF: ack pmcu status");
        }
        break;
    case kPropertyPlatformSMPSNumber:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            const auto count = static_cast<int_fast32_t>(read_u32(1, value_len - 1));
            if (idx >= 0) {
                if (static_cast<size_t>(idx) >= platform_smps_number.size()) {
                    platform_smps_number.resize(static_cast<size_t>(idx) + 1);
                }
                platform_smps_number[idx] = count;
            }
            SPDLOG_DEBUG("BDIF: ack smps number[{}]={}", idx, count);
        } else if (value_valid) {
            const auto count = static_cast<int_fast32_t>(read_u32(0, value_len));
            if (platform_smps_number.empty()) {
                platform_smps_number.push_back(count);
            } else {
                platform_smps_number[0] = count;
            }
            SPDLOG_DEBUG("BDIF: ack smps number={}", count);
        } else {
            SPDLOG_DEBUG("BDIF: ack smps number");
        }
        break;
    case kPropertyAudioVolume:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            if (idx >= 0 && idx < num_amps) {
                audio_volume[idx] = static_cast<int_fast32_t>(value_ptr[1]);
                SPDLOG_DEBUG("BDIF: ack volume[{}]={}", idx, audio_volume[idx]);
            }
        } else if (value_valid) {
            SPDLOG_DEBUG("BDIF: ack volume payload={}", hex_string(value_ptr, value_len));
        } else {
            SPDLOG_DEBUG("BDIF: ack volume");
        }
        break;
    case kPropertyAudioPhantomPower:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            if (idx >= 0 && idx < num_amps) {
                audio_phantom_power[idx] = value_ptr[1] != 0;
                SPDLOG_DEBUG("BDIF: ack phantom power[{}]={}", idx, static_cast<bool>(audio_phantom_power[idx]));
            }
        } else {
            SPDLOG_DEBUG("BDIF: ack phantom power");
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
    case kPropertyAudioAnalogGain:
        if (value_valid && value_len >= 2) {
            const int idx = static_cast<int>(value_ptr[0]) - 1;
            if (idx >= 0 && idx < num_amps) {
                audio_analog_gain[idx] = static_cast<int_fast32_t>(value_ptr[1]);
                SPDLOG_DEBUG("BDIF: ack analog gain[{}]={}", idx, audio_analog_gain[idx]);
            }
        } else if (value_valid) {
            SPDLOG_DEBUG("BDIF: ack analog gain payload={}", hex_string(value_ptr, value_len));
        } else {
            SPDLOG_DEBUG("BDIF: ack analog gain");
        }
        break;
    default:
        break;
    }
}

bool BDIFClient::enqueue_tx(Operator op, uint16_t property_id, const std::vector<uint8_t> &value)
{
    if (property_id == kPropertyPlatformBootComplete) {
        if (has_queued_property(property_id)) {
            return true;
        }

        if (tx_queue_.size() >= kMaxTxQueue) {
            const auto &dropped = tx_queue_.back();
            SPDLOG_WARN("BDIF: tx queue full ({}), dropping queued property 0x{:04x} to prioritize boot_complete",
                        tx_queue_.size(), dropped.property_id);
            tx_queue_.pop_back();
        }

        tx_queue_.push_front(TxRequest{op, property_id, value});
        return true;
    }

    if (!boot_complete_acked_ && tx_queue_.size() >= (kMaxTxQueue - 1)) {
        SPDLOG_WARN("BDIF: reserving tx queue space for boot_complete, dropping property 0x{:04x}",
                    property_id);
        return false;
    }

    if (tx_queue_.size() >= kMaxTxQueue) {
        SPDLOG_WARN("BDIF: tx queue full ({}), dropping property 0x{:04x}", tx_queue_.size(), property_id);
        return false;
    }
    tx_queue_.push_back(TxRequest{op, property_id, value});
    return true;
}

bool BDIFClient::has_queued_property(uint16_t property_id) const
{
    return std::any_of(tx_queue_.begin(), tx_queue_.end(),
                       [&](const TxRequest &req) { return req.property_id == property_id; });
}

void BDIFClient::drain_tx_queue()
{
    size_t sent = 0;
    while (!tx_queue_.empty() && sent < kDrainBatch) {
        const auto &req = tx_queue_.front();
        if (!boot_complete_acked_ && req.property_id != kPropertyPlatformBootComplete) {
            break;
        }
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
        SPDLOG_WARN("BDIF: empty numeric command");
        return false;
    }

    std::vector<std::string> tokens;
    tokens.push_back(token);
    while (iss >> token) {
        tokens.push_back(token);
    }

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
            bool b = false;
            if (parse_bool_token(tokens[i], b)) {
                value.push_back(static_cast<uint8_t>(b ? 1 : 0));
            } else {
                SPDLOG_WARN("BDIF: failed to parse payload byte '{}'", tokens[i]);
                return false;
            }
        }
    }

    return true;
}

bool BDIFClient::send_command_from_param(const std::string &cmd, Operator op)
{
    uint16_t property_id = 0;
    std::vector<uint8_t> payload;
    if (cmd.empty()) {
        SPDLOG_WARN("BDIF: empty command parameter for {}", operator_name(op));
        return false;
    }
    std::istringstream iss(cmd);
    std::string token;
    std::vector<std::string> tokens;
    while (iss >> token) {
        tokens.push_back(token);
    }
    if (tokens.empty()) {
        SPDLOG_WARN("BDIF: command parameter for {} contained no tokens", operator_name(op));
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
    case ArgKind::kIndexByte: {
        if (args.size() != 2) {
            SPDLOG_WARN("BDIF: command '{}' expects <index> <byte>", name);
            return false;
        }
        uint8_t idx = 0;
        if (!parse_index(args[0], idx)) {
            return false;
        }
        uint8_t byte = 0;
        try {
            const auto parsed = std::stoul(args[1], nullptr, 0);
            if (parsed > 0xFF) {
                SPDLOG_WARN("BDIF: command '{}' byte arg '{}' out of range", name, args[1]);
                return false;
            }
            byte = static_cast<uint8_t>(parsed);
        } catch (const std::exception &) {
            SPDLOG_WARN("BDIF: command '{}' expects byte arg, got '{}'", name, args[1]);
            return false;
        }
        value.push_back(idx);
        value.push_back(byte);
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
        SPDLOG_ERROR("BDIF: unable to send {} property 0x{:04x}; UART not ready",
                     operator_name(op), property_id);
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
        SPDLOG_ERROR("BDIF: TX {} property 0x{:04x} failed payload={}",
                     operator_name(op), property_id, hex_string(value.data(), value.size()));
        return false;
    }

    SPDLOG_INFO("BDIF: TX {} property 0x{:04x} payload={}",
                operator_name(op), property_id, hex_string(value.data(), value.size()));

    return true;
}

void BDIFClient::maybe_send_heartbeat()
{
    const auto now = Clock::now();
    if (!port_.is_open()) {
        return;
    }
    if (!boot_complete_acked_) {
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

void BDIFClient::maybe_send_boot_complete()
{
    if (boot_complete_acked_) {
        return;
    }

    const auto now = Clock::now();
    if (boot_complete_inflight_ && now - last_boot_complete_sent_ < kBootCompleteRetry) {
        return;
    }

    const std::vector<uint8_t> payload = {1};
    if (enqueue_tx(Operator::kSet, kPropertyPlatformBootComplete, payload)) {
        boot_complete_inflight_ = true;
        last_boot_complete_sent_ = now;
        SPDLOG_DEBUG("BDIF: sending boot_complete");
    }
}

void BDIFClient::check_heartbeat_timeout()
{
    if (!boot_complete_acked_) {
        return;
    }

    const auto now = Clock::now();
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
}

void BDIFClient::handle_set_post_func()
{
    if (!send_command_from_param(set_cmd_, Operator::kSet)) {
        SPDLOG_ERROR("BDIF: failed to enqueue set command '{}'", set_cmd_);
    }
}

void BDIFClient::handle_get_post_func()
{
    if (!send_command_from_param(get_cmd_, Operator::kGet)) {
        SPDLOG_ERROR("BDIF: failed to enqueue get command '{}'", get_cmd_);
    }
}

void BDIFClient::handle_setget_post_func()
{
    if (!send_command_from_param(setget_cmd_, Operator::kSetGet)) {
        SPDLOG_ERROR("BDIF: failed to enqueue setget command '{}'", setget_cmd_);
    }
}

void BDIFClient::process()
{
    if (!ensure_port()) {
        return;
    }

    poll_rx_port();
    maybe_send_boot_complete();
    maybe_send_heartbeat();
    check_heartbeat_timeout();

    if (!boot_complete_acked_ || !link_ready_) {
        drain_tx_queue();
        return;
    }

    drain_tx_queue();
}

} // namespace
