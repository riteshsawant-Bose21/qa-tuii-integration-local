#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>
#include <numeric>

namespace {


class IoCard : public bosepro::Module
{
public:
    IoCard(const bosepro::BlockConfiguration &configuration);
    virtual ~IoCard() = default;

    virtual void process();

private:
    std::vector<std::string> sysfs_paths;
    std::vector<std::string> parameter_names;
    std::map<std::string, std::string> sysfs_map;

    std::string read_id;
    bool        phantom_power;

    void read_id_func();
    void phantom_power_func();

    MODULE_DECLARE(IoCard);
};

MODULE_REGISTER(IoCard, "io_card");

IoCard::IoCard(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration)
{
    get_property("parameter_paths", sysfs_paths);
    for (auto &path : sysfs_paths)
    {
        std::string key = path.substr(path.rfind('/') + 1);
        sysfs_map[key.substr(key.find('_') + 1)] = path;
    }

    assign_parameter("read_id", &read_id, 
                     POST_FUNCTION_SCALAR(read_id_func));
    assign_parameter("phantom_power", &phantom_power, 
                     POST_FUNCTION_SCALAR(phantom_power_func));

    assign_telemetry("phantom_power", &phantom_power);
}


void IoCard::read_id_func()
{
    std::ifstream ifs(sysfs_map["read_id"]);
    if (!ifs.is_open()) {
        SPDLOG_ERROR("Failed to open sysfs entry: {}", sysfs_map["read_id"]);
        return;
    }

    read_id.clear();
    std::getline(ifs, read_id);
    SPDLOG_DEBUG("Read ID: {}", read_id);
}


void IoCard::phantom_power_func()
{
    std::ofstream ofs(sysfs_map["phantom_power"]);
    if (!ofs.is_open()) {
        SPDLOG_ERROR("Failed to open sysfs entry for writing: {}", sysfs_map["phantom_power"]);
        return;
    }

    ofs << (phantom_power ? 1 : 0) << std::endl;
}


void IoCard::process()
{
    
}


} // namespace
