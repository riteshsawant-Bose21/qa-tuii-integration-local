#include <bosepro/session.h>
#include <spdlog/spdlog.h>

namespace bosepro {


void Session::cmd_send_telemetry(const ParameterSetting&)
{
    if (telemetry_callback != nullptr)
    {
        for (auto &task : tasks)
        {
            task.second->send_telemetry(telemetry_callback);
        }
        for (auto &na_task : na_tasks)
        {
            na_task.second->send_telemetry();
        }
    }
}


void Session::cmd_stop_all(const ParameterSetting&)
{
    stop();
}


void Session::cmd_destroy_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    destroy_task(task_name);
}


void Session::cmd_create_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    bosepro::Configuration config(filename);
    for (auto &t : config.get_session().get_tasks()) {
        const TaskConfiguration &tc = 
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_task(tc);
    }
}


void Session::cmd_create_na_task(const ParameterSetting& setting)
{
    std::string filename;
    setting.get_value(filename);

    bosepro::Configuration config(filename);
    for (auto &t : config.get_session().get_na_tasks()) {
        SPDLOG_INFO("Getting na_tasks.");
        const TaskConfiguration &tc =
            reinterpret_cast<const TaskConfiguration &>(t.second);
        create_na_task(tc);
    }
}


void Session::cmd_start_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    start_task(task_name);
}


void Session::cmd_stop_task(const ParameterSetting& setting)
{
    std::string task_name;
    setting.get_value(task_name);
    stop_task(task_name);
}

} // namespace bosepro
