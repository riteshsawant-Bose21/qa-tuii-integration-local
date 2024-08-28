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
            create_task(tc);
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
            task.second->process();
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


    /// Create a task given a task configuration.  This will also start the
    /// task.
    ///
    /// @param   task_configuration  The configuration for the task.
    void create_task(const TaskConfiguration &task_configuration)
    {
        const std::string task_name = task_configuration.get_name();

        if (tasks.count(task_name) != 0)
        {
            SPDLOG_CRITICAL("Duplicate tasks with name {}.", task_name);
            return;
        }

        tasks[task_name] = std::unique_ptr<Task>(new Task(task_configuration));
    }


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_task(const std::string &task_name)
    {
        if (tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        tasks.erase(task_name);
    }


    /// Start an existing task with the given name.
    ///
    /// @param  task_name  The name of the task to start.
    void start_task(const std::string &task_name)
    {
        if (tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        tasks[task_name]->start();
    }


    /// Stop an existing task with the given name.  The task will remain
    /// available to run again using `start_tas()`.
    ///
    /// @param  task_name  The name of the task to stop.
    void stop_task(const std::string &task_name)
    {
        if (tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        tasks[task_name]->stop();
    }


    /// Start all of the tasks in the session.
    void start()
    {
        SPDLOG_INFO("Starting session.");
        for (auto &task : tasks)
        {
            task.second->start();
        }
    }


    /// Stop all of the tasks in the session.
    void stop()
    {
        SPDLOG_INFO("Stopping session.");
        for (auto &task : tasks)
        {
            task.second->stop();
        }
    }


    /// Process the provided command.
    ///
    /// @param  command  The command to process.
    void process_command(const Command &command)
    {
        // TODO - we really need a better way to manage the different session
        // commands.
        if (command.get_target() == "session")
        {
            if (command.get_name() == "stop")
            {
                stop();
            }
            else if (command.get_name() == "destroy_task")
            {
                std::string task_name;
                command.get_value(task_name);
                destroy_task(task_name);
            }
            else if (command.get_name() == "create_task")
            {
                std::string filename;
                command.get_value(filename);

                bosepro::Configuration configuration(filename);
                for (auto &t : configuration.get_session().get_tasks())
                {
                    const TaskConfiguration &tc =
                        reinterpret_cast<const TaskConfiguration &>(t.second);
                    create_task(tc);
                }
            }
            else if (command.get_name() == "start_task")
            {
                std::string task_name;
                command.get_value(task_name);
                start_task(task_name);
            }
            else if (command.get_name() == "stop_task")
            {
                std::string task_name;
                command.get_value(task_name);
                stop_task(task_name);
            }
        }
        else
        {
            for (auto &task : tasks)
            {
                std::string block_name;
                Algorithm *block = task.second->get_block(command.get_target());
                if (block != nullptr)
                {
                    block->set_control((const ControlSetting &)command);
                    break;
                }
            }
        }
    }

private:
    int_fast32_t frames_to_run;
    std::map<std::string, std::unique_ptr<Task>> tasks;
};


} // namespace bosepro
