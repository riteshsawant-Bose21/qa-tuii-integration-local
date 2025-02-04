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


bool Session::cmd_stop_all(const ParameterSetting&)
{
    stop();

    return true;
}


bool Session::cmd_destroy_audio_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    destroy_audio_task(task_name);

    return true;
}


bool Session::cmd_destroy_audio_tasks(const ParameterSetting&)
{
    destroy_audio_tasks();

    return true;
}


bool Session::cmd_create_audio_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    Configuration config(filename);
    for (auto &t : config.get_session().get_audio_tasks()) {
        const TaskConfiguration &tc = 
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_audio_task(tc);
    }

    return true;
}


bool Session::cmd_destroy_periodic_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    destroy_periodic_task(task_name);

    return true;
}


bool Session::cmd_destroy_periodic_tasks(const ParameterSetting&)
{
    destroy_periodic_tasks();

    return true;
}


bool Session::cmd_create_periodic_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    Configuration config(filename);
    for (auto &t : config.get_session().get_periodic_tasks()) {
        const TaskConfiguration &tc = 
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_periodic_task(tc);
    }

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
