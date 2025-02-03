#pragma once

#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
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
    /// Create a session using the given configuration and definitions.
    /// After this is done, the session is ready for `process()` to be called.
    ///
    /// @param  configuration  The configuration for the session.
    /// @param  definitions  The algorithm definitions for the system.
    Session(const SessionConfiguration &configuration,
            const Definition &definitions)
        : Configurable(configuration), meter_callback(nullptr)
    {
        SPDLOG_TRACE("Creating session.");
        // This makes the definitions available to all `Configurable` objects.
        set_definitions(definitions);

        frames_to_run = -1;
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


    void create_tasks(const Configuration &configuration)
    {
        for (auto &t : configuration.get_tasks())
        {
            const TaskConfiguration &tc =
                reinterpret_cast<const TaskConfiguration &>(t.second);
            create_task(tc);
        }
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


    /// Destroy all tasks in the session.  This will stop each task before
    /// destroying it.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_all_tasks()
    {
        tasks.clear();
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
    /// available to run again using `start_task()`.
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

    /// Get a pointer to a signal processing block with the given name.
    ///
    /// @param  name  The name of the block.
    /// @return  A pointer to the block.
    Task *get_task(const std::string &name)
    {
        if (tasks.count(name) != 0)
        {
            return tasks[name].get();
        }
        else
        {
            return nullptr;
        }
    }


    /// Process the list of task connections specified in a configuration,
    /// connecting JACK input and output ports accordingly.
    ///
    /// @param  configuration  A list of task connections from the
    ///                        configuration.
    void connect_tasks(const TaskConnectionConfiguration &configuration)
    {
        Task *source_task = get_task(configuration.get_source_task());
        Task *destination_task = get_task(configuration.get_destination_task());

        // Either the source_task or destination_task names may not correspond
        // to DSP tasks, because they may be specifying a connection to the
        // system or an external JACK client.  In the case the connection is
        // made between two DSP tasks, we set the connection in both tasks in
        // case one of them needs to be stopped and restarted.

        if (source_task != nullptr)
        {
            Jack *output_block =
                dynamic_cast<Jack *>(source_task->get_block(configuration.get_output_block()));

            if (output_block != nullptr)
            {
                std::string connection = configuration.get_destination_task()
                    + ":" + configuration.get_input_block() + "_"
                    + std::to_string(configuration.get_input_channel() + 1);

                output_block->connect_port(configuration.get_output_channel(),
                                           connection);
            }
            else
            {
                SPDLOG_ERROR("Nonexistent output block {} for task connection.",
                             configuration.get_output_block());
            }
        }

        if (destination_task != nullptr)
        {
            Jack *input_block =
                dynamic_cast<Jack *>(destination_task->get_block(configuration.get_input_block()));

            if (input_block != nullptr)
            {
                std::string connection = configuration.get_source_task()
                    + ":" + configuration.get_output_block() + "_"
                    + std::to_string(configuration.get_output_channel() + 1);

                input_block->connect_port(configuration.get_input_channel(),
                                          connection);
            }
            else
            {
                SPDLOG_ERROR("Nonexistent input block {} for task connection.",
                             configuration.get_input_block());
            }
        }

        if (source_task == nullptr && destination_task == nullptr)
        {
            SPDLOG_ERROR("Nonexistent tasks {} and {} for task connection.",
                         configuration.get_source_task(),
                         configuration.get_destination_task());
        }
    }


    /// Process the provided command.
    ///
    /// @param  command  The command to process.
    void process_parameter_setting(const ParameterSetting &setting)
    {
        // TODO - we really need a better way to manage the different session
        // commands.
        if (setting.get_target() == "session")
        {
            if (setting.get_name() == "send_meters")
            {
                if (meter_callback != nullptr)
                {
                    for (auto &task : tasks)
                    {
                        task.second->send_meters(meter_callback);
                    }
                }
            }
            else if (setting.get_name() == "stop")
            {
                stop();
            }
            else if (setting.get_name() == "destroy_task")
            {
                std::string task_name;
                setting.get_value(task_name);
                destroy_task(task_name);
            }
            else if (setting.get_name() == "destroy_all_tasks")
            {
                destroy_all_tasks();
            }
            else if (setting.get_name() == "create_task")
            {
                std::string filename;
                setting.get_value(filename);

                bosepro::Configuration configuration(filename);
                for (auto &t : configuration.get_tasks())
                {
                    const TaskConfiguration &tc =
                        reinterpret_cast<const TaskConfiguration &>(t.second);
                    create_task(tc);
                }
            }
            else if (setting.get_name() == "start_task")
            {
                std::string task_name;
                setting.get_value(task_name);
                start_task(task_name);
            }
            else if (setting.get_name() == "stop_task")
            {
                std::string task_name;
                setting.get_value(task_name);
                stop_task(task_name);
            }
        }
        else
        {
            for (auto &task : tasks)
            {
                std::string block_name;
                Algorithm *block = task.second->get_block(setting.get_target());
                if (block != nullptr)
                {
                    block->set_parameter(setting);
                    break;
                }
            }
        }
    }


    /// Set the callback used to send meters.  When the "send_meters" command
    /// is sent to this session, every block in the session will send a
    /// JSON-formatted string containing meter data for each of its meters.
    ///
    /// @param  meter_callback  The callback function used to send meter data.
    void set_meter_callback(void (*meter_callback)(const std::string &))
    {
        this->meter_callback = meter_callback;
    }

private:
    int_fast32_t frames_to_run;
    std::map<std::string, std::unique_ptr<Task>> tasks;
    void (*meter_callback)(const std::string &meter_message);
};


} // namespace bosepro
