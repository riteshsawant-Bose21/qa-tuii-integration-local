
#include <bosepro/configuration.h>
#include <bosepro/navigator.h>

#include <sstream>
#include <string>
#include <vector>


namespace bosepro {


Configuration::Configuration(const std::string &filename)
    : Navigator(filename)
{
}


Configuration::Configuration(std::stringstream &ss)
    : Navigator(ss)
{
}


const SessionConfiguration &Configuration::get_session() const
{
    return (const SessionConfiguration &)get_member("session");
}


bool Configuration::has_audio_tasks() const
{
    return has_member("audio_tasks");
}


const TaskConfiguration &Configuration::get_audio_tasks() const
{
    return (const TaskConfiguration &)get_member("audio_tasks");
}


bool Configuration::has_periodic_tasks() const
{
    return has_member("periodic_tasks");
}


const TaskConfiguration &Configuration::get_periodic_tasks() const
{
    return (const TaskConfiguration &)get_member("periodic_tasks");
}


bool Configuration::has_parameter_settings() const
{
    return has_member("parameter_settings");
}


const ParameterSetting &Configuration::get_parameter_settings() const
{
    return (const ParameterSetting &)get_member("parameter_settings");
}


bool Configuration::has_name() const
{
    return has_member("name");
}


const std::string &Configuration::get_name() const
{
    return get_string("name");
}


template <typename T>
void Configuration::get_value(T &value) const
{
    get_member_value("value", value);
}


bool Configuration::has_properties() const
{
    return has_member("property_settings");
}


bool Configuration::has_property(const std::string &name) const
{
    return list_has_member("property_settings", "name", name);
}


#define DECLARE_TEMPLATE_CONFIGURATION_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string) \
    X(std::vector<std::string>)
#define X(t) \
    template void Configuration::get_value<t>(t &value) const;
DECLARE_TEMPLATE_CONFIGURATION_TYPES
#undef X


const PropertyConfiguration &Configuration::get_property(const std::string &name) const
{
    return (const PropertyConfiguration &)list_get_member("property_settings",
                                                          "name", name);
}


const PropertyConfiguration &Configuration::get_properties() const
{
    return (const PropertyConfiguration &)get_member("property_settings");
}


bool Configuration::has_task_connections() const
{
    return has_member("task_connections");
}


const TaskConnectionConfiguration &Configuration::get_task_connections() const
{
    return (const TaskConnectionConfiguration &)get_member("task_connections");
}


const BlockConfiguration &TaskConfiguration::get_blocks() const
{
    return (const BlockConfiguration &)get_member("blocks");
}


bool TaskConfiguration::has_block_connections() const
{
    return has_member("block_connections");
}


const BlockConnectionConfiguration &TaskConfiguration::get_block_connections() const
{
    return (const BlockConnectionConfiguration &)get_member("block_connections");
}


const std::string &BlockConfiguration::get_algorithm() const
{
    return get_string("algorithm");
}


const std::string &BlockConfiguration::get_module() const
{
    return get_string("module");
}


const std::string &BlockConfiguration::get_processor() const
{
    if (has_member("algorithm"))
    {
        return get_string("algorithm");
    }
    else
    {
        return get_string("module");
    }
}


bool BlockConfiguration::has_terminal(const std::string &name) const
{
    return list_has_member("terminal_channels", "name", name);
}


const TerminalConfiguration &BlockConfiguration::get_terminal(const std::string &name) const
{
    return (TerminalConfiguration &)list_get_member("terminal_channels",
            "name", name);
}


bool BlockConfiguration::has_terminals() const
{
    return has_member("terminal_channels");
}


const TerminalConfiguration &BlockConfiguration::get_terminals() const
{
    return (TerminalConfiguration &)get_member("terminal_channels");
}


int TerminalConfiguration::get_num_channels() const
{
    return get_count("channels");
}


ParameterSetting::ParameterSetting(std::stringstream &ss)
    : Configuration(ss)
{
}


const std::string &ParameterSetting::get_target() const
{
    return get_string("target");
}


bool ParameterSetting::has_value() const
{
    return has_member("value");
}


bool ParameterSetting::has_row() const
{
    size_t index_size = list_size("index");

    return index_size == 1 || index_size == 2;
}


int ParameterSetting::get_row() const
{
    int_fast32_t row;
    get_list_value("index", 0, row);
    return static_cast<int>(row - 1);
}


bool ParameterSetting::has_column() const
{
    size_t index_size = list_size("index");

    return index_size == 2;
}

int ParameterSetting::get_column() const
{
    int_fast32_t column;
    get_list_value("index", 1, column);
    return static_cast<int>(column - 1);
}


const std::string &BlockConnectionConfiguration::get_source_block() const
{
    return get_string("source_block");
}


const std::string &BlockConnectionConfiguration::get_destination_block() const
{
    return get_string("destination_block");
}


const std::string &BlockConnectionConfiguration::get_output_terminal() const
{
    return get_string("output_terminal");
}


const std::string &BlockConnectionConfiguration::get_input_terminal() const
{
    return get_string("input_terminal");
}


int BlockConnectionConfiguration::get_output_channel() const
{
    return get_index("output_channel");
}


int BlockConnectionConfiguration::get_input_channel() const
{
    return get_index("input_channel");
}


const std::string &TaskConnectionConfiguration::get_source_task() const
{
    return get_string("source_task");
}


const std::string &TaskConnectionConfiguration::get_destination_task() const
{
    return get_string("destination_task");
}


const std::string &TaskConnectionConfiguration::get_output_block() const
{
    return get_string("output_block");
}


const std::string &TaskConnectionConfiguration::get_input_block() const
{
    return get_string("input_block");
}


int TaskConnectionConfiguration::get_output_channel() const
{
    return get_index("output_channel");
}


int TaskConnectionConfiguration::get_input_channel() const
{
    return get_index("input_channel");
}


TelemetryConfiguration::TelemetryConfiguration(const std::string& filename)
    : Configuration(filename)
{
}


const std::string& TelemetryConfiguration::get_socket_path() const
{
    TelemetryConfiguration &socket_path((TelemetryConfiguration &)list_get_member("telemetry_configuration",
                                        "name", "socket_path"));
    return socket_path.get_string("property");
}


} // namespace bosepro
