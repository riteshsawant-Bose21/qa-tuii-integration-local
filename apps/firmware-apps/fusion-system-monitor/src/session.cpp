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


void Session::cmd_stop_all(const ParameterSetting&)
{
    stop();
}


void Session::cmd_destroy_audio_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    destroy_audio_task(task_name);
}


void Session::cmd_create_audio_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    Configuration config(filename);
    for (auto &t : config.get_session().get_audio_tasks()) {
        const TaskConfiguration &tc = 
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_audio_task(tc);
    }
}


void Session::cmd_start_audio_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    start_audio_task(task_name);
}


void Session::cmd_stop_audio_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    stop_audio_task(task_name);
}


void Session::cmd_create_periodic_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    Configuration config(filename);
    for (auto &t : config.get_session().get_periodic_tasks()) {
        SPDLOG_INFO("Getting periodic_tasks.");
        const TaskConfiguration &tc =
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_periodic_task(tc);
    }
}

} // namespace bosepro
