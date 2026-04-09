
#include <bosepro/definition.h>

#include <spdlog/spdlog.h>

#include <string>
#include <vector>

namespace bosepro {


Definition::Definition(const std::string &filename)
    : Navigator(filename)
{
}


const std::string &Definition::get_name() const
{
    return get_string("name");
}


const std::string &Definition::get_value_type() const
{
    return get_string("value_type");
}


int Definition::get_num_dimensions() const
{
    return list_size("dimensions");
}


void Definition::get_dimensions(int &num_rows, int &num_columns,
                                std::string &rows_name,
                                std::string &columns_name) const
{
    if (get_num_dimensions() == 0)
    {
        rows_name = "";
        columns_name = "";
        return;
    }

    if (!try_list_value("dimensions", 0, rows_name))
    {
        rows_name = "";
        int_fast32_t rows_value;
        try_list_value("dimensions", 0, rows_value);
        num_rows = static_cast<int>(rows_value);
    }

    if (get_num_dimensions() == 1)
    {
        columns_name = "";
        return;
    }

    if (!try_list_value("dimensions", 1, columns_name))
    {
        columns_name = "";
        int_fast32_t columns_value;
        try_list_value("dimensions", 1, columns_value);
        num_columns = static_cast<int>(columns_value);
    }
}


bool Definition::has_algorithm(const std::string &name) const
{
    return list_has_member("algorithms", "name", name);
}


const AlgorithmDefinition &Definition::get_algorithm(const std::string &name) const
{
    return (const AlgorithmDefinition &)list_get_member("algorithms", "name",
                                                        name);
}


bool Definition::has_module(const std::string &name) const
{
    return list_has_member("modules", "name", name);
}


const ModuleDefinition &Definition::get_module(const std::string &name) const
{
    return (const ModuleDefinition &)list_get_member("modules", "name", name);
}


bool Definition::has_property(const std::string &name) const
{
    return list_has_member("properties", "name", name);
}


const PropertyDefinition &Definition::get_property(const std::string &name) const
{
    return (const PropertyDefinition &)list_get_member("properties", "name",
                                                       name);
}


template <typename T>
void Definition::get_default_value(T &value) const
{
    get_member_value<T>("default_value", value);
}


bool Definition::has_minimum_value() const
{
    return has_member("minimum_value");
}


template <typename T>
void Definition::get_minimum_value(T &value) const
{
    get_member_value<T>("minimum_value", value);
}


bool Definition::has_maximum_value() const
{
    return has_member("maximum_value");
}


template <typename T>
void Definition::get_maximum_value(T &value) const
{
    get_member_value<T>("maximum_value", value);
}


template <typename T>
void Definition::get_maximum_value(T &value, std::string &maximum_name) const
{
    if (try_member_value<T>("maximum_value", value))
    {
        SPDLOG_DEBUG("Got maximum value from definition: {}.", value);
        maximum_name = "";
    }
    else if (try_member_value<std::string>("maximum_value", maximum_name))
    {
        SPDLOG_DEBUG("Got maximum value from definition: {}.", maximum_name.c_str());
    }
    else
    {
        SPDLOG_CRITICAL("Failed to get maximum value from definition.");
    }
}


bool Definition::has_maximum_length() const
{
    return has_member("maximum_length");
}


size_t Definition::get_maximum_length() const
{
    int_fast32_t length;
    get_member_value("maximum_length", length);
    return static_cast<size_t>(length);
}


bool Definition::has_allowed_values() const
{
    return has_member("allowed_values");
}


template <typename T>
void Definition::get_allowed_values(std::set<T> &values) const
{
    get_list_values("allowed_values", values);
}


template <typename T>
bool Definition::is_allowed_value(const T &value) const
{
    std::set<T> allowed_values;
    get_allowed_values(allowed_values);
    return allowed_values.find(value) != allowed_values.end();
}


#define DECLARE_TEMPLATE_DEFINITION_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string)
#define X(t) \
    template void Definition::get_default_value<t>(t &value) const; \
    template void Definition::get_minimum_value<t>(t &value) const; \
    template void Definition::get_maximum_value<t>(t &value) const; \
    template void Definition::get_maximum_value<t>(t &value, \
                                                   std::string &maximum_name) const; \
    template void Definition::get_allowed_values<t>(std::set<t> &values) const; \
    template bool Definition::is_allowed_value<t>(const t &value) const;
DECLARE_TEMPLATE_DEFINITION_TYPES
#undef X

template void Definition::get_default_value<std::vector<std::string>>(std::vector<std::string> &value) const;

bool ProcessorDefinition::has_terminals() const
{
    return has_member("terminals");
}


const TerminalDefinition &ProcessorDefinition::get_terminals() const
{
    return (const TerminalDefinition &)get_member("terminals");
}


bool ProcessorDefinition::has_terminal(const std::string &name) const
{
    return list_has_member("terminals", "name", name);
}


const TerminalDefinition &ProcessorDefinition::get_terminal(const std::string &name) const
{
    return (const TerminalDefinition &)list_get_member("terminals", "name",
                                                       name);
}


bool ProcessorDefinition::has_parameters() const
{
    return has_member("parameters");
}


const ParameterDefinition &ProcessorDefinition::get_parameters() const
{
    return (const ParameterDefinition &)get_member("parameters");
}


bool ProcessorDefinition::has_telemetry() const
{
    return has_member("telemetry");
}


const TelemetryDefinition &ProcessorDefinition::get_telemetry() const
{
    return (const TelemetryDefinition &)get_member("telemetry");
}


bool TerminalDefinition::is_output() const
{
    return get_string("direction") == "output";
}


bool TerminalDefinition::has_channels() const
{
    return has_member("channels");
}


int TerminalDefinition::get_channels(std::string &property_name) const
{
    int_fast32_t channels = 0;

    if (try_member_value<int_fast32_t>("channels", channels))
    {
        SPDLOG_DEBUG("Got channels from definition: {}.", channels);
    }
    else if (try_member_value<std::string>("channels", property_name))
    {
        SPDLOG_DEBUG("Got channels from definition: {}.", property_name.c_str());
    }
    else
    {
        SPDLOG_CRITICAL("Failed to get channels from definition.");
    }

    return static_cast<int>(channels);
}


int TerminalDefinition::get_minimum_channels() const
{
    int_fast32_t minimum_channels = 0;
    get_member_value("minimum_channels", minimum_channels);
    return static_cast<int>(minimum_channels);
}


int TerminalDefinition::get_maximum_channels() const
{
    int_fast32_t maximum_channels = 0;
    get_member_value("maximum_channels", maximum_channels);
    return static_cast<int>(maximum_channels);
}


bool TerminalDefinition::has_bypass_source() const
{
    return has_member("bypass_source");
}


const std::string &TerminalDefinition::get_bypass_source() const
{
    return get_string("bypass_source");
}


const std::string &TelemetryDefinition::get_period_type() const
{
    return get_string("period_type");
}


const std::string &TelemetryDefinition::get_telemetry_type() const
{
    return get_string("telemetry_type");
}


} // namespace bosepro
