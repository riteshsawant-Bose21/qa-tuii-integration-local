#include <bosepro/periodic_task.h>

#include <bosepro/module.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>

#include <spdlog/spdlog.h>

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

PeriodicTask::PeriodicTask(const TaskConfiguration &configuration)
    : Configurable(configuration), task_name(configuration.get_name()),
      period_ms(0), period_ns(0), stop_flag(false)
{
    // Use this task's region manager while allocating blocks within the task.
    region_manager.open_region();

    if (configuration.has_property("period_ms"))
    {
        configuration.get_property("period_ms").get_value(period_ms);
    }

    SPDLOG_DEBUG("Periodic task {} has period {}ms", configuration.get_name(), period_ms);
    period_ns = period_ms == 0 ? 0 : static_cast<uint64_t>(period_ms) * 1'000'000ULL; // Convert ms to nanoseconds

    // Create all of the blocks in the task.
    for (auto &b : configuration.get_blocks())
    {
        const BlockConfiguration *bc =
            reinterpret_cast<const BlockConfiguration *>(&b.second);

        blocks.push_back(std::unique_ptr<Module>(
                    ChildFactory<Module, const BlockConfiguration &>::create_child(
                        bc->get_module(), *bc)));
        block_map[bc->get_name()] = blocks.back().get();
    }

    region_manager.close_region();
}


PeriodicTask::~PeriodicTask()
{
    stop();
}


void PeriodicTask::process()
{
    for (auto &block : blocks)
    {
        block->process();
    }
}


Module *PeriodicTask::get_block(const std::string &name)
{
    if (block_map.count(name) != 0)
    {
        return block_map[name];
    }
    else
    {
        return nullptr;
    }
}


int_fast32_t PeriodicTask::get_cpu_affinity()
{
    return cpu_affinity;
}


int_fast32_t PeriodicTask::get_period_ms()
{
    return period_ms;
}

void PeriodicTask::start()
{
    if (period_ns)
    {
        task_thread = std::thread(&PeriodicTask::run, this);
    }
}

void PeriodicTask::stop()
{
    stop_flag = true;

    if (task_thread.joinable()) {
        task_thread.join();
    }
}

void PeriodicTask::run()
{
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

    while (!stop_flag)
    {
        // Execute the task function
        process();

        // Calculate the next execution time
        next_execution_time += std::chrono::nanoseconds(period_ns);

        // Sleep until the next execution time
        std::this_thread::sleep_until(next_execution_time);
    }

    SPDLOG_INFO("Stopping PeriodicTask periodic thread.");
}


}
