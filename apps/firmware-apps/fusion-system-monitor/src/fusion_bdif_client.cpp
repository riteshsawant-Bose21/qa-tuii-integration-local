#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <algorithm>

#define UART_DEV "/dev/ttymxc3"
#define SYSFS_ROOT "/sys/devices/virtual/bosepro/"

namespace {

class FusionBDIFClient : public bosepro::Module
{
public:
    FusionBDIFClient(const bosepro::BlockConfiguration &configuration);
    virtual ~FusionBDIFClient() = default;

    virtual void process();

private:
    bosepro::DspParamMemory<int_fast32_t[]> gain;
    bosepro::DspParamMemory<bool[]> php;
    std::map<int, std::string> gain_path_map;
    std::map<int, std::string> php_path_map;

    int num_gain_chs;
    std::vector<std::string> gain_paths;
    int num_php_chs;
    std::vector<std::string> php_paths;

    void change_gain_post_func(int index);
    void change_php_post_func(int index);
    
    MODULE_DECLARE(FusionBDIFClient);
};

MODULE_REGISTER(FusionBDIFClient, "fusion_bdif_client");

FusionBDIFClient::FusionBDIFClient(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration)
{
    // get uart handle

    // assign parameters based on hw (refer to gpio work by pushpa)
    get_property("num_gain_chs", num_gain_chs);
    get_property("gain_paths", gain_paths);
    get_property("num_php_chs", num_php_chs);
    get_property("php_paths", php_paths);

    // Map each index to its GPIO path for fast lookup
    for (size_t i = 0; i < gain_paths.size(); ++i) {
        gain_path_map[i] = gain_paths[i];
    }
    for (size_t i = 0; i < php_paths.size(); ++i) {
        php_path_map[i] = php_paths[i];
    }

    // Initialize DSP parameter for LED states
    assign_parameter("gain", gain, POST_FUNCTION_VECTOR(change_gain_post_func));
    assign_parameter("php", php, POST_FUNCTION_VECTOR(change_php_post_func));
}

void FusionBDIFClient::change_gain_post_func(int index)
{
    SPDLOG_DEBUG("fusion bdif change_gain index {}", index);
}

void FusionBDIFClient::change_php_post_func(int index)
{
    SPDLOG_DEBUG("fusion bdif change_php index {}", index);
}

void FusionBDIFClient::process()
{
    // do heartbeat
    // first time, test stm32 status and check fw version. 
    // compare fw ver against file name at /lib/firmware/fusion/amplifer
    // if file has newer version, do fw update and restart
}

} // namespace
