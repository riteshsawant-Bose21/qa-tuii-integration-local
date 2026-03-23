#include <bosepro/algorithm.h>

#include <bosepro/child_factory.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/conversion.h>
#include <bosepro/parameter.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/terminal.h>
#include <bosepro/telemetry_monitor.h>

#include <cstdint>
#include <functional>
#include <map>
#include <memory>
#include <string>


namespace bosepro {


Algorithm::Algorithm(const BlockConfiguration &configuration)
    : Configurable(configuration), output_process_count(0)
{
    meta->configuration = &configuration;
    meta->definition = static_cast<const AlgorithmDefinition*>(get_definition(configuration.get_algorithm()));
    meta->block_name = configuration.get_name();
    meta->algorithm_name = configuration.get_algorithm();

    // There is no need to create property data, because we just look it
    // up from the algorithm's property definitions and the configuration.
    if (meta->configuration->has_properties())
    {
        for (auto &p : meta->configuration->get_properties())
        {
            const PropertyConfiguration &pc = static_cast<const PropertyConfiguration &>(p.second);
            const std::string &name = pc.get_name();

            if (!meta->definition->has_property(name)
                    && name != "sample_rate" && name != "frame_size")
            {
                throw std::runtime_error("Unknown property '" + name
                        + "' in '"
                        + meta->configuration->get_name()
                        + "'.");
            }
        }
    }

    if (meta->configuration->has_terminals())
    {
        for (auto &t : meta->configuration->get_terminals())
        {
            const TerminalConfiguration &tc = static_cast<const TerminalConfiguration &>(t.second);
            const std::string &name = tc.get_name();

            if (!meta->definition->has_terminal(name))
            {
                throw std::runtime_error("Unknown terminal '" + name
                        + "' in '"
                        + meta->configuration->get_name()
                        + "'.");
            }
        }
    }

    // Create the terminal data for all of the terminals in the algorithm.
    // We use the definition rather than the configuration, because the
    // configuration may not contain terminal settings if the number of
    // channels is fixed or derived from a property value.
    // We assume there must be at least one terminal for every algorithm.
    for (auto &t : meta->definition->get_terminals())
    {
        const TerminalDefinition &td =
            reinterpret_cast<const TerminalDefinition &>(t.second);
        const std::string &name = td.get_name();
        meta->terminals[name] =
            std::make_unique<Terminal>(Terminal(td,
                        static_cast<const ProcessorDefinition&>(*meta->definition),
                        meta->configuration,
                        get_frame_size()));
    }

    // Create the parameter data for all of the parameters in the algorithm.
    if (meta->definition->has_parameters())
    {
        for (auto &p: meta->definition->get_parameters())
        {
            const ParameterDefinition &pd =
                reinterpret_cast<const ParameterDefinition &>(p.second);
            const std::string &name = pd.get_name();

            meta->parameters[name] =
                std::unique_ptr<Parameter>(Parameter::create(pd,
                            static_cast<const ProcessorDefinition&>(*meta->definition),
                            meta->configuration));
        }
    }

    // Create the meter data for all of the telemetry in the algorithm.
    if (meta->definition->has_telemetry())
    {
        for (auto &m : meta->definition->get_telemetry())
        {
            const TelemetryDefinition &md = reinterpret_cast<const TelemetryDefinition &>(m.second);
            std::unique_ptr<Telemetry> telemetry = 
                std::unique_ptr<Telemetry>(Telemetry::create(md,
                            static_cast<const ProcessorDefinition&>(*meta->definition),
                            meta->configuration));

            telemetry->set_block_name(this->get_block_name());

            // Delegate the telemetry registration to the TelemetryMonitor
            TelemetryMonitor::get_instance().register_telemetry(std::move(telemetry));
        }
    }

    // Count up how many terminals we have.
    for (auto &t : meta->definition->get_terminals())
    {
        const TerminalDefinition &td =
            reinterpret_cast<const TerminalDefinition &>(t.second);
        const std::string &name = td.get_name();
        Terminal &terminal = *meta->terminals[name];

        if (terminal.is_output())
        {
            const std::string gain_name = name + "_gain";
            const std::string mute_name = name + "_mute";
            const std::string meter_name = name + "_meter";

            if ((meta->parameters.count(gain_name) != 0)
                || (meta->parameters.count(mute_name) != 0)
                || (TelemetryMonitor::get_instance().has_meter(this->get_block_name() +  "::" + meter_name) != 0)
                || (td.has_bypass_source()
                    && (meta->parameters.count("bypass") != 0)))
            {
                output_process_count++;
            }
        }
    }

    outputs_to_process.resize(output_process_count);
    int top_index = 0;

    // Assign universal parameters and meter to the associated output
    // terminals.
    for (auto &t : meta->definition->get_terminals())
    {
        const TerminalDefinition &td =
            reinterpret_cast<const TerminalDefinition &>(t.second);
        const std::string &name = td.get_name();
        Terminal &terminal = *meta->terminals[name];

        if (terminal.is_output())
        {
            const std::string gain_name = name + "_gain";
            const std::string mute_name = name + "_mute";
            const std::string meter_name = name + "_meter";
            TerminalOutputProcessor &top = outputs_to_process[top_index];
            bool requires_processing = false;

            if (meta->parameters.count(gain_name) != 0)
            {
                assign_parameter(gain_name, top.get_gain(), db_to_linear);
                requires_processing = true;
            }

            if (meta->parameters.count(mute_name) != 0)
            {
                assign_parameter(mute_name, top.get_mute());
                requires_processing = true;
            }

            if (TelemetryMonitor::get_instance().has_meter(this->get_block_name() +  
                        "::" + meter_name))
            {
                assign_telemetry(meter_name, top.get_telemetry(), linear_to_db);
                requires_processing = true;
            }

            if (td.has_bypass_source() && meta->parameters.count("bypass") != 0)
            {
                assign_parameter("bypass", top.get_bypass());
                requires_processing = true;
            }

            if (requires_processing)
            {
                terminal.set_output_processor(&top);
                top_index++;
            }
        }
    }
}


Algorithm::~Algorithm()
{
    TelemetryMonitor::get_instance().unregister_block(this->get_block_name());
}


const std::string &Algorithm::get_block_name() const
{
    return meta->block_name;
}


const std::string &Algorithm::get_algorithm_name() const
{
    return meta->algorithm_name;
}


void Algorithm::initialize_terminals()
{
    SPDLOG_TRACE("Initializing terminals for '{}'.",
                 meta->configuration->get_name());

    // We have to do this here because the source buffers for the bypass
    // function aren't available until after the terminals are assigned
    // in the algorithm-specific constructor.
    for (auto &t : meta->definition->get_terminals())
    {
        const TerminalDefinition &td =
            reinterpret_cast<const TerminalDefinition &>(t.second);
        const std::string &name = td.get_name();
        Terminal &terminal = *meta->terminals[name];

        if (terminal.is_output())
        {
            TerminalOutputProcessor *top = terminal.get_output_processor();

            if (td.has_bypass_source()
                && meta->parameters.count("bypass") != 0
                && top != nullptr)
            {
                top->set_bypass_source(
                        meta->terminals[td.get_bypass_source()]->get_buffers());
            }
        }
    }

    for (auto &t : meta->terminals)
    {
        t.second->initialize();
    }
}


Terminal &Algorithm::get_terminal(const std::string &name)
{
    if (meta->terminals.count(name) == 0)
    {
        throw std::runtime_error("Unknown terminal '" + name + "' in '"
                                 + meta->configuration->get_name() + "'.");
    }

    return *meta->terminals[name];
}


void Algorithm::connect_terminal(const std::string &name, int input_channel,
                                 Terminal &output_terminal, int output_channel)
{
    if (meta->terminals.count(name) == 0)
    {
        throw std::runtime_error("Unknown terminal '" + name + "' in '"
                                 + meta->configuration->get_name() + "'.");
    }

    meta->terminals[name]->connect(input_channel, output_terminal,
                                   output_channel);
}


int Algorithm::get_empty_frame_size() const
{
    int largest_frame_size = 0;

    for (auto &t : meta->terminals)
    {
        if (!t.second->is_output() && t.second->is_unconnected())
        {
            largest_frame_size = std::max(largest_frame_size,
                                          t.second->get_frame_size());
        }
    }

    return largest_frame_size;
}


void Algorithm::set_empty_signal(DspSignalMemory<const float[]> &signal_memory)
{
    for (auto &t : meta->terminals)
    {
        if (!t.second->is_output())
        {
            t.second->set_empty_signal(signal_memory.get());
        }
    }
}


Parameter &Algorithm::get_parameter(const std::string &name)
{
    if (meta->parameters.count(name) == 0)
    {
        SPDLOG_CRITICAL("Unknown parameter '{}' in '{}'.",
                        name, meta->configuration->get_name());
    }

    return *meta->parameters[name];
}


void Algorithm::initialize_parameters()
{
    SPDLOG_TRACE("Initializing parameters for '{}'.",
                 meta->configuration->get_name());

    for (auto &c : meta->parameters)
    {
        c.second->initialize_post();
    }
}


bool Algorithm::set_parameter(const ParameterSetting &setting)
{
    if (meta->parameters.count(setting.get_name()) == 0)
    {
        throw std::runtime_error("Unknown parameter '" + setting.get_name()
                                 + "' in '" + meta->block_name + "'.");
        return false;
    }

    get_parameter(setting.get_name()).set(setting);

    return true;
}


template <typename T>
void Algorithm::get_property(const std::string &name, T &value)
{
    const PropertyDefinition &pd = meta->definition->get_property(name);

    if (meta->configuration->has_property(name))
    {
        meta->configuration->get_property(name).get_value(value);
    }
    else if (meta->definition->has_property(name))
    {
        pd.get_default_value(value);
        SPDLOG_DEBUG("No value specified for property '{}', using {}.",
                     name, value);
    }
    else
    {
        throw std::runtime_error("Unknown property '" + name + "' in '"
                                 + meta->configuration->get_name() + "'.");
    }

    if (pd.has_allowed_values())
    {
        if (!pd.is_allowed_value(value))
        {
            throw std::runtime_error("Property '" + name + "' in '"
                                     + meta->configuration->get_name()
                                     + "' has an invalid value.");
        }
    }
    else if constexpr(std::is_same_v<T, int_fast32_t>
                      || std::is_same_v<T, float>)
    {
        T minimum_value;
        T maximum_value;
        pd.get_minimum_value(minimum_value);
        pd.get_maximum_value(maximum_value);

        if (value < minimum_value || value > maximum_value)
        {
            throw std::runtime_error("Property '" + name + "' in '"
                                     + meta->configuration->get_name()
                                     + "' is out of range.");
        }
    }
    else if constexpr(std::is_same_v<T, std::string>)
    {
        if (value.length() > pd.get_maximum_length())
        {
            throw std::runtime_error("Property '" + name + "' in '"
                                     + meta->configuration->get_name()
                                     + "' is too long.");
        }
    }
}


void Algorithm::get_terminal_num_channels(const std::string &name,
                                          int &num_channels)
{
    num_channels = get_terminal(name).get_num_channels();
}


template <typename T>
void Algorithm::assign_terminal(const std::string &name,
                                DspSignalMemory<const T[]> &signal_memory)
{
    get_terminal(name).assign(signal_memory);
}


template <typename T>
void Algorithm::assign_terminal(const std::string &name,
                                DspSignalMemory<const T*[]> &signal_memory)
{
    get_terminal(name).assign(signal_memory);
}


template <typename T>
void Algorithm::assign_terminal(const std::string &name,
                                DspSignalMemory<T[]> &signal_memory)
{
    get_terminal(name).assign(signal_memory);
}


template <typename T>
void Algorithm::assign_terminal(const std::string &name,
                                DspSignalMemory<T*[]> &signal_memory)
{
    get_terminal(name).assign(signal_memory);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name, T *value)
{
    get_parameter(name).assign(value);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name, T *value,
                                 T (*conversion_function)(T))
{
    get_parameter(name).assign(value, conversion_function);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name, T *value,
                                 std::function<void()> post_function)
{
    get_parameter(name).assign(value, post_function);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name,
                                 DspCoeffMemory<T[]> &value)
{
    get_parameter(name).assign(value);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name,
                                 DspCoeffMemory<T[]> &value,
                                 T (*conversion_function)(T))
{
    get_parameter(name).assign(value, conversion_function);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name,
                                 DspParamMemory<T[]> &value,
                                 std::function<void(int)> post_function)
{
    get_parameter(name).assign(value, post_function);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name,
                                 DspCoeffMemory<T*[]> &value)
{
    get_parameter(name).assign(value);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name,
                                 DspCoeffMemory<T*[]> &value,
                                 T (*conversion_function)(T))
{
    get_parameter(name).assign(value, conversion_function);
}


template <typename T>
void Algorithm::assign_parameter(const std::string &name,
                                 DspParamMemory<T*[]> &value,
                                 std::function<void(int, int)> post_function)
{
    get_parameter(name).assign(value, post_function);
}


template <typename T>
void Algorithm::assign_telemetry(const std::string &name, const T *value)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
}


template <typename T>
void Algorithm::assign_telemetry(const std::string &name, const T *value,
                                 T (*conversion_function)(T))
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, conversion_function);
}


template <typename T>
void Algorithm::assign_telemetry(const std::string &name,
                                 DspTelemetryMemory<T[]> &value)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
}


template <typename T>
void Algorithm::assign_telemetry(const std::string &name,
                                 DspTelemetryMemory<T[]> &value,
                                 T (*conversion_function)(T))
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, conversion_function);
}


template <typename T>
void Algorithm::assign_telemetry(const std::string &name,
                                 DspTelemetryMemory<T*[]> &value)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
}


template <typename T>
void Algorithm::assign_telemetry(const std::string &name,
                                 DspTelemetryMemory<T*[]> &value,
                                 T (*conversion_function)(T))
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, conversion_function);
}


// Using an X Macro to declare all the template specializations for each
// parameter type.
#define DECLARE_TEMPLATE_ALGORITHM_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string)
#define X(t) \
    template void Algorithm::get_property<t>(const std::string &name, t &value); \
    template void Algorithm::assign_terminal<t>(const std::string &name, \
                                                DspSignalMemory<const t[]> &signal_memory); \
    template void Algorithm::assign_terminal<t>(const std::string &name, \
                                                DspSignalMemory<const t*[]> &signal_memory); \
    template void Algorithm::assign_terminal<t>(const std::string &name, \
                                                DspSignalMemory<t[]> &signal_memory); \
    template void Algorithm::assign_terminal<t>(const std::string &name, \
                                                DspSignalMemory<t*[]> &signal_memory); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 t* value); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 t* value, \
                                                 t (*conversion_function)(t)); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 t* value, \
                                                 std::function<void()> post_function); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 DspCoeffMemory<t[]> &value); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 DspCoeffMemory<t[]> &value, \
                                                 t (*conversion_function)(t)); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 DspParamMemory<t[]> &value, \
                                                 std::function<void(int)> post_function); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 DspCoeffMemory<t*[]> &value); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 DspCoeffMemory<t*[]> &value, \
                                                 t (*conversion_function)(t)); \
    template void Algorithm::assign_parameter<t>(const std::string &name, \
                                                 DspParamMemory<t*[]> &value, \
                                                 std::function<void(int, int)> post_function); \
    template void Algorithm::assign_telemetry<t>(const std::string &name, \
                                                 const t* value); \
    template void Algorithm::assign_telemetry<t>(const std::string &name, \
                                                 const t* value, \
                                                 t (*conversion_function)(t)); \
    template void Algorithm::assign_telemetry<t>(const std::string &name, \
                                                 DspTelemetryMemory<t[]> &value); \
    template void Algorithm::assign_telemetry<t>(const std::string &name, \
                                                 DspTelemetryMemory<t[]> &value, \
                                                 t (*conversion_function)(t)); \
    template void Algorithm::assign_telemetry<t>(const std::string &name, \
                                                 DspTelemetryMemory<t*[]> &value); \
    template void Algorithm::assign_telemetry<t>(const std::string &name, \
                                                 DspTelemetryMemory<t*[]> &value, \
                                                 t (*conversion_function)(t));
DECLARE_TEMPLATE_ALGORITHM_TYPES
#undef X

} // namespace bosepro
