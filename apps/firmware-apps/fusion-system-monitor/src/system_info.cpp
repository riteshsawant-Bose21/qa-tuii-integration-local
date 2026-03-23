#include <bosepro/module.h>
#include <bosepro/periodic_task.h>

#include <algorithm>
#include <cstdint>
#include <filesystem>
#include <fstream>
#include <sstream>
#include <string>

namespace {

constexpr float kHighUsageThreshold = 80.0f;
constexpr const char *kSomTempPath = "/sys/class/thermal/thermal_zone0/temp";

class SystemInfo : public bosepro::Module
{
public:
    SystemInfo(const bosepro::BlockConfiguration &configuration);
    virtual ~SystemInfo() = default;

    virtual void process() override;

private:
    float cpu;
    bool high_cpu_usage;
    float ram_usage;
    bool high_ram_usage;
    float emmc_usage;
    bool high_emmc_usage;
    float usb_storage_usage;
    bool usb_connected;
    float temperature;
    uint64_t prev_idle_time;
    uint64_t prev_total_time;

    bool parse_cpu_stats(uint64_t &idle_time, uint64_t &total_time);
    bool parse_memory_info();
    bool parse_storage_usage(const std::string &path, float &usage);
    bool parse_temperature();

    MODULE_DECLARE(SystemInfo);
};

MODULE_REGISTER(SystemInfo, "system_info");

SystemInfo::SystemInfo(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration),
      cpu(0.0f),
      high_cpu_usage(false),
      ram_usage(0.0f),
      high_ram_usage(false),
      emmc_usage(0.0f),
      high_emmc_usage(false),
      usb_storage_usage(0.0f),
      usb_connected(false),
      temperature(0.0f),
      prev_idle_time(0),
      prev_total_time(0)
{
    assign_telemetry("cpu", &cpu);
    assign_telemetry("high_cpu_usage", &high_cpu_usage);
    assign_telemetry("ram", &ram_usage);
    assign_telemetry("high_ram_usage", &high_ram_usage);
    assign_telemetry("emmc", &emmc_usage);
    assign_telemetry("high_emmc_usage", &high_emmc_usage);
    assign_telemetry("usb_storage", &usb_storage_usage);
    assign_telemetry("usb_connected", &usb_connected);
    assign_telemetry("temperature", &temperature);
}

bool SystemInfo::parse_cpu_stats(uint64_t &idle_time, uint64_t &total_time)
{
    std::ifstream stat_file("/proc/stat");
    if (!stat_file.is_open()) {
        SPDLOG_ERROR("Failed to open /proc/stat");
        return false;
    }

    std::string line;
    while (std::getline(stat_file, line)) {
        if (line.rfind("cpu ", 0) != 0) {
            continue;
        }

        std::istringstream iss(line);
        std::string cpu_label;
        uint64_t user = 0;
        uint64_t nice = 0;
        uint64_t system = 0;
        uint64_t idle = 0;
        uint64_t iowait = 0;
        uint64_t irq = 0;
        uint64_t softirq = 0;
        uint64_t steal = 0;

        iss >> cpu_label >> user >> nice >> system >> idle >> iowait >> irq >> softirq >> steal;
        if (iss.fail()) {
            SPDLOG_ERROR("Failed to parse cpu stats line");
            return false;
        }

        idle_time = idle + iowait;
        total_time = user + nice + system + idle_time + irq + softirq + steal;
        return true;
    }

    SPDLOG_ERROR("Failed to find aggregate cpu stats");
    return false;
}

bool SystemInfo::parse_memory_info()
{
    std::ifstream meminfo_file("/proc/meminfo");
    if (!meminfo_file.is_open()) {
        SPDLOG_ERROR("Failed to open /proc/meminfo");
        return false;
    }

    std::string line;
    uint64_t mem_total = 0;
    uint64_t mem_available = 0;

    while (std::getline(meminfo_file, line)) {
        std::istringstream iss(line);
        std::string key;
        uint64_t value = 0;
        std::string unit;

        iss >> key >> value >> unit;

        if (key == "MemTotal:") {
            mem_total = value;
        } else if (key == "MemAvailable:") {
            mem_available = value;
        }

        if (mem_total != 0 && mem_available != 0) {
            break;
        }
    }

    if (mem_total == 0) {
        SPDLOG_ERROR("Failed to parse memory info");
        return false;
    }

    ram_usage = 100.0f * (1.0f - static_cast<float>(mem_available) / static_cast<float>(mem_total));
    return true;
}

bool SystemInfo::parse_storage_usage(const std::string &path, float &usage)
{
    try {
        const std::filesystem::space_info space = std::filesystem::space(path);
        if (space.capacity == 0) {
            SPDLOG_ERROR("Invalid storage path: {}", path);
            return false;
        }

        usage = 100.0f * (1.0f - static_cast<float>(space.available) / static_cast<float>(space.capacity));
        return true;
    } catch (const std::exception &e) {
        SPDLOG_ERROR("Failed to get storage info for {}: {}", path, e.what());
        return false;
    }
}

bool SystemInfo::parse_temperature()
{
    std::ifstream temp_file(kSomTempPath);
    if (!temp_file.is_open()) {
        SPDLOG_ERROR("Failed to open {}", kSomTempPath);
        return false;
    }

    int milli_celsius = 0;
    temp_file >> milli_celsius;
    if (temp_file.fail()) {
        SPDLOG_ERROR("Failed to read temperature from {}", kSomTempPath);
        return false;
    }

    temperature = static_cast<float>(milli_celsius) / 1000.0f;
    return true;
}

void SystemInfo::process()
{
    uint64_t idle_time = 0;
    uint64_t total_time = 0;
    if (parse_cpu_stats(idle_time, total_time)) {
        const uint64_t delta_idle = idle_time - prev_idle_time;
        const uint64_t delta_total = total_time - prev_total_time;
        cpu = delta_total == 0 ? 0.0f
                               : (100.0f * static_cast<float>(delta_total - delta_idle)
                                  / static_cast<float>(delta_total));
        high_cpu_usage = cpu >= kHighUsageThreshold;
        prev_idle_time = idle_time;
        prev_total_time = total_time;
    }

    if (parse_memory_info()) {
        high_ram_usage = ram_usage > kHighUsageThreshold;
    }

    if (parse_storage_usage("/", emmc_usage)) {
        high_emmc_usage = emmc_usage > kHighUsageThreshold;
    }

    usb_connected = false;
    usb_storage_usage = 0.0f;
    try {
        for (const auto &entry : std::filesystem::directory_iterator("/mnt")) {
            if (!entry.is_directory()) {
                continue;
            }

            const std::string mount_path = entry.path().string();
            float usage = 0.0f;
            if (parse_storage_usage(mount_path, usage)) {
                usb_connected = true;
                usb_storage_usage = std::max(usb_storage_usage, usage);
            }
        }
    } catch (const std::exception &e) {
        SPDLOG_DEBUG("Skipping USB storage scan in /mnt: {}", e.what());
    }

    parse_temperature();
}

} // namespace
