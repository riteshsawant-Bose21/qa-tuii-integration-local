#pragma once

#include <bosepro/algorithm.h>
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
class AudioSubtask {
public:
    /// Create a new periodic task.
    ///
    /// @param  run_function  The function to run in the task thread.
    /// @param  obj  The object to pass to the run function.
    /// @param  period  The period of the task, relative to the base frame rate
    ///                 of the system.
    AudioSubtask(void (*run_function)(void *), void *obj,
                 int_fast32_t sample_rate, int_fast32_t frame_size,
                 int_fast32_t base_frame_size);


    virtual ~AudioSubtask();


    /// Set the real-time priority of the task (between 0 and 99).  If this is
    /// not called, the task will not be a real-time task.
    ///
    /// @param priority The real-time priority of the task.
    void set_priority(int priority);


    /// Increment the task tick count, indicating one frame at the base frame
    /// rate has passed.  This will wake the task according to its period.
    inline void tick()
    {
        pthread_mutex_lock(&ticks_mutex);
        ticks++;

        if (ticks >= 2 * period)
        {
            SPDLOG_WARN("Audio SubTask {} is running behind: {}, {}", task_id, ticks, period);
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
    static void *run(void *p_task);


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
class AudioTask : public Configurable {
public:
    /// Create a task from a configuration.
    ///
    /// @param  configuration  The configuration for the task.
    AudioTask(const TaskConfiguration &configuration);


    virtual ~AudioTask();


    /// Run one frame of audio through all of the blocks in this task.
    virtual void process() override;

    /// Get a pointer to a signal processing block with the given name.
    ///
    /// @param  name  The name of the block.
    /// @return  A pointer to the block.
    Algorithm *get_block(const std::string &name);


    /// Start this task after it has been stopped with `stop()`.
    void start();


    /// Stop running the task without destroying it.  It can be started again
    /// with `start()`.
    void stop();


    /// Check whether a task has completed running, if it was set up to run for
    /// only a certain amount of time with `set_seconds_to_run()`.
    ///
    /// @return  `true` if the task has finished running.
    bool finished_running();


    /// Set the number of seconds to run this task, after which it will stop
    /// processing.
    ///
    /// @param  seconds  The number of seconds to run the task.
    void set_seconds_to_run(double seconds);


    /// Get the CPU affinity to be used for this task.
    ///
    /// @return  The CPU affinity configured for this task.
    int_fast32_t get_cpu_affinity();


private:
    RegionManager region_manager;
    Profile task_profile;
    // A list of blocks, for quickly processing in order.
    std::list<std::unique_ptr<Algorithm>> blocks;
    std::vector<Profile> block_profile;
    std::vector<double> block_timings;
    // A map of blocks, for accessing parameters.
    std::map<std::string, Algorithm *> block_map;
    bool profile_blocks = false;
    int_fast32_t cpu_affinity;
    DspSignalMemory<const float []> empty_signal;

    JackClient *client;
    int_fast32_t frames_to_run;
    std::ofstream log_file;
};


} // namespace bosepro
