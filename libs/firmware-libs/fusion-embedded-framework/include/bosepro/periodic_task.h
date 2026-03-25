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
    PeriodicTask(const TaskConfiguration &configuration);


    virtual ~PeriodicTask();


    /// Run process() on all of the blocks in this non-audio task.
    virtual void process() override;


    /// Get a pointer to a module block with the given name.
    Module *get_block(const std::string &name);


    /// Get the CPU affinity to be used for this non-audio task.
    int_fast32_t get_cpu_affinity();


    /// Get the period in milliseconds for this non-audio task.
    int_fast32_t get_period_ms();


    void start();


    void stop();


private:
    /// The function that runs the task thread. It executes the task function at the specified frequency.
    void run();

    RegionManager region_manager;

    std::list<std::unique_ptr<Module>> blocks; // List of blocks for processing
    std::map<std::string, Module *> block_map; // Map of block names to Module pointers

    std::string task_name;
    int_fast32_t cpu_affinity; // CPU affinity for the task
    int_fast32_t period_ms;    // Period in milliseconds
    uint64_t period_ns;    // Period in nanoseconds
    std::atomic<bool> stop_flag;

    std::thread task_thread;       // Periodic task thread
};

}
