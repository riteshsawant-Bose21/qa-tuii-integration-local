#pragma once

#include <bosepro/algorithm.h>
#include <bosepro/module.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/jack.h>
#include <bosepro/profile.h>

#include <pthread.h>
#include <spdlog/spdlog.h>

#ifdef USE_MAC_THREADS
#include <mach/thread_policy.h>
#include <mach/thread_act.h>
#include <CoreAudio/HostTime.h>
#endif

#include <cstdint>
#include <cstring>
#include <list>
#include <map>
#include <memory>
#include <string>
#include <vector>


namespace bosepro {


/// A periodic real-time task that runs in a separate thread.
class PeriodicTask {
public:
    /// Create a new periodic task.
    ///
    /// @param  run_function  The function to run in the task thread.
    /// @param  obj  The object to pass to the run function.
    /// @param  period  The period of the task, relative to the base frame rate
    ///                 of the system.
    PeriodicTask(void (*run_function)(void *), void *obj,
                 int_fast32_t sample_rate, int_fast32_t frame_size,
                 int_fast32_t base_frame_size)
        : run_function(run_function), obj(obj), sample_rate(sample_rate),
          frame_size(frame_size), ticks(0)
    {
        int err;
        pthread_mutexattr_t attr;

        if (frame_size % base_frame_size != 0)
        {
            SPDLOG_CRITICAL("frame_size ({}) must be a multiple of "
                            "base_frame_size ({})",
                            frame_size, base_frame_size);
        }

        period = frame_size / base_frame_size;

        err = pthread_create(&thread, NULL, run, this);

        if (err != 0)
        {
            SPDLOG_CRITICAL("pthread_create() failed: {}", strerror(err));
        }


        err = pthread_mutexattr_init(&attr);

        if (err != 0)
        {
            SPDLOG_CRITICAL("pthread_mutexattr_init() failed: {}",
                            strerror(err));
        }


        err = pthread_mutexattr_setprotocol(&attr, PTHREAD_PRIO_INHERIT);

        if (err != 0)
        {
            SPDLOG_CRITICAL("pthread_mutexattr_setprotocol() failed: {}",
                            strerror(err));
        }


        err = pthread_mutex_init(&ticks_mutex, &attr);

        if (err != 0)
        {
            SPDLOG_CRITICAL("pthread_mutex_init() failed: {}", strerror(err));
        }


        err = pthread_cond_init(&ticks_cond, NULL);

        if (err != 0)
        {
            SPDLOG_CRITICAL("pthread_cond_init() failed: {}", strerror(err));
        }

        profile.set_period((double)frame_size / sample_rate);

        task_id = task_count++;
    }


    virtual ~PeriodicTask()
    {
        SPDLOG_DEBUG("Task {} MIPS: {} first, {} max, {} avg.",
                     task_id,
                     profile.get_first_mips(),
                     profile.get_max_mips(),
                     profile.get_average_mips());
    }


    /// Set the real-time priority of the task (between 0 and 99).  If this is
    /// not called, the task will not be a real-time task.
    ///
    /// @param priority The real-time priority of the task.
    void set_priority(int priority)
    {
#ifdef USE_MAC_THREADS
        // In macOS, the pthread real-time scheduler doesn't have actual
        // real-time priority (but allows you to set real-time priority without
        // complaint).  Instead, we need to use the native macOS threads to
        // set priority.

        thread_time_constraint_policy_data_t policy;

        double frame_period_ns = frame_size * 1.0e9 / sample_rate;
        policy.period = AudioConvertNanosToHostTime(frame_period_ns);
        // thread_policy_set() doesn't like constraints more than 100ms
        frame_period_ns = (frame_period_ns > 1.0e8) ? 1.0e8 : frame_period_ns;
        policy.computation = AudioConvertNanosToHostTime(frame_period_ns / 2);
        policy.constraint = AudioConvertNanosToHostTime(frame_period_ns);
        policy.preemptible = 1;

        kern_return_t result = thread_policy_set(pthread_mach_thread_np(thread),
                                                 THREAD_TIME_CONSTRAINT_POLICY,
            (thread_policy_t)&policy, THREAD_TIME_CONSTRAINT_POLICY_COUNT);

        if (result != KERN_SUCCESS)
        {
            SPDLOG_ERROR("Failed to set task priority {}", priority);
        }
#else
        int err;
        struct sched_param sched_param;

        sched_param.sched_priority = priority;

        err = pthread_setschedparam(thread, SCHED_FIFO, &sched_param);

        if (err != 0)
        {
            SPDLOG_ERROR("Failed to set task priority: {}", strerror(err));
        }
#endif
    }


    /// Increment the task tick count, indicating one frame at the base frame
    /// rate has passed.  This will wake the task according to its period.
    void tick()
    {
        pthread_mutex_lock(&ticks_mutex);
        ticks++;

        if (ticks >= 2 * period)
        {
            SPDLOG_WARN("Periodic task {} is running behind: {}, {}", task_id, ticks, period);
            ticks = 1;
        }

        if (ticks >= period)
        {
            pthread_cond_signal(&ticks_cond);
        }

        pthread_mutex_unlock(&ticks_mutex);
    }


private:
    /// The function that runs the task thread.  It runs the task function
    /// once per period, then waits for the next period to elapse.
    ///
    /// @param p_task A pointer to the task object.
    static void *run(void *p_task)
    {
        PeriodicTask *task = (PeriodicTask *)p_task;
        while (true)
        {
            pthread_mutex_lock(&task->ticks_mutex);
            while (task->ticks < task->period)
            {
                pthread_cond_wait(&task->ticks_cond, &task->ticks_mutex);
            }
            task->ticks -= task->period;
            pthread_mutex_unlock(&task->ticks_mutex);
            task->profile.start();
            task->run_function(task->obj);
            task->profile.finish();
        }
    }


    static int task_count;
    int task_id;
    pthread_t thread;
    pthread_mutex_t ticks_mutex;
    pthread_cond_t ticks_cond;
    void (*run_function)(void *);
    void *obj;
    int_fast32_t sample_rate;
    int_fast32_t frame_size;
    int_fast32_t period;
    int_fast32_t ticks;
    Profile profile;
};


/// A real-time audio processing task, which runs a collection of blocks that
/// all have the same frame rate.
class Task : public Configurable {
public:
    /// Create a task from a configuration.
    ///
    /// @param  configuration  The configuration for the task.
    Task(const TaskConfiguration &configuration)
        : Configurable(configuration), client(nullptr)
    {
        // Use this task's region manager while allocating blocks within the
        // task.
        region_manager.open_region();

        frames_to_run = -1;

        if (configuration.has_property("jack_client_name") > 0)
        {
            std::string client_name;
            configuration.get_property("jack_client_name").get_value(client_name);
            client = Jack::create_client(client_name, this);
        }

        if (configuration.has_property("cpu_affinity") > 0)
        {
            configuration.get_property("cpu_affinity").get_value(cpu_affinity);
        }

        // Create all of the blocks in the task.
        for (auto &b : configuration.get_blocks())
        {
            const BlockConfiguration *bc =
                reinterpret_cast<const BlockConfiguration *>(&b.second);

            SPDLOG_DEBUG("Creating block: {}.", bc->get_name());

            blocks.push_back(std::unique_ptr<Algorithm>(
                ChildFactory<Algorithm,
                     const BlockConfiguration &>::create_child(
                         bc->get_algorithm(), *bc)));
            block_map[bc->get_name()] = blocks.back().get();
        }

        for (auto &b : blocks)
        {
            b->initialize_terminals();
            b->initialize_parameters();
        }

        for (auto &c : configuration.get_block_connections())
        {
            const ConnectionConfiguration *cc =
                reinterpret_cast<const ConnectionConfiguration *>(&c.second);
            Algorithm *input_block = block_map[cc->get_destination_block()];
            Algorithm *ouput_block = block_map[cc->get_source_block()];
            Terminal &output_terminal =
                ouput_block->get_terminal(cc->get_output_terminal());
            int output_channel = cc->get_output_channel();
            int input_channel = cc->get_input_channel();

            SPDLOG_TRACE("Connecting {}:{}:{} -> {}:{}:{}.",
                    cc->get_source_block(), cc->get_output_terminal(),
                    cc->get_output_channel(), cc->get_destination_block(),
                    cc->get_input_terminal(), cc->get_input_channel());

            input_block->connect_terminal(cc->get_input_terminal(),
                    input_channel, output_terminal,
                    output_channel);
        }

        if (configuration.has_property("profile_blocks") > 0)
        {
            configuration.get_property("profile_blocks").get_value(profile_blocks);
        }

        block_profile.resize(blocks.size());

        task_profile.set_period((double)get_frame_size() / get_sample_rate());

        for (auto &bp : block_profile)
        {
            bp.set_period((double)get_frame_size() / get_sample_rate());
        }

        region_manager.close_region();
    }


    virtual ~Task()
    {
        frames_to_run = 0;

        if (client != nullptr)
        {
            client->stop();
            Jack::destroy_client(client->get_name());
        }

        // Use this task's region manager while destroying blocks within this
        // task (will occur after this destructor exits, when `blocks` is
        // destroyed).  The region will be closed when `region_manager` is
        // destroyed.
        region_manager.open_region();

        SPDLOG_DEBUG("Task MIPS: {} first, {} max, {} avg.",
                     task_profile.get_first_mips(),
                     task_profile.get_max_mips(),
                     task_profile.get_average_mips());

        if (profile_blocks)
        {
            int block_index = 0;
            for (auto &block : blocks)
            {
                SPDLOG_DEBUG("Block MIPS, {} ({}): {} first, {} max, {} avg.",
                             block->get_block_name(),
                             block->get_algorithm_name(),
                             block_profile[block_index].get_first_mips(),
                             block_profile[block_index].get_max_mips(),
                             block_profile[block_index].get_average_mips());
                block_index++;
            }
        }
    }


    /// Run one frame of audio through all of the blocks in this task.
    virtual void process() override
    {
        task_profile.start();

        if (!profile_blocks)
        {
            for (auto &block : blocks)
            {
                block->process();
                block->process_outputs();
            }
        }
        else
        {
            int block_index = 0;
            for (auto &block : blocks)
            {
                block_profile[block_index].start();
                block->process();
                block->process_outputs();
                block_profile[block_index++].finish();
            }
        }

        if (frames_to_run > 0)
        {
            frames_to_run--;
        }

        task_profile.finish();
    }


    /// Get a pointer to a signal processing block with the given name.
    ///
    /// @param  name  The name of the block.
    /// @return  A pointer to the block.
    Algorithm *get_block(const std::string &name)
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


    /// Start this task after it has been stopped with `stop()`.
    void start()
    {
        if (client != nullptr)
        {
            client->start();
        }
        else
        {
            SPDLOG_ERROR("No JACK client associated with this task.");
        }
    }


    /// Stop running the task without destroying it.  It can be started again
    /// with `start()`.
    void stop()
    {
        if (client != nullptr)
        {
            client->stop();
        }
        else
        {
            SPDLOG_ERROR("No JACK client associated with this task.");
        }
    }


    /// Check whether a task has completed running, if it was set up to run for
    /// only a certain amount of time with `set_seconds_to_run()`.
    ///
    /// @return  `true` if the task has finished running.
    bool finished_running()
    {
        return frames_to_run == 0;
    }


    /// Set the number of seconds to run this task, after which it will stop
    /// processing.
    ///
    /// @param  seconds  The number of seconds to run the task.
    void set_seconds_to_run(double seconds)
    {
        frames_to_run =
            std::ceil(seconds * get_sample_rate() / get_frame_size());
    }


    /// Get the CPU affinity to be used for this task.
    ///
    /// @return  The CPU affinity configured for this task.
    int_fast32_t get_cpu_affinity()
    {
        return cpu_affinity;
    }


private:
    RegionManager region_manager;
    Profile task_profile;
    // A list of blocks, for quickly processing in order.
    std::list<std::unique_ptr<Algorithm>> blocks;
    std::vector<Profile> block_profile;
    // A map of blocks, for accessing parameters.
    std::map<std::string, Algorithm *> block_map;
    bool profile_blocks = false;
    int_fast32_t cpu_affinity;

    JackClient *client;
    int_fast32_t frames_to_run;
};


/// A non-real-time non-audio processing task, which starts a periodic task thread
/// that runs a collection of blocks
class NaTask : public Configurable {
public:
    /// Create a task from a configuration.
    ///
    /// @param  configuration  The configuration for the task.
    NaTask(const TaskConfiguration &configuration)
        : Configurable(configuration),
        period_ms(0), period_ns(0)
    {
        // Use this task's region manager while allocating blocks within the
        // task.
        region_manager.open_region();

        if (configuration.has_property("cpu_affinity") > 0)
        {
            configuration.get_property("cpu_affinity").get_value(cpu_affinity);
        }

        if (configuration.has_property("period_ms") > 0)
        {
            configuration.get_property("period_ms").get_value(period_ms);
        }

        period_ns = period_ms == 0 ? 0 : period_ms * 1'000'000; // Convert ms to nanoseconds

        // Create all of the blocks in the task.
        for (auto &b : configuration.get_blocks())
        {
            SPDLOG_DEBUG("Creating blocks");
            const BlockConfiguration *bc =
                reinterpret_cast<const BlockConfiguration *>(&b.second);

            SPDLOG_DEBUG("Creating block: {}.", bc->get_name());

            blocks.push_back(std::unique_ptr<Module>(
                ChildFactory<Module,
                     const BlockConfiguration &>::create_child(
                         bc->get_module(), *bc)));
            block_map[bc->get_name()] = blocks.back().get();
        }

        for (auto &b : blocks)
        {
            b->initialize_parameters();
        }

        region_manager.close_region();
    }


    virtual ~NaTask()
    {
        // Stop the thread if it's running
        stop();

        // Use this task's region manager while destroying blocks within this
        // task (will occur after this destructor exits, when `blocks` is
        // destroyed). The region will be closed when `region_manager` is
        // destroyed.
        region_manager.open_region();
    }


    /// Run process() on all of the blocks in this non-audio task.
    ///
    virtual void process() override
    {
        for (auto &block : blocks)
        {
            block->process();
        }
    }


    /// Get a pointer to a module block with the given name.
    ///
    /// @param  name  The name of the block.
    /// @return  A pointer to the block.
    Module *get_block(const std::string &name)
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


    /// Get the CPU affinity to be used for this non-audio task.
    ///
    /// @return  The CPU affinity configured for this task.
    int_fast32_t get_cpu_affinity()
    {
        return cpu_affinity;
    }


    /// Get the period in milliseconds for this non-audio task.
    ///
    /// @return  The period in milliseconds configured for this task.
    int_fast32_t get_period_ms()
    {
        return period_ms;
    }


    /// Set the real-time priority of the task (between 0 and 99).
    /// If this is not called, the task will not be a real-time task.
    void set_priority(int priority)
    {
#ifdef USE_MAC_THREADS
        // Mac-specific thread priority setting
#else
        struct sched_param sched_param;
        sched_param.sched_priority = priority;

        int err = pthread_setschedparam(thread, SCHED_FIFO, &sched_param);
        if (err != 0) {
            SPDLOG_ERROR("Failed to set task priority: {}", strerror(err));
        }
#endif
    }


    void start()
    {
        // we only start the periodic thread if there's a period
        if (period_ns)
        {
            int err = pthread_create(&thread, nullptr, thread_entry_point, this);
            if (err != 0) {
                SPDLOG_CRITICAL("pthread_create() failed: {}", strerror(err));
            }
        }
    }


    void stop()
    {
        if (thread != 0) {
            pthread_cancel(thread);
            pthread_join(thread, nullptr);
            thread = 0;
        }
    }


private:
    /// The static function that serves as the entry point for the thread.
    static void* thread_entry_point(void* arg)
    {
        NaTask* task = static_cast<NaTask*>(arg);
        return task->run();
    }

    /// The function that runs the task thread. It executes the task function
    /// at the specified frequency.
    void* run()
    {
        auto next_execution_time = std::chrono::steady_clock::now();

        while (true) {
            // Execute the task function
            process();

            // Calculate the next execution time
            next_execution_time += std::chrono::nanoseconds(period_ns);

            // Sleep until the next execution time
            std::this_thread::sleep_until(next_execution_time);

            // Check for cancellation
            pthread_testcancel();
        }

        return nullptr; // Not reached
    }


    RegionManager region_manager;

    // A list of blocks, for quickly processing in order.
    std::list<std::unique_ptr<Module>> blocks;
    // A map of blocks, for accessing parameters
    std::map<std::string, Module *> block_map;

    int_fast32_t cpu_affinity;
    int_fast32_t period_ms;
    int_fast32_t period_ns;

    pthread_t thread;
};


} // namespace bosepro
