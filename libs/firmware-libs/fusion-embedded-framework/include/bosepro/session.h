#pragma once

#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/audio_task.h>
#include <bosepro/periodic_task.h>

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
            const Definition &definitions);


    virtual ~Session() = default;


    /// Process one frame of audio at the highest frame rate of the session.
    /// The might be called in a callback from the system's audio drivers, or
    /// in a loop for file processing.
    virtual void process() override;


    /// Set the number of frames that the session is to run before finishing.
    /// The progress of this duration can be checked using `finished_running()`.
    ///
    /// @param  seconds  The duration in seconds to run.
    void set_seconds_to_run(double seconds);


    /// Test whether the session has finished running, in the case where a
    /// duration has been set using `set_seconds_to_run()`.  If the duration
    /// has not been set, this always returns `true`.
    ///
    /// @return  `true` if the session has finished running.
    bool finished_running();


    void create_audio_tasks(const Configuration &configuration);


    /// Create a task given a task configuration.  This will also start the
    /// task.
    ///
    /// @param   task_configuration  The configuration for the task.
    void create_audio_task(const TaskConfiguration &task_configuration);


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_audio_task(const std::string &task_name);


    /// Destroy all audio tasks.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_audio_tasks();


    void create_periodic_tasks(const Configuration &configuration);


    /// Create a task given a task configuration.  This will also start the
    /// task.
    ///
    /// @param   task_configuration  The configuration for the task.
    void create_periodic_task(const TaskConfiguration &task_configuration);


    /// Destroy the task with the given name.  This will also stop the task.
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_periodic_task(const std::string &task_name);


    /// Destroy all periodic tasks
    ///
    /// @param  task_name  The name of the task to destroy.
    void destroy_periodic_tasks();


    /// Start an existing task with the given name.
    ///
    /// @param  task_name  The name of the task to start.
    void start_audio_task(const std::string &task_name);


    /// Stop an existing task with the given name.  The task will remain
    /// available to run again using `start_task()`.
    ///
    /// @param  task_name  The name of the task to stop.
    void stop_audio_task(const std::string &task_name);


    /// Start an existing na task with the given name.
    ///
    /// @param  task_name  The name of the task to start.
    void start_periodic_task(const std::string &task_name);


    /// Stop an existing na task with the given name.  The task will remain
    /// available to run again using `start_periodic_task()`.
    ///
    /// @param  task_name  The name of the na task to stop.
    void stop_periodic_task(const std::string &task_name);


    /// Start all of the tasks in the session.
    void start();


    /// Stop all of the tasks in the session.
    void stop();


    /// Get a pointer to a signal processing block with the given name.
    ///
    /// @param  name  The name of the block.
    /// @return  A pointer to the block.
    AudioTask *get_task(const std::string &name);


    /// Process the list of task connections specified in a configuration,
    /// connecting JACK input and output ports accordingly.
    ///
    /// @param  configuration  A list of task connections from the
    ///                        configuration.
    void connect_tasks(const TaskConnectionConfiguration &configuration);


    /// Process the provided command.
    ///
    /// @param  setting  The setting to process.
    void process_parameter_setting(const ParameterSetting &setting);


    /// Retrieve the ready flag
    ///
    /// @return  the ready flag bool
    bool is_ready();


    /// Socket setting to stop all tasks
    ///
    /// @param setting 
    bool cmd_stop_all(const ParameterSetting& setting);

    /// Socket setting to destroy a specific task
    ///
    /// @param setting 
    bool cmd_destroy_audio_task(const ParameterSetting& setting);

    /// Socket setting to destroy a specific task
    ///
    /// @param setting 
    bool cmd_destroy_audio_tasks(const ParameterSetting& setting);

    /// Socket setting to create an audio task
    ///
    /// @param setting 
    bool cmd_create_audio_task(const ParameterSetting& setting);

    /// Socket setting to destroy a specific task
    ///
    /// @param setting 
    bool cmd_destroy_periodic_task(const ParameterSetting& setting);

    /// Socket setting to destroy a specific task
    ///
    /// @param setting 
    bool cmd_destroy_periodic_tasks(const ParameterSetting& setting);

    /// Socket setting to create an audio task
    ///
    /// @param setting 
    bool cmd_create_periodic_task(const ParameterSetting& setting);

    /// Socket setting to start a specific task
    ///
    /// @param setting 
    bool cmd_start_audio_task(const ParameterSetting& setting);

    /// Socket setting to stop a specific task
    ///
    /// @param setting 
    bool cmd_stop_audio_task(const ParameterSetting& setting);

    /// Socket setting to start a specific task
    ///
    /// @param setting 
    bool cmd_start_periodic_task(const ParameterSetting& setting);

    /// Socket setting to stop a specific task
    ///
    /// @param setting 
    bool cmd_stop_periodic_task(const ParameterSetting& setting);

    /// Socket setting to apply parameter setting to a block
    ///
    /// @param setting 
    bool cmd_apply_parameter_setting(const ParameterSetting& setting);


private:
    int_fast32_t frames_to_run;
    std::map<std::string, std::unique_ptr<AudioTask>> audio_tasks;
    std::map<std::string, std::unique_ptr<PeriodicTask>> periodic_tasks;
    std::map<std::string, std::function<bool(const ParameterSetting&)>> ps_command_map;

    std::atomic<bool> ready;
};


} // namespace bosepro
