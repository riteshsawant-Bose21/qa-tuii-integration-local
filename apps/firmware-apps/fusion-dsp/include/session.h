#pragma once

#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/parameters.h>
#include <bosepro/task.h>

#include <spdlog/spdlog.h>

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
    }


private:
    std::list<std::unique_ptr<Task>> tasks;
};


} // namespace bosepro
