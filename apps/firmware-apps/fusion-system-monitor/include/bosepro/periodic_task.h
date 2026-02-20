#include <bosepro/module.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>

#include "spdlog/spdlog.h"

#include <thread>
#include <atomic>
#include <chrono>
#include <list>
#include <map>
#include <memory>
#include <string>

#ifdef __linux__
#include <pthread.h>
#endif

namespace bosepro {

class PeriodicTask : public Configurable {
public:
    /// Create a task from a configuration.
    ///
    /// @param  configuration  The configuration for the task.
    PeriodicTask(const TaskConfiguration &configuration)
        : Configurable(configuration),
          task_name(configuration.get_name()),
          period_ms(0),
          period_ns(0),
          stop_flag(false)
    {
        // Use this task's region manager while allocating blocks within the task.
        region_manager.open_region();

        if (configuration.has_property("period_ms")) {
            configuration.get_property("period_ms").get_value(period_ms);
        }

        SPDLOG_DEBUG("Periodic task {} has period {}ms", configuration.get_name(), period_ms);
        period_ns = period_ms == 0 ? 0 : static_cast<uint64_t>(period_ms) * 1'000'000ULL; // Convert ms to nanoseconds

        // Create all of the blocks in the task.
        for (auto &b : configuration.get_blocks()) {
            const BlockConfiguration *bc =
                reinterpret_cast<const BlockConfiguration *>(&b.second);

            blocks.push_back(std::unique_ptr<Module>(
                ChildFactory<Module, const BlockConfiguration &>::create_child(
                    bc->get_module(), *bc)));
            block_map[bc->get_name()] = blocks.back().get();
        }

        region_manager.close_region();
    }

    virtual ~PeriodicTask() {
        stop();
    }

    /// Run process() on all of the blocks in this non-audio task.
    virtual void process() override {
        for (auto &block : blocks) {
            block->process();
        }
    }

    /// Get a pointer to a module block with the given name.
    Module *get_block(const std::string &name) {
        if (block_map.count(name) != 0) {
            return block_map[name];
        } else {
            return nullptr;
        }
    }

    /// Get the CPU affinity to be used for this non-audio task.
    int_fast32_t get_cpu_affinity() {
        return cpu_affinity;
    }

    /// Get the period in milliseconds for this non-audio task.
    int_fast32_t get_period_ms() {
        return period_ms;
    }

    void start() {
        if (period_ns) {
            task_thread = std::thread(&PeriodicTask::run, this);
        }
    }

    void stop() {
        stop_flag = true;

        if (task_thread.joinable()) {
            task_thread.join();
        }
    }

private:
    /// The function that runs the task thread. It executes the task function at the specified frequency.
    void run() {
#ifdef __linux__
        // pthread names are limited to 16 bytes including the null terminator.
        constexpr size_t kMaxPthreadNameLen = 15;
        std::string name = task_name;
        if (name.size() > kMaxPthreadNameLen) {
            name.resize(kMaxPthreadNameLen);
        }
        pthread_setname_np(pthread_self(), name.c_str());
#endif
        auto next_execution_time = std::chrono::steady_clock::now();

        while (!stop_flag) {
            // Execute the task function
            process();

            // Calculate the next execution time
            next_execution_time += std::chrono::nanoseconds(period_ns);

            // Sleep until the next execution time
            std::this_thread::sleep_until(next_execution_time);
        }

        SPDLOG_INFO("Stopping PeriodicTask periodic thread.");
    }

    RegionManager region_manager;

    std::list<std::unique_ptr<Module>> blocks; // List of blocks for processing
    std::map<std::string, Module *> block_map; // Map of block names to Module pointers

    std::string task_name;
    int_fast32_t cpu_affinity; // CPU affinity for the task
    uint32_t period_ms;    // Period in milliseconds
    uint64_t period_ns;    // Period in nanoseconds
    std::atomic<bool> stop_flag;

    std::thread task_thread;       // Periodic task thread
};

}
