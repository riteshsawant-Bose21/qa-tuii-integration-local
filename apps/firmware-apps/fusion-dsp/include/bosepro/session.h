#pragma once

#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/audio_task.h>
#include <bosepro/periodic_task.h>

#include <spdlog/spdlog.h>

#include <sys/un.h>
#include <string>
#include <vector>
#include <functional>
#include <map>
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
    /// @param  definitions  The parameter definitions for the system.
    Session(const SessionConfiguration &configuration,
            const Definition &definitions)
        : Configurable(configuration)
          
    {
        SPDLOG_TRACE("Creating session.");
        // This makes the definitions available to all `Configurable` objects.
        set_definitions(definitions);

        ps_command_map = 
        {
            {"stop",                        [this](const ParameterSetting& c){ return cmd_stop_all(c); }},
            {"destroy_audio_task",          [this](const ParameterSetting& c){ return cmd_destroy_audio_task(c); }},
            {"destroy_all_audio_tasks",     [this](const ParameterSetting& c){ return cmd_destroy_audio_tasks(c); }},
            {"create_audio_task",           [this](const ParameterSetting& c){ return cmd_create_audio_task(c); }},
            {"destroy_periodic_task",       [this](const ParameterSetting& c){ return cmd_destroy_periodic_task(c); }},
            {"destroy_all_periodic_tasks",  [this](const ParameterSetting& c){ return cmd_destroy_periodic_tasks(c); }},
            {"create_periodic_task",        [this](const ParameterSetting& c){ return cmd_create_periodic_task(c); }},
            {"start_audio_task",            [this](const ParameterSetting& c){ return cmd_start_audio_task(c); }},
            {"stop_audio_task",             [this](const ParameterSetting& c){ return cmd_stop_audio_task(c); }},
            {"start_periodic_task",         [this](const ParameterSetting& c){ return cmd_start_periodic_task(c); }},
            {"stop_periodic_task",          [this](const ParameterSetting& c){ return cmd_stop_periodic_task(c); }},
            {"apply_parameter_setting",     [this](const ParameterSetting& c){ return cmd_apply_parameter_setting(c); }}
        };

        frames_to_run = -1;
    }


    virtual ~Session() = default;


    /// Process one frame of audio at the highest frame rate of the session.
    /// The might be called in a callback from the system's audio drivers, or
    /// in a loop for file processing.
    virtual void process() override
    {
        for (auto &task : audio_tasks)
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


    void create_audio_tasks(const Configuration &configuration)
    {
        for (auto &t : configuration.get_audio_tasks())
        {
            const TaskConfiguration &tc =
                reinterpret_cast<const TaskConfiguration &>(t.second);
            create_audio_task(tc);
        }
    }


    /// Create a task given a task configuration.  This will also start the
    /// task.
    ///
    /// @param   task_configuration  The configuration for the task.
    void create_audio_task(const TaskConfiguration &task_configuration)
    {
        const std::string task_name = task_configuration.get_name();

        if (audio_tasks.count(task_name) != 0)
        {
            SPDLOG_CRITICAL("Duplicate tasks with name {}.", task_name);
            return;
        }

        audio_tasks[task_name] = std::unique_ptr<AudioTask>(new AudioTask(task_configuration));
    }


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_audio_task(const std::string &task_name)
    {
        if (audio_tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        audio_tasks.erase(task_name);
    }


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_audio_tasks()
    {
        audio_tasks.clear();
    }


    void create_periodic_tasks(const Configuration &configuration)
    {
        for (auto &t : configuration.get_periodic_tasks())
        {
            const TaskConfiguration &tc =
                reinterpret_cast<const TaskConfiguration &>(t.second);
            create_periodic_task(tc);
        }
    }


    /// Create a task given a task configuration.  This will also start the
    /// task.
    ///
    /// @param   task_configuration  The configuration for the task.
    void create_periodic_task(const TaskConfiguration &task_configuration)
    {
        const std::string task_name = task_configuration.get_name();

        if (periodic_tasks.count(task_name) != 0)
        {
            SPDLOG_CRITICAL("Duplicate tasks with name {}.", task_name);
            return;
        }

        periodic_tasks[task_name] = std::unique_ptr<PeriodicTask>(new PeriodicTask(task_configuration));
    }


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_periodic_task(const std::string &task_name)
    {
        if (periodic_tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        periodic_tasks.erase(task_name);
    }


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_periodic_tasks()
    {
        periodic_tasks.clear();
    }


    /// Start an existing task with the given name.
    ///
    /// @param  task_name  The name of the task to start.
    void start_audio_task(const std::string &task_name)
    {
        if (audio_tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        audio_tasks[task_name]->start();
    }


    /// Stop an existing task with the given name.  The task will remain
    /// available to run again using `start_task()`.
    ///
    /// @param  task_name  The name of the task to stop.
    void stop_audio_task(const std::string &task_name)
    {
        if (audio_tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        audio_tasks[task_name]->stop();
    }


    void create_periodic_tasks(const Configuration &configuration)
    {
        for (auto &t : configuration.get_periodic_tasks())
        {
            const TaskConfiguration &tc =
                reinterpret_cast<const TaskConfiguration &>(t.second);
            create_periodic_task(tc);
        }
    }


    /// Create a non-audio task given a task configuration.  This will also start the
    /// task.
    ///
    /// @param   task_configuration  The configuration for the task.
    void create_periodic_task(const TaskConfiguration &task_configuration)
    {
        const std::string task_name = task_configuration.get_name();

        SPDLOG_INFO("Creating periodic_task {}.", task_name);
        if (periodic_tasks.count(task_name) != 0)
        {
            SPDLOG_CRITICAL("Duplicate tasks with name {}.", task_name);
            return;
        }

        periodic_tasks[task_name] = std::unique_ptr<PeriodicTask>(new PeriodicTask(task_configuration));
    }


    /// Start an existing na task with the given name.
    ///
    /// @param  task_name  The name of the task to start.
    void start_periodic_task(const std::string &task_name)
    {
        if (periodic_tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        periodic_tasks[task_name]->start();
    }


    /// Stop an existing na task with the given name.  The task will remain
    /// available to run again using `start_periodic_task()`.
    ///
    /// @param  task_name  The name of the na task to stop.
    void stop_periodic_task(const std::string &task_name)
    {
        if (periodic_tasks.count(task_name) == 0)
        {
            SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
            return;
        }

        periodic_tasks[task_name]->stop();
    }
    

    /// Start all of the tasks in the session.
    void start()
    {
        SPDLOG_INFO("Starting session.");
        for (auto &task : audio_tasks)
        {
            task.second->start();
        }
        for (auto &task : periodic_tasks)
        {
            task.second->start();
        }
    }


    /// Stop all of the tasks in the session.
    void stop()
    {
        SPDLOG_INFO("Stopping session.");
        for (auto &task : audio_tasks)
        {
            task.second->stop();
        }
        for (auto &task : periodic_tasks)
        {
            task.second->stop();
        }
    }

    /// Get a pointer to a signal processing block with the given name.
    ///
    /// @param  name  The name of the block.
    /// @return  A pointer to the block.
    AudioTask *get_task(const std::string &name)
    {
        if (audio_tasks.count(name) != 0)
        {
            return audio_tasks[name].get();
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
        AudioTask *source_task = get_task(configuration.get_source_task());
        AudioTask *destination_task = get_task(configuration.get_destination_task());

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
    /// @param  setting  The setting to process.
    void process_parameter_setting(const ParameterSetting &setting)
    {
        // session commands
        if (setting.get_target() == "session")
        {
            try {
                ps_command_map.at(setting.get_name())(setting);
            } catch (const std::out_of_range&) {
                SPDLOG_WARN("Unknown session setting '{}'", setting.get_name());
            }
        }
        // block parameter setting
        else
        {
            if (!ps_command_map["apply_parameter_setting"](setting))
            {
                SPDLOG_WARN("Unknown block '{}'", setting.get_target());
            }
        }
    }


    /// Socket setting to stop all tasks
    ///
    /// @param setting 
    bool cmd_stop_all(const ParameterSetting& setting);

    /// Socket setting to destroy a specific task
    ///
    /// @param setting 
    bool cmd_destroy_audio_task(const ParameterSetting& setting);

    /// Socket setting to create an audio task
    ///
    /// @param setting 
    bool cmd_create_audio_task(const ParameterSetting& setting);

    /// Socket setting to start a specific task
    ///
    /// @param setting 
    bool cmd_start_audio_task(const ParameterSetting& setting);

    /// Socket setting to stop a specific task
    ///
    /// @param setting 
    bool cmd_stop_audio_task(const ParameterSetting& setting);

    /// Socket setting to create a non-audio task
    ///
    /// @param setting 
    bool cmd_create_periodic_task(const ParameterSetting& setting);

    /// Socket setting to apply parameter setting to a block
    ///
    /// @param setting 
    bool cmd_apply_parameter_setting(const ParameterSetting& setting);


private:
    int_fast32_t frames_to_run;
    std::map<std::string, std::unique_ptr<AudioTask>> audio_tasks;
    std::map<std::string, std::unique_ptr<PeriodicTask>> periodic_tasks;
    std::map<std::string, std::function<bool(const ParameterSetting&)>> ps_command_map;
};


} // namespace bosepro
