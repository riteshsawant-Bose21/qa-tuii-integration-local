#include <bosepro/module.h>
#include <chrono>
#include <cstdint>
#include <cstring>
#include <dirent.h>
#include <errno.h>
#include <fstream>
#include <limits.h>
#include <map>
#include <sstream>
#include <string>
#include <thread>
#include <unistd.h>
#include <vector>

#define SYSFS_ROOT "/sys/devices/virtual/bosepro/"
#define PWM_SYSFS_ROOT "/sys/class/pwm"

namespace {

constexpr int kPhpLedPwmChannel = 0;
constexpr int kPhpLedPwmPeriodNs = 1000000;

bool path_exists(const std::string &path)
{
    return access(path.c_str(), F_OK) == 0;
}

bool write_text_file(const std::string &path, const std::string &value)
{
    std::ofstream out(path);
    if (!out.is_open()) {
        SPDLOG_ERROR("Failed to open sysfs path: {}", path);
        return false;
    }

    out << value << std::endl;
    if (!out.good()) {
        SPDLOG_ERROR("Failed to write '{}' to {}", value, path);
        return false;
    }

    return true;
}

bool read_int_file(const std::string &path, int &value)
{
    std::ifstream in(path);
    if (!in.is_open()) {
        SPDLOG_ERROR("Failed to open sysfs path: {}", path);
        return false;
    }

    in >> value;
    if (in.fail()) {
        SPDLOG_ERROR("Failed to read integer from {}", path);
        return false;
    }

    return true;
}

std::string read_symlink_target(const std::string &path)
{
    char buffer[PATH_MAX] = {};
    const ssize_t length = readlink(path.c_str(), buffer, sizeof(buffer) - 1);
    if (length < 0) {
        return "";
    }

    buffer[length] = '\0';
    return std::string(buffer, static_cast<size_t>(length));
}

std::string pwm_label_to_device_suffix(const std::string &label)
{
    static const std::map<std::string, std::string> kLabelToSuffix = {
        {"PWM1", "30660000.pwm"},
        {"PWM2", "30670000.pwm"},
        {"PWM3", "30680000.pwm"},
        {"PWM4", "30690000.pwm"},
    };

    auto it = kLabelToSuffix.find(label);
    return it == kLabelToSuffix.end() ? "" : it->second;
}

std::string discover_pwm_chip_path(const std::string &label)
{
    if (label.empty()) {
        return "";
    }

    if (label.rfind(PWM_SYSFS_ROOT "/pwmchip", 0) == 0) {
        return label;
    }

    if (label.rfind("pwmchip", 0) == 0) {
        return std::string(PWM_SYSFS_ROOT) + "/" + label;
    }

    const std::string device_suffix = pwm_label_to_device_suffix(label);
    DIR *dir = opendir(PWM_SYSFS_ROOT);
    if (!dir) {
        SPDLOG_ERROR("Failed to open {}: {}", PWM_SYSFS_ROOT, strerror(errno));
        return "";
    }

    std::string resolved_chip_path;
    while (dirent *entry = readdir(dir)) {
        const std::string chip_name(entry->d_name);
        if (chip_name.rfind("pwmchip", 0) != 0) {
            continue;
        }

        const std::string chip_path = std::string(PWM_SYSFS_ROOT) + "/" + chip_name;
        const std::string device_link = read_symlink_target(chip_path + "/device");
        if (!device_suffix.empty() && device_link.find(device_suffix) != std::string::npos) {
            resolved_chip_path = chip_path;
            break;
        }

        std::ifstream of_name_in(chip_path + "/device/of_node/name");
        std::string of_name;
        if (of_name_in.is_open()) {
            std::getline(of_name_in, of_name);
            if (of_name == label) {
                resolved_chip_path = chip_path;
                break;
            }
        }
    }

    closedir(dir);

    if (resolved_chip_path.empty()) {
        SPDLOG_ERROR("Unable to resolve PWM chip path for '{}'", label);
    } else {
        SPDLOG_DEBUG("Resolved {} to {}", label, resolved_chip_path);
    }

    return resolved_chip_path;
}

bool ensure_pwm_channel_exported(const std::string &chip_path, int channel)
{
    const std::string pwm_path = chip_path + "/pwm" + std::to_string(channel);
    if (path_exists(pwm_path)) {
        return true;
    }

    if (!write_text_file(chip_path + "/export", std::to_string(channel))) {
        return false;
    }

    for (int attempt = 0; attempt < 20; ++attempt) {
        if (path_exists(pwm_path)) {
            return true;
        }
        std::this_thread::sleep_for(std::chrono::milliseconds(10));
    }

    SPDLOG_ERROR("PWM channel path did not appear after export: {}", pwm_path);
    return false;
}

bool set_pwm_output(const std::string &chip_path, int channel, bool enabled)
{
    if (chip_path.empty()) {
        return false;
    }

    if (!ensure_pwm_channel_exported(chip_path, channel)) {
        return false;
    }

    const std::string pwm_path = chip_path + "/pwm" + std::to_string(channel);
    const std::string enable_path = pwm_path + "/enable";
    const std::string period_path = pwm_path + "/period";
    const std::string duty_cycle_path = pwm_path + "/duty_cycle";

    if (path_exists(enable_path)) {
        write_text_file(enable_path, "0");
    }

    if (enabled) {
        if (!write_text_file(period_path, std::to_string(kPhpLedPwmPeriodNs))) {
            return false;
        }
        if (!write_text_file(duty_cycle_path, std::to_string(kPhpLedPwmPeriodNs))) {
            return false;
        }
        if (path_exists(enable_path) && !write_text_file(enable_path, "1")) {
            return false;
        }
    } else {
        if (path_exists(duty_cycle_path) && !write_text_file(duty_cycle_path, "0")) {
            return false;
        }
    }

    return true;
}

class HWControl : public bosepro::Module {
public:
    HWControl(const bosepro::BlockConfiguration &configuration);
    virtual ~HWControl() = default;
    virtual void process() override;

private:
    bosepro::DspParamMemory<int_fast32_t[]> gain;
    bosepro::DspParamMemory<bool[]> php;
    bosepro::DspParamMemory<std::string[]> gpio_dir;
    bosepro::DspParamMemory<int_fast32_t[]> gpio_val;
    std::map<int, std::string> gain_path_map;
    std::map<int, std::string> php_path_map;
    std::map<int, std::string> gpio_ctrl_path_map;

    int_fast32_t num_gain_chs;
    std::vector<std::string> gain_paths;
    int_fast32_t num_php_chs;
    std::vector<std::string> php_paths;
    int_fast32_t num_user_gpio;
    std::vector<std::string> user_gpio_ctrl_paths;
    std::string php_led_name;
    std::string php_led_chip_path;

    void change_gain_post_func(int index);
    void change_php_post_func(int index);
    void change_gpio_dir_post_func(int index);
    void change_gpio_val_post_func(int index);
    void sync_php_led_from_gpio(int index);

    MODULE_DECLARE(HWControl);
};

MODULE_REGISTER(HWControl, "hw_control");

HWControl::HWControl(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration)
{
    get_property("num_gain_chs", num_gain_chs);
    get_property("gain_paths", gain_paths);
    get_property("num_php_chs", num_php_chs);
    get_property("php_paths", php_paths);
    get_property("num_user_gpio", num_user_gpio);
    get_property("user_gpio_ctrl_paths", user_gpio_ctrl_paths);
    get_property("php_led", php_led_name);

    for (size_t i = 0; i < gain_paths.size(); ++i) {
        gain_path_map[i] = gain_paths[i];
    }
    for (size_t i = 0; i < php_paths.size(); ++i) {
        php_path_map[i] = php_paths[i];
    }
    for (size_t i = 0; i < user_gpio_ctrl_paths.size(); ++i) {
        gpio_ctrl_path_map[i] = user_gpio_ctrl_paths[i];
    }

    if (!php_led_name.empty()) {
        php_led_chip_path = discover_pwm_chip_path(php_led_name);
    }

    assign_parameter("gain", gain, POST_FUNCTION_VECTOR(change_gain_post_func));
    assign_parameter("php", php, POST_FUNCTION_VECTOR(change_php_post_func));
    assign_parameter("gpio_dir", gpio_dir, POST_FUNCTION_VECTOR(change_gpio_dir_post_func));
    assign_parameter("gpio_val", gpio_val, POST_FUNCTION_VECTOR(change_gpio_val_post_func));
}

void HWControl::change_gain_post_func(int index)
{
    auto it = gain_path_map.find(index);
    if (it == gain_path_map.end()) {
        SPDLOG_ERROR("No gain path mapped for index {}", index);
        return;
    }

    const std::string &path = SYSFS_ROOT + it->second;
    int value = gain[index];
    if (value < 0) value = 0;
    if (value > 4) value = 4;
    if (value > 2) value = 1 << (value - 1);

    std::ofstream gain_out(path);
    if (!gain_out.is_open()) {
        SPDLOG_ERROR("Failed to open GPIO sysfs path: {}", path);
        return;
    }

    gain_out << value << std::endl;
    SPDLOG_DEBUG("Set gain[{}] to {}", index, value);
}

void HWControl::sync_php_led_from_gpio(int index)
{
    if (php_led_name.empty()) {
        return;
    }

    auto it = php_path_map.find(index);
    if (it == php_path_map.end()) {
        SPDLOG_ERROR("No php path mapped for index {}", index);
        return;
    }

    if (php_led_chip_path.empty()) {
        php_led_chip_path = discover_pwm_chip_path(php_led_name);
    }
    if (php_led_chip_path.empty()) {
        return;
    }

    int gpio_state = 0;
    const std::string path = std::string(SYSFS_ROOT) + it->second;
    if (!read_int_file(path, gpio_state)) {
        return;
    }

    if (!set_pwm_output(php_led_chip_path, kPhpLedPwmChannel, gpio_state == 0)) {
        SPDLOG_ERROR("Failed to sync php_led '{}' from gpio state {}", php_led_name, gpio_state);
        return;
    }

    SPDLOG_DEBUG("Synced php_led '{}' from gpio state {}", php_led_name, gpio_state);
}

void HWControl::change_php_post_func(int index)
{
    auto it = php_path_map.find(index);
    if (it == php_path_map.end()) {
        SPDLOG_ERROR("No php path mapped for index {}", index);
        return;
    }

    const std::string &path = SYSFS_ROOT + it->second;
    const int value = php[index] ? 1 : 0;

    std::ofstream php_out(path);
    if (!php_out.is_open()) {
        SPDLOG_ERROR("Failed to open GPIO sysfs path: {}", path);
        return;
    }

    php_out << value << std::endl;
    SPDLOG_DEBUG("Set php[{}] to {}", index, value);
    sync_php_led_from_gpio(index);
}

// gpio_ctrl pin/state mapping
// C1+ -- 3 pin circuit
// enum gpio_dir_state {
//     GPIO_CTRL_OUTPUT_HI = 0x1,
//     GPIO_CTRL_OUTPUT_LO = 0x7,
//     GPIO_CTRL_INPUT_HI  = 0x3,
//     GPIO_CTRL_HI_Z      = 0x6
// };

// C0 -- 2 pin circuit
enum gpio_dir_state {
    GPIO_CTRL_OUTPUT_HI = 0x0,
    GPIO_CTRL_OUTPUT_LO = 0x3,
    GPIO_CTRL_INPUT_HI  = 0x1
};

void HWControl::change_gpio_dir_post_func(int index)
{
    auto it = gpio_ctrl_path_map.find(index);
    if (it == gpio_ctrl_path_map.end()) {
        SPDLOG_ERROR("No gpio_ctrl path mapped for index {}", index);
        return;
    }

    const std::string &path = SYSFS_ROOT + it->second;
    std::string str_value = gpio_dir[index];
    int value = GPIO_CTRL_OUTPUT_LO;

    if (str_value == "in") {
        value = GPIO_CTRL_INPUT_HI;
    } else if (str_value == "out") {
        value = GPIO_CTRL_OUTPUT_LO;
    }

    std::ofstream gpio_dir_out(path);
    if (!gpio_dir_out.is_open()) {
        SPDLOG_ERROR("Failed to open gpio_ctrl sysfs path: {}", path);
        return;
    }

    gpio_dir_out << value << std::endl;
    SPDLOG_DEBUG("Set gpio_ctrl[{}] to {}", index, value);
}

void HWControl::change_gpio_val_post_func(int index)
{
    auto it = gpio_ctrl_path_map.find(index);
    if (it == gpio_ctrl_path_map.end()) {
        SPDLOG_ERROR("No gpio_val path mapped for index {}", index);
        return;
    }

    if (gpio_dir[index] != "out") {
        SPDLOG_ERROR("gpio_dir index {} is not an output gpio", index);
        return;
    }

    const std::string &path = SYSFS_ROOT + it->second;
    int value = gpio_val[index] ? GPIO_CTRL_OUTPUT_HI : GPIO_CTRL_OUTPUT_LO;

    std::ofstream gpio_val_out(path);
    if (!gpio_val_out.is_open()) {
        SPDLOG_ERROR("Failed to open gpio sysfs path: {}", path);
        return;
    }

    gpio_val_out << value << std::endl;
    SPDLOG_DEBUG("Set gpio_ctrl[{}] to {}", index, value);
}

void HWControl::process()
{
}
}
