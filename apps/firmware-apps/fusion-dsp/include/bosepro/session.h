#pragma once

#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/task.h>

#include <spdlog/spdlog.h>

#include <cmath>
#include <list>
#include <memory>


namespace bosepro {


/// A session is a collection of tasks that are run together.  It represents
/// a complete audio processing system.
class Session : public Configurable {
public:
    /// Create a session using the given configuration and parameters.
    /// After this is done, the session is ready for `process()` to be called.
    ///
    /// @param  configuration  The configuration for the session.
    /// @param  parameters  The parameter definitions for the system.
    Session(const SessionConfiguration &configuration,
            const Parameters &parameters)
        : Configurable(configuration)
    {
        SPDLOG_TRACE("Creating session.");
        // This makes the parameters available to all `Configurable` objects.
        set_parameters(parameters);

        frames_to_run = -1;

        for (auto &t : configuration.get_tasks())
        {
            const TaskConfiguration &tc =
                reinterpret_cast<const TaskConfiguration &>(t.second);
            SPDLOG_DEBUG("Creating task: {}", tc.get_name());
            tasks.push_back(std::unique_ptr<Task>(new Task(tc)));
        }
    }


    virtual ~Session() = default;


    /// Process one frame of audio at the highest frame rate of the session.
    /// The might be called in a callback from the system's audio drivers, or
    /// in a loop for file processing.
    virtual void process() override
    {
        for (auto &task : tasks)
        {
            task->process();
        }

        if (frames_to_run > 0)
        {
            frames_to_run--;
        }
    }


    /// Set the number of frames that the session is to run before finishing.
    /// The progress of this duration can be checked using `finished_running()`.
    ///
    /// @param  seconds  The duration in seconds to run.
    void set_seconds_to_run(double seconds)
    {
        frames_to_run =
            std::ceil(seconds * get_sample_rate() / get_frame_size());
    }


    /// Test whether the session has finished running, in the case where a
    /// duration has been set using `set_seconds_to_run()`.  If the duration
    /// has not been set, this always returns `true`.
    ///
    /// @return  `true` if the session has finished running.
    bool finished_running()
    {
        return frames_to_run == 0;
    }


private:
    int_fast32_t frames_to_run;
    std::list<std::unique_ptr<Task>> tasks;
};


} // namespace bosepro
