#include <bosepro/module.h>
#include <bosepro/periodic_task.h>
#include <cstdint>
#include <sstream>
#include <string>
#include <vector>
#include <filesystem>
#include <fstream>
#include <algorithm>

namespace {

class SpaceUsage : public bosepro::Module
{
public:
    SpaceUsage(const bosepro::BlockConfiguration &configuration);
    virtual ~SpaceUsage() = default;

    virtual void process();

private:
    // RAM usage
    float ram_usage;
    bool high_ram_usage;

    // eMMC storage
    float emmc_usage;
    bool high_emmc_usage;

    // USB storage
    float usb_storage_usage;
    bool usb_connected;

    // Helper methods
    bool parse_memory_info();
    bool parse_storage_usage(const std::string &path, float &usage);

    MODULE_DECLARE(SpaceUsage);
};

MODULE_REGISTER(SpaceUsage, "space_usage");

SpaceUsage::SpaceUsage(const bosepro::BlockConfiguration &configuration)
    : bosepro::Module(configuration),
      ram_usage(0.0f), high_ram_usage(false),
      emmc_usage(0.0f), high_emmc_usage(false),
      usb_storage_usage(0.0f), usb_connected(false)
{
    assign_telemetry("ram", &ram_usage);
    assign_telemetry("high_ram_usage", &high_ram_usage);
    assign_telemetry("emmc", &emmc_usage);
    assign_telemetry("high_emmc_usage", &high_emmc_usage);
    assign_telemetry("usb_storage", &usb_storage_usage);
    assign_telemetry("usb_connected", &usb_connected);
}

bool SpaceUsage::parse_memory_info()
{
    std::ifstream meminfo_file("/proc/meminfo");
    if (!meminfo_file.is_open()) {
        SPDLOG_ERROR("Failed to open /proc/meminfo");
        return false;
    }

    std::string line;
    uint64_t mem_total = 0, mem_available = 0;

    while (std::getline(meminfo_file, line)) {
        std::istringstream iss(line);
        std::string key;
        uint64_t value;
        std::string unit;

        iss >> key >> value >> unit;

        if (key == "MemTotal:") {
            mem_total = value; // in KB
        } else if (key == "MemAvailable:") {
            mem_available = value; // in KB
        }

        if (mem_total && mem_available) {
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

bool SpaceUsage::parse_storage_usage(const std::string &path, float &usage)
{
    try {
        std::filesystem::space_info space = std::filesystem::space(path);

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

void SpaceUsage::process()
{
    // RAM usage
    if (!parse_memory_info()) {
        SPDLOG_ERROR("Failed to parse memory info");
    } else {
        high_ram_usage = ram_usage > 80.0f;
    }

    // eMMC storage usage
    if (!parse_storage_usage("/", emmc_usage)) {
        SPDLOG_ERROR("Failed to parse eMMC usage");
    } else {
        high_emmc_usage = emmc_usage > 80.0f;
    }

    // USB storage usage
    usb_connected = false;
    usb_storage_usage = 0.0f;

    for (const auto &entry : std::filesystem::directory_iterator("/mnt")) {
        if (entry.is_directory()) {
            std::string mount_path = entry.path();
            SPDLOG_DEBUG("Checking USB storage at {}", mount_path);

            float usage = 0.0f;
            if (parse_storage_usage(mount_path, usage)) {
                usb_connected = true;
                usb_storage_usage = std::max(usb_storage_usage, usage);
            }
        }
    }
}

} // namespace
