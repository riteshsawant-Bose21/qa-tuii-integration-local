#include <bosepro/session.h>
#include <spdlog/spdlog.h>

#include <netinet/in.h>
#include <sys/socket.h>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h> 
#include <iostream>

namespace bosepro {

Session::Session(const SessionConfiguration &configuration,
                 const Definition &definitions)
    : Configurable(configuration), ready(false)
{
    SPDLOG_TRACE("Creating session.");
    // This makes the definitions available to all `Configurable` objects.
    set_definitions(definitions);

    ps_command_map = {
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


void Session::process()
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


void Session::set_seconds_to_run(double seconds)
{
    frames_to_run = std::ceil(seconds * get_sample_rate() / get_frame_size());
}


bool Session::finished_running()
{
    return frames_to_run == 0;
}


void Session::create_audio_tasks(const Configuration &configuration)
{
    ready = false;

    bosepro::TelemetryMonitor::get_instance().stop();
    bosepro::TelemetryMonitor::get_instance().unregister_all_telemetry();

    for (auto &t : configuration.get_audio_tasks())
    {
        const TaskConfiguration &tc =
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_audio_task(tc);
    }

    ready = true;
}


void Session::create_audio_task(const TaskConfiguration &task_configuration)
{
    const std::string task_name = task_configuration.get_name();

    if (audio_tasks.count(task_name) != 0)
    {
        throw std::runtime_error("Duplicate tasks with name '"
                                 + task_name + "'.");
    }

    audio_tasks[task_name] = std::unique_ptr<AudioTask>(new AudioTask(task_configuration));
}


void Session::destroy_audio_task(const std::string &task_name)
{
    if (audio_tasks.count(task_name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
        return;
    }

    audio_tasks.erase(task_name);
}


void Session::destroy_audio_tasks()
{
    audio_tasks.clear();
}


void Session::create_periodic_tasks(const Configuration &configuration)
{
    for (auto &t : configuration.get_periodic_tasks())
    {
        const TaskConfiguration &tc =
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_periodic_task(tc);
    }
}


void Session::create_periodic_task(const TaskConfiguration &task_configuration)
{
    const std::string task_name = task_configuration.get_name();

    if (periodic_tasks.count(task_name) != 0)
    {
        SPDLOG_CRITICAL("Duplicate tasks with name {}.", task_name);
        return;
    }

    periodic_tasks[task_name] = std::unique_ptr<PeriodicTask>(new PeriodicTask(task_configuration));
}


void Session::destroy_periodic_task(const std::string &task_name)
{
    if (periodic_tasks.count(task_name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
        return;
    }

    periodic_tasks.erase(task_name);
}


void Session::destroy_periodic_tasks()
{
    periodic_tasks.clear();

    bosepro::TelemetryMonitor::get_instance().stop();
    bosepro::TelemetryMonitor::get_instance().unregister_all_telemetry();
}


void Session::start_audio_task(const std::string &task_name)
{
    if (audio_tasks.count(task_name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
        return;
    }

    audio_tasks[task_name]->start();
}


void Session::stop_audio_task(const std::string &task_name)
{
    if (audio_tasks.count(task_name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
        return;
    }

    audio_tasks[task_name]->stop();
}


void Session::start_periodic_task(const std::string &task_name)
{
    if (periodic_tasks.count(task_name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
        return;
    }

    periodic_tasks[task_name]->start();
}


void Session::stop_periodic_task(const std::string &task_name)
{
    if (periodic_tasks.count(task_name) == 0)
    {
        SPDLOG_CRITICAL("Couldn't find task with name {}.", task_name);
        return;
    }

    periodic_tasks[task_name]->stop();
}


void Session::start()
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

    ready = true;
}


void Session::stop()
{
    ready = false;

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


AudioTask *Session::get_task(const std::string &name)
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


void Session::connect_tasks(const TaskConnectionConfiguration &configuration)
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
            throw std::runtime_error("Nonexistent output block '"
                                     + configuration.get_output_block()
                                     + "' for task connection.");
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
            throw std::runtime_error("Nonexistent input block '"
                                     + configuration.get_input_block()
                                     + "' for task connection.");
        }
    }

    if (source_task == nullptr && destination_task == nullptr)
    {
        throw std::runtime_error("Nonexistent tasks '"
                                 + configuration.get_source_task()
                                 + "' and '"
                                 + configuration.get_destination_task()
                                 + "' for task connection.");
    }
}


void Session::process_parameter_setting(const ParameterSetting &setting)
{
    // session commands
    if (setting.get_target() == "session")
    {
        try {
            ps_command_map.at(setting.get_name())(setting);
        } catch (const std::out_of_range&) {
            throw std::runtime_error("Unknown session parameter '"
                                     + setting.get_name() + "'");
        }
    }
    // block parameter setting
    else
    {
        if (!ps_command_map["apply_parameter_setting"](setting))
        {
            throw std::runtime_error("Unknown block '"
                                     + setting.get_target() + "'");
        }
    }
}


bool Session::is_ready()
{
    return ready;
}


bool Session::cmd_stop_all(const ParameterSetting&)
{
    stop();

    return true;
}


bool Session::cmd_destroy_audio_task(const ParameterSetting& setting)
{
    // no need to stop telemetry, because meters just shrunk

    std::string task_name;
    setting.get_value(task_name);
    destroy_audio_task(task_name);

    return true;
}


bool Session::cmd_destroy_audio_tasks(const ParameterSetting&)
{
    ready = false;

    // stop telemetry because all the tasks are gone!
    bosepro::TelemetryMonitor::get_instance().stop();

    destroy_audio_tasks();

    return true;
}


bool Session::cmd_create_audio_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    Configuration config(filename);

    ready = false;

    // NEED to redo telemetry because meters shm needs to grow
    bosepro::TelemetryMonitor::get_instance().stop();

    if (config.has_audio_tasks())
    {
        for (auto &t : config.get_audio_tasks())
        {
            const TaskConfiguration &tc =
                reinterpret_cast<const TaskConfiguration &>(t.second);
            create_audio_task(tc);
        }
    }

    if (config.has_parameter_settings())
    {
        for (auto &p : config.get_parameter_settings())
        {
            const ParameterSetting &ps =
                reinterpret_cast<const ParameterSetting &>(p.second);
            process_parameter_setting(ps);
        }
    }

    if (config.has_task_connections())
    {
        for (auto &c : config.get_task_connections())
        {
            const TaskConnectionConfiguration &tc =
                reinterpret_cast<const TaskConnectionConfiguration &>(c.second);
            connect_tasks(tc);
        }
    }

    // ready set in start
    start();

    return true;
}


bool Session::cmd_destroy_periodic_task(const ParameterSetting& setting)
{
    // no need to stop telemetry, because meters just shrunk

    std::string task_name;
    setting.get_value(task_name);
    destroy_periodic_task(task_name);

    return true;
}


bool Session::cmd_destroy_periodic_tasks(const ParameterSetting&)
{
    ready = false;

    // stop telemetry because all the tasks are gone!
    bosepro::TelemetryMonitor::get_instance().stop();

    destroy_periodic_tasks();

    return true;
}


bool Session::cmd_create_periodic_task(const ParameterSetting& setting)
{
    ready = false;

    // NEED to redo telemetry because meters GREW
    bosepro::TelemetryMonitor::get_instance().stop();

    std::string filename;
    setting.get_value(filename);

    Configuration config(filename);
    if (config.has_periodic_tasks())
    {
        for (auto &t : config.get_periodic_tasks()) {
            const TaskConfiguration &tc = 
                reinterpret_cast<const TaskConfiguration &>(t.second);
            create_periodic_task(tc);
        }
    }

    if (config.has_parameter_settings())
    {
        for (auto &p : config.get_parameter_settings())
        {
            const ParameterSetting &ps =
                reinterpret_cast<const ParameterSetting &>(p.second);
            process_parameter_setting(ps);
        }
    }

    // ready set in start
    start();

    return true;
}


bool Session::cmd_start_audio_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    start_audio_task(task_name);

    return true;
}


bool Session::cmd_stop_audio_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    stop_audio_task(task_name);

    return true;
}


bool Session::cmd_start_periodic_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    start_periodic_task(task_name);

    return true;
}


bool Session::cmd_stop_periodic_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    stop_periodic_task(task_name);

    return true;
}


bool Session::cmd_apply_parameter_setting(const ParameterSetting& setting)
{
    for (auto &task : audio_tasks)
    {
        std::string block_name;
        Algorithm *block = task.second->get_block(setting.get_target());
        if (block != nullptr)
        {
            block->set_parameter(setting);
            
            return true;
        }
    }
    for (auto &task : periodic_tasks)
    {
        std::string block_name;
        Module *block = task.second->get_block(setting.get_target());
        if (block != nullptr)
        {
            block->set_parameter(setting);
            
            return true;
        }
    }

    return false;
}

} // namespace bosepro
