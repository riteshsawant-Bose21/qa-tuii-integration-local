#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>
#include <numeric>

namespace {

void read_id_func()
{

}

void phantom_power_func()
{

}

class IoCard : public bosepro::Module
{
public:
    IoCard(const bosepro::BlockConfiguration &configuration);
    virtual ~IoCard() = default;

    virtual void process();

private:
    std::vector<std::string> sysfs_paths;

    std::string read_id;
    bool phantom_power;

    std::string status;

    MODULE_DECLARE(IoCard);
};

MODULE_REGISTER(IoCard, "proto_io_card");

IoCard::IoCard(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration),
      read_id(""), phantom_power()
{
    get_property("parameter_paths", sysfs_paths);

    assign_parameter("read_id", &read_id, &read_id_func);
    assign_parameter("phantom_power", &phantom_power, &phantom_power_func);

    assign_telemetry("status", &status, nullptr);
}

void IoCard::process()
{
    
}


} // namespace
