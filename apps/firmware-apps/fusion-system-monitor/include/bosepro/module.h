#pragma once

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


/// A structure for managing the non-real-time data of an module.  This will
/// eventually help manage cache performance, keeping the real-time data more
/// localized.
struct ModuleMeta {
    const ModuleDefinition *definition;
    const BlockConfiguration *configuration;
    std::map<std::string, std::unique_ptr<Parameter>> parameters;
    std::string block_name;
    std::string module_name;
};


/// A base class for all FW and HW modules.
class Module : public Configurable {
public:
    /// Create an module object based on the configuration for a block.
    ///
    /// @param  configuration  The configuration to use for the module.
    Module(const BlockConfiguration &configuration)
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


    virtual ~Module() 
    {
        TelemetryMonitor::get_instance().unregister_block(this->get_block_name());
    }


    /// Run the modules process. Every module must implement this.
    virtual void process() = 0;


    /// Return the name of this block.
    const std::string &get_block_name() const
    {
        return meta->block_name;
    }


    /// Return the name of this module.
    const std::string &get_module_name() const
    {
        return meta->module_name;
    }


    /// Get a reference to a parameter by name.  This is called by the framework,
    /// not by the module.
    ///
    /// @param  name  The name of the parameter.
    /// @return  A reference to the parameter.
    Parameter &get_parameter(const std::string &name)
    {
        if (meta->parameters.count(name) == 0)
        {
            SPDLOG_CRITICAL("Unknown paramter '{}' in '{}'.",
                            name, meta->configuration->get_name());
        }

        return *meta->parameters[name];
    }


    /// Initialize all of the parameters.  This is called by the framework,
    /// not by the module.  This will allocate storage for the parameter
    /// values, and set them to their defaults.  Then, if any parameter settings
    /// are present in the configuration, they will be applied.
    void initialize_parameters()
    {
        SPDLOG_TRACE("Initializing parameters for '{}'.",
                     meta->configuration->get_name());

        for (auto &c : meta->parameters)
        {
            c.second->initialize_post();
        }
    }


    /// Set a parameter value.  This is called by the framework, not by the
    /// module.
    ///
    /// @param  setting  The setting to apply.
    /// @return  True if the setting was applied, false if the parameter was
    ///          not found.
    bool set_parameter(const ParameterSetting &setting)
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


protected:
    /// Get the value of a constant from the configuration.  If this constant
    /// is not specified in the configuration, the default value from the
    /// parameter definition is used.
    ///
    /// @param  name  The name of the constant.
    /// @param  value  The value of the constant.
    template <typename T>
    void get_property(const std::string &name, T &value)
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


    /// Assign storage for a scalar parameter value.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_SCALAR()` can be used to facilitate creating the
    /// `post_function` argument from a member function, if needed.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  post_function  An optional function to be called after the value
    ///                        is set.
    template <typename T>
    void assign_parameter(const std::string &name, T *value,
                        std::function<void()> post_function = nullptr)
    {
        get_parameter(name).assign(value, post_function);
    }


    /// Assign storage for vector parameter values that are coefficients that
    /// can used directly by the module without conversion.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T[]> &value)
    {
        get_parameter(name).assign(value);
    }


    /// Assign storage for vector parameter values that are intermediate and
    /// not used in real-time.  The post function is used to update the
    /// module's coefficients with values derived from the parameter value.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_VECTOR()` can be used to facilitate creating the
    /// `post_function` argument from a member function.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign_parameter(const std::string &name, DspParamMemory<T[]> &value,
                        std::function<void(int)> post_function)
    {
        get_parameter(name).assign(value, post_function);
    }


    /// Assign storage for matrix parameter values that are coefficients that
    /// can used directly by the module without conversion.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T*[]> &value)
    {
        get_parameter(name).assign(value);
    }


    /// Assign storage for matrix parameter values that are intermediate and
    /// not used in real-time.  The post function is used to update the
    /// module's coefficients with values derived from the parameter value.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_MATRIX()` can be used to facilitate creating the
    /// `post_function` argument from a member function.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign_parameter(const std::string &name, DspParamMemory<T*[]> &value,
                        std::function<void(int, int)> post_function)
    {
        get_parameter(name).assign(value, post_function);
    }


    /// Assign storage for a scalar telemetry value.
    ///
    /// @param  name  The name of the telemetry.
    /// @param  value  The storage for the telemetry value.
    /// @param  pre_function  A function to be called before the value is sent.
    template <typename T>
    void assign_telemetry(const std::string &name, const T *value,
                        std::function<void()> pre_function)
    {
        TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, pre_function);
    }


    /// Assign storage for a scalar telemetry value.
    ///
    /// @param  name  The name of the telemetry.
    /// @param  value  The storage for the telemetry value.
    template <typename T>
    void assign_telemetry(const std::string &name, const T *value)
    {
        TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
    }


    /// Assign storage for vector telemetry values.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the telemetry.
    /// @param  value  The storage for the telemetry value.
    /// @param  pre_function  A function to be called before the value is sent.
    template <typename T>
    void assign_telemetry(const std::string &name, DspTelemetryMemory<T[]> &value,
                        std::function<void(int)> pre_function)
    {
        TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, pre_function);
    }


    /// Assign storage for vector telemetry values.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the telemetry.
    /// @param  value  The storage for the telemetry value.
    /// @param  pre_function  A function to be called before the value is sent.
    template <typename T>
    void assign_telemetry(const std::string &name, DspTelemetryMemory<T[]> &value)
    {
        TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
    }


    /// Assign storage for matrix telemetry values.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the telemetry.
    /// @param  value  The storage for the telemetry value.
    /// @param  pre_function  A function to be called before the value is sent.
    template <typename T>
    void assign_telemetry(const std::string &name, DspTelemetryMemory<T*[]> &value,
                        std::function<void(int, int)> pre_function)
    {
        TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value, pre_function);
    }


    /// Assign storage for matrix telemetry values.
    /// The value is not valid until after the module's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the telemetry.
    /// @param  value  The storage for the telemetry value.
    /// @param  pre_function  A function to be called before the value is sent.
    template <typename T>
    void assign_telemetry(const std::string &name, DspTelemetryMemory<T*[]> &value)
    {
        TelemetryMonitor::get_instance().get_telemetry(this->get_block_name() + "::" + name).assign(value);
    }


private:
    /// Stores the non-real-time data for managing the module.
    DspParamMemory<ModuleMeta> meta;
};


/// Declare an module type that will be stored in the registry of modules.
/// This must be placed at the end of every module class definition.
///
/// @param  module_type  The module class.
#define MODULE_DECLARE(module_type) \
    private: \
        static const bosepro::ChildCreatorImpl<bosepro::Module, module_type, const bosepro::BlockConfiguration &> creator


/// Register an module type in the registry of modules. This must appear
/// in the source file for the module.
///
/// @param  module_type  The module class.
/// @param  module_name  The name use to reference the module.
#define MODULE_REGISTER(module_type, module_name) \
    const bosepro::ChildCreatorImpl<bosepro::Module, module_type, const bosepro::BlockConfiguration &> module_type::creator(module_name)


/// Create a lambda function that calls a member function on this object.
/// This can be used to facilitate creating the post function in 
/// `assign_parameter()` for scalar parameters.
#define POST_FUNCTION_SCALAR(func) \
    [this]() { \
        this->func(); \
    }


/// Create a lambda function that calls a member function on this object.
/// This can be used to facilitate creating the post function in 
/// `assign_parameter()` for vector parameters.
#define POST_FUNCTION_VECTOR(func) \
    [this](int row_index) { \
        this->func(row_index); \
    }


/// Create a lambda function that calls a member function on this object.
/// This can be used to facilitate creating the post function in 
/// `assign_parameter()` for matrix parameters.
#define POST_FUNCTION_MATRIX(func) \
    [this](int row_index, int column_index) { \
        this->func(row_index, column_index); \
    }


} // namespace bosepro
