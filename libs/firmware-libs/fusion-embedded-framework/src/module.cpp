#include <bosepro/module.h>

#include <bosepro/child_factory.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/parameter.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/telemetry_monitor.h>

#include <cstdint>
#include <functional>
#include <list>
#include <map>
#include <memory>
#include <string>


namespace bosepro {


Module::Module(const BlockConfiguration &configuration)
    : Configurable(configuration)
{
    meta->configuration = &configuration;
    meta->definition = static_cast<const ModuleDefinition*>(get_definition(configuration.get_module()));
    meta->block_name = configuration.get_name();
    meta->module_name = configuration.get_module();

    // There is no need to create constant data, because we just look it
    // up from the definition and configuration.

    // Create the parameter data for all parameters in the module.
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
    // Create the telemetry data for all of the telemetry in the module.
    if (meta->definition->has_telemetry())
    {
        for (auto &m : meta->definition->get_telemetry())
        {
            const TelemetryDefinition &md = reinterpret_cast<const TelemetryDefinition &>(m.second);
            std::unique_ptr<Telemetry> telemetry = 
                std::unique_ptr<Telemetry>(Telemetry::create(
                            md,
                            static_cast<const ProcessorDefinition&>(*meta->definition),
                            meta->configuration));

            telemetry->set_block_name(this->get_block_name());

            // Delegate the telemetry registration to the TelemetryMonitor
            TelemetryMonitor::get_instance().register_telemetry(std::move(telemetry));
        }
    }
}


Module::~Module()
{
    TelemetryMonitor::get_instance().unregister_block(this->get_block_name());
}


const std::string &Module::get_block_name() const
{
    return meta->block_name;
}


const std::string &Module::get_module_name() const
{
    return meta->module_name;
}


Parameter &Module::get_parameter(const std::string &name)
{
    if (meta->parameters.count(name) == 0)
    {
        SPDLOG_CRITICAL("Unknown paramter '{}' in '{}'.",
                name, meta->configuration->get_name());
    }

    return *meta->parameters[name];
}


void Module::initialize_parameters()
{
    SPDLOG_TRACE("Initializing parameters for '{}'.",
                 meta->configuration->get_name());

    for (auto &c : meta->parameters)
    {
        c.second->initialize_post();
    }
}


bool Module::set_parameter(const ParameterSetting &setting)
{
    if (meta->parameters.count(setting.get_name()) == 0)
    {
        SPDLOG_WARN("Unknown parameter '{}' in '{}'.", setting.get_name(),
                meta->configuration->get_name());
        return false;
    }

    get_parameter(setting.get_name()).set(setting);

    return true;
}


template <typename T>
void Module::get_property(const std::string &name, T &value)
{
    if (meta->configuration->has_property(name))
    {
        meta->configuration->get_property(name).get_value(value);
    }
    else if (meta->definition->has_property(name))
    {
        meta->definition->get_property(name).get_default_value(value);
    }
    else
    {
        SPDLOG_CRITICAL("Unknown property '{}' in '{}'.",
                name, meta->configuration->get_name());
    }
}


template <typename T>
void Module::assign_parameter(const std::string &name, T *value,
                              std::function<void()> post_function)
{
    get_parameter(name).assign(value, post_function);
}


template <typename T>
void Module::assign_parameter(const std::string &name,
                              DspCoeffMemory<T[]> &value)
{
    get_parameter(name).assign(value);
}


template <typename T>
void Module::assign_parameter(const std::string &name,
                              DspParamMemory<T[]> &value,
                              std::function<void(int)> post_function)
{
    get_parameter(name).assign(value, post_function);
}


template <typename T>
void Module::assign_parameter(const std::string &name,
                              DspCoeffMemory<T*[]> &value)
{
    get_parameter(name).assign(value);
}


template <typename T>
void Module::assign_parameter(const std::string &name,
                              DspParamMemory<T*[]> &value,
                              std::function<void(int, int)> post_function)
{
    get_parameter(name).assign(value, post_function);
}


template <typename T>
void Module::assign_telemetry(const std::string &name, const T *value,
                              std::function<void()> pre_function)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, pre_function);
}


template <typename T>
void Module::assign_telemetry(const std::string &name, const T *value)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
}


template <typename T>
void Module::assign_telemetry(const std::string &name,
                              DspTelemetryMemory<T[]> &value,
                              std::function<void(int)> pre_function)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, pre_function);
}


template <typename T>
void Module::assign_telemetry(const std::string &name,
                              DspTelemetryMemory<T[]> &value)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
}


template <typename T>
void Module::assign_telemetry(const std::string &name,
                              DspTelemetryMemory<T*[]> &value,
                              std::function<void(int, int)> pre_function)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, pre_function);
}


template <typename T>
void Module::assign_telemetry(const std::string &name,
                              DspTelemetryMemory<T*[]> &value)
{
    TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
}


// Using an X Macro to declare all the template specializations for each
// parameter type.
#define DECLARE_TEMPLATE_MODULE_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string)
#define X(t) \
    template void Module::get_property<t>(const std::string &name, t &value); \
    template void Module::assign_parameter<t>(const std::string &name, \
                                              t* value, \
                                              std::function<void()> post_function); \
    template void Module::assign_parameter<t>(const std::string &name, \
                                              DspCoeffMemory<t[]> &value); \
    template void Module::assign_parameter<t>(const std::string &name, \
                                              DspParamMemory<t[]> &value, \
                                              std::function<void(int)> post_function); \
    template void Module::assign_parameter<t>(const std::string &name, \
                                              DspCoeffMemory<t*[]> &value); \
    template void Module::assign_parameter<t>(const std::string &name, \
                                              DspParamMemory<t*[]> &value, \
                                              std::function<void(int, int)> post_function); \
    template void Module::assign_telemetry<t>(const std::string &name, \
                                              const t* value); \
    template void Module::assign_telemetry<t>(const std::string &name, \
                                              const t* value, \
                                              std::function<void()> pre_function); \
    template void Module::assign_telemetry<t>(const std::string &name, \
                                              DspTelemetryMemory<t[]> &value); \
    template void Module::assign_telemetry<t>(const std::string &name, \
                                              DspTelemetryMemory<t[]> &value, \
                                              std::function<void(int)> pre_function); \
    template void Module::assign_telemetry<t>(const std::string &name, \
                                              DspTelemetryMemory<t*[]> &value); \
    template void Module::assign_telemetry<t>(const std::string &name, \
                                              DspTelemetryMemory<t*[]> &value, \
                                              std::function<void(int, int)> pre_function);
DECLARE_TEMPLATE_MODULE_TYPES
#undef X

template void Module::get_property<std::vector<std::string>>(const std::string &name, std::vector<std::string> &value);

} // namespace bosepro
