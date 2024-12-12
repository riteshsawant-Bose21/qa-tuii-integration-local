#include <bosepro/module.h>
#include <bosepro/task.h>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>
#include <numeric>
#include <algorithm>

namespace {

class CpuUsage : public bosepro::Module
{
public:
    CpuUsage(const bosepro::BlockConfiguration &configuration);
    virtual ~CpuUsage() = default;

    virtual void process();

private:
    float cpu;
    bool  high_cpu_usage;
    bosepro::DspTelemetryMemory<bool[]> test;
    uint64_t idle_time;
    uint64_t total_time;

    bool parse_cpu_stats();

    MODULE_DECLARE(CpuUsage);
};

MODULE_REGISTER(CpuUsage, "cpu_usage");

CpuUsage::CpuUsage(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration),
      idle_time(0), total_time(0)
{
    assign_telemetry("cpu", &cpu, nullptr);
    assign_telemetry("high_cpu_usage", &high_cpu_usage, nullptr);
    assign_telemetry("test", test, nullptr);
}

bool CpuUsage::parse_cpu_stats()
{
    std::ifstream stat_file("/proc/stat");
    if (!stat_file.is_open()) {
        SPDLOG_ERROR("Failed to open /proc/stat");
        return false;
    }

    std::string line;

    while (std::getline(stat_file, line)) {
        if (line.find("cpu ") == 0) {
            std::istringstream iss(line);
            std::string cpu_label;
            uint64_t user, nice, system, idle, iowait, irq, softirq, steal;

            iss >> cpu_label >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;

            uint64_t idle_t = idle + iowait;
            uint64_t total_t = user + nice + system + idle_t + irq + softirq + steal;

            idle_time = idle_t;
            total_time = total_t;

            return true;
        }
    }

    return false;
}

void CpuUsage::process()
{
    static uint64_t prev_idle_time = 0;
    static uint64_t prev_total_time = 0;

    if (!parse_cpu_stats()) {
        SPDLOG_ERROR("Failed to parse CPU stats");
        return;
    }

    uint64_t delta_idle = idle_time - prev_idle_time;
    uint64_t delta_total = total_time - prev_total_time;

    cpu = delta_total == 0 ? 0.0f : (100.0f * static_cast<float>(delta_total - delta_idle) / static_cast<float>(delta_total));

    prev_idle_time = idle_time;
    prev_total_time = total_time;

    if (cpu >= 80.0f && high_cpu_usage == false) 
    {
        high_cpu_usage = true;
        send_event_telemetry("high_cpu_usage");
    }
    else if (cpu < 80.0f && high_cpu_usage == true)
    {
        high_cpu_usage = false;
        send_event_telemetry("high_cpu_usage");
    }
}


} // namespace
