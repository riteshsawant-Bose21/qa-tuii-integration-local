#include <bosepro/module.h>
#include <cstdint>
#include <fstream>
#include <vector>
#include <string>
#include <map>
#include <sstream>

#define SYSFS_ROOT "/sys/devices/virtual/bosepro/"

namespace {

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

    int num_gain_chs;
    std::vector<std::string> gain_paths;
    int num_php_chs;
    std::vector<std::string> php_paths;
    int num_user_gpio;
    std::vector<std::string> user_gpio_ctrl_paths;

    void change_gain_post_func(int index);
    void change_php_post_func(int index);
    void change_gpio_dir_post_func(int index);
    void change_gpio_val_post_func(int index);

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

    // Map each index to its GPIO path for fast lookup
    for (size_t i = 0; i < gain_paths.size(); ++i) {
        gain_path_map[i] = gain_paths[i];
    }
    for (size_t i = 0; i < php_paths.size(); ++i) {
        php_path_map[i] = php_paths[i];
    }
    for (size_t i = 0; i < user_gpio_ctrl_paths.size(); ++i) {
        gpio_ctrl_path_map[i] = user_gpio_ctrl_paths[i];
    }

    // Initialize DSP parameter for LED states
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
    if (value > 3) value = 3;
    if (value < 0) value = 0;

    std::ofstream gain_out(path);
    if (!gain_out.is_open()) {
        SPDLOG_ERROR("Failed to open GPIO sysfs path: {}", path);
        return;
    }

    gain_out << value << std::endl;
    SPDLOG_DEBUG("Set gain[{}] to {}", index, value);
}

void HWControl::change_php_post_func(int index)
{
    auto it = php_path_map.find(index);
    if (it == php_path_map.end()) {
        SPDLOG_ERROR("No php path mapped for index {}", index);
        return;
    }

    const std::string &path = SYSFS_ROOT + it->second;
    int value = php[index] ? true : false;

    std::ofstream php_out(path);
    if (!php_out.is_open()) {
        SPDLOG_ERROR("Failed to open GPIO sysfs path: {}", path);
        return;
    }

    php_out << value << std::endl;
    SPDLOG_DEBUG("Set php[{}] to {}", index, value);
}

// gpio_ctrl pin/state mapping
// enum gpio_dir_state {
//     GPIO_CTRL_OUTPUT_HI = 0x1,
//     GPIO_CTRL_OUTPUT_LO = 0x7,
//     GPIO_CTRL_INPUT_HI  = 0x3,
//     GPIO_CTRL_HI_Z      = 0x6
// };

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
    //int value = GPIO_CTRL_HI_Z; // default to hi-z
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

void HWControl::process() {
}
}
