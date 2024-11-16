
#include <bosepro/algorithm.h>

#include <cstdint>


namespace {


class CpuUsage : public bosepro::Algorithm
{
public:
    CpuUsage(const bosepro::BlockConfiguration &configuration);
    virtual ~CpuUsage() = default;

    virtual void process() override;

private:
    float cpu1;
    float cpu2;
    float cpu3;
    float cpu4;
    bool high_cpu_usage;

    ALGORITHM_DECLARE(CpuUsage);
};

ALGORITHM_REGISTER(CpuUsage, "cpu_usage");


CpuUsage::CpuUsage(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    assign_telemetry("gain_meter", &cpu1);
    assign_telemetry("gain_meter", &cpu2);
    assign_telemetry("gain_meter", &cpu3);
    assign_telemetry("gain_meter", &cpu4);
    assign_telemetry("gain_meter", &high_cpu_usage);

    cpu1 = 0;
    cpu2 = 0;
    cpu3 = 0;
    cpu4 = 0;
    high_cpu_usage = false;
}


void CpuUsage::process()
{
    cpu1 = 1;
    cpu2 = 2;
    cpu3 = 3;
    cpu4 = 4;
    high_cpu_usage = false;
}


} // namespace
