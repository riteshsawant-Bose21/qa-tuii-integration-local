#pragma once

#include <bosepro/child_factory.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/conversion.h>
#include <bosepro/parameter.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/telemetry.h>
#include <bosepro/terminal.h>

#include <cstdint>
#include <functional>
#include <list>
#include <map>
#include <memory>
#include <string>


namespace bosepro {


/// A structure for managing the non-real-time data of an algorithm.  This
/// helps manage cache performance, keeping the real-time data more localized.
struct AlgorithmMeta {
    const AlgorithmDefinition *definition;
    const BlockConfiguration *configuration;
    std::map<std::string, std::unique_ptr<Terminal>> terminals;
    std::map<std::string, std::unique_ptr<Parameter>> parameters;
    std::map<std::string, std::unique_ptr<Telemetry>> telemetry;
};


/// A base class for all signal proessing algorithms.
class Algorithm : public Configurable {
public:
    /// Create an algorithm object based on the configuration for a block.
    ///
    /// @param  configuration  The configuration to use for the algorithm.
    Algorithm(const BlockConfiguration &configuration)
        : Configurable(configuration), 
          telemetry_callback(nullptr),
          event_telemetry_callback(nullptr),
          output_process_count(0)
    {
        meta->configuration = &configuration;
        meta->definition = static_cast<const AlgorithmDefinition*>(get_definition(configuration.get_algorithm()));

        // There is no need to create property data, because we just look it
        // up from the algorithm's property definitions and the configuration.

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
                std::make_unique<Terminal>(Terminal(td, meta->configuration, get_frame_size()));
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
            for (auto &m: meta->definition->get_telemetry())
            {
                const TelemetryDefinition &md =
                    reinterpret_cast<const TelemetryDefinition &>(m.second);
                const std::string &name = md.get_name();

                meta->telemetry[name] =
                    std::unique_ptr<Telemetry>(Telemetry::create(md,
                                                                 static_cast<const ProcessorDefinition&>(*meta->definition),
                                                                 meta->configuration));
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
                const std::string telemetry_name = name + "_telemetry";

                if ((meta->parameters.count(gain_name) != 0)
                    || (meta->parameters.count(mute_name) != 0)
                    || (meta->telemetry.count(telemetry_name) != 0)
                    || (td.has_bypass_source()
                        && (meta->parameters.count("bypass") != 0)))
                {
                    output_process_count++;
                }
            }
        }

        outputs_to_process.resize(output_process_count);
        int top_index = 0;

        // Assign universal parameters and telemetry to the associated output
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
                const std::string telemetry_name = name + "_telemetry";
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

                if (meta->telemetry.count(telemetry_name) != 0)
                {
                    assign_telemetry(telemetry_name, top.get_telemetry());
                    requires_processing = true;
                }

                if (td.has_bypass_source()
                    && meta->parameters.count("bypass") != 0)
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


    virtual ~Algorithm() = default;


    /// Process one frame of audio. Every algorithm must implement this.
    virtual void process() = 0;


    /// Return the name of this block.
    const std::string &get_block_name() const
    {
        return meta->configuration->get_name();
    }


    /// Return the name of this algorithm.
    const std::string &get_algorithm_name() const
    {
        return meta->configuration->get_algorithm();
    }


    /// Allocate buffers for all of the terminals.  This is called by the
    /// framework, not by the algorithm.
    void initialize_terminals()
    {
        SPDLOG_TRACE("Initializing terminals for '{}'.",
                     meta->configuration->get_algorithm());

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


    /// Get a reference to a terminal by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the terminal.
    /// @return  A reference to the terminal.
    Terminal &get_terminal(const std::string &name)
    {
        if (meta->terminals.count(name) == 0)
        {
            SPDLOG_CRITICAL("Unknown terminal '{}' in '{}'.",
                            name, meta->configuration->get_algorithm());
        }

        return *meta->terminals[name];
    }


    /// Connect a terminal to another terminal.  This is called by the
    /// framework, not by the algorithm.
    ///
    /// @param  name  The name of the input terminal in this block.
    /// @param  input_channel  The channel of the input terminal.
    /// @param  output_terminal  The terminal to connect to.
    /// @param  output_channel  The channel of the output terminal.
    void connect_terminal(const std::string &name, int input_channel,
                          Terminal &output_terminal, int output_channel)
    {
        meta->terminals[name]->connect(input_channel, output_terminal,
                                       output_channel);
    }


    /// Get a reference to a parameter by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the parameter.
    /// @return  A reference to the parameter.
    Parameter &get_parameter(const std::string &name)
    {
        if (meta->parameters.count(name) == 0)
        {
            SPDLOG_CRITICAL("Unknown parameter '{}' in '{}'.",
                            name, meta->configuration->get_algorithm());
        }

        return *meta->parameters[name];
    }


    /// Initialize all of the parameters.  This is called by the framework,
    /// not by the algorithm.  This will allocate storage for the parameter
    /// values, and set them to their defaults.  Then, if any parameter settings
    /// are present in the configuration, they will be applied.
    void initialize_parameters()
    {
        SPDLOG_TRACE("Initializing parameters for '{}'.",
                     meta->configuration->get_algorithm());

        for (auto &c : meta->parameters)
        {
            c.second->initialize_post();
        }
    }


    /// Set a parameter value.  This is called by the framework, not by the
    /// algorithm.
    ///
    /// @param  setting  The setting to apply.
    /// @return  True if the setting was applied, false if the parameter was
    ///          not found.
    bool set_parameter(const ParameterSetting &setting)
    {
        if (meta->parameters.count(setting.get_name()) == 0)
        {
            SPDLOG_WARN("Unknown parameter '{}' in '{}'.", setting.get_name(),
                        meta->configuration->get_algorithm());
            return false;
        }

        get_parameter(setting.get_name()).set(setting);

        return true;
    }


    void set_telemetry_callbacks(void (*telemetry_callback)(const std::string &), void (*event_telemetry_callback)(const std::string &))
    {
        this->telemetry_callback = telemetry_callback;
        this->event_telemetry_callback = event_telemetry_callback;
    }


    /// Get a reference to a meter by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the meter.
    /// @return  A reference to the meter.
    Telemetry &get_telemetry(const std::string &name)
    {
        if (meta->telemetry.count(name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}' in '{}'.",
                            name, meta->configuration->get_algorithm());
        }

        return *meta->telemetry[name];
    }


    /// Initialize all of the telemetry.  This is called by the framework,
    /// not by the algorithm. This will allocate storage for the telemetry values.
    void initialize_telemetry()
    {
        SPDLOG_TRACE("Initializing telemetry for '{}'.",
                     meta->configuration->get_algorithm());

        for (auto &m : meta->telemetry)
        {
            m.second->initialize();
        }
    }


    /// For any output terminals that have default gain, bypass, or telemetry,
    /// process the output after the algorithm has finished processing.
    void process_outputs()
    {
        for (int top_index = 0; top_index < output_process_count; top_index++)
        {
            outputs_to_process[top_index].process();
        }
    }


    /// Send telemetry data for all of the telemetry in this block.
    size_t get_telemetry_size()
    {
        size_t size = 0;
        for (auto &m : meta->telemetry)
        {
            if (m.second->get_telemetry_type() != "event")
            {
                size += m.second->get_telemetry_size();
            }
        }

        return size;
    }


    /// Send telemetry data for all of the telemetry in this block.
    void send_telemetry()
    {
        if(telemetry_callback)
        {
            for (auto &m : meta->telemetry)
            {
                if (m.second->get_telemetry_type() != "event")
                {
                    m.second->pre_process();
                    m.second->send(telemetry_callback);
                }
            }
        }
    }


    /// Send telemetry data for a specific event
    ///
    /// @param  name  The name of the telemetry object
    void send_event_telemetry(const std::string &name)
    {
        if(event_telemetry_callback)
        {
            auto &m = get_telemetry(name);
            if (m.get_telemetry_type() == "event") 
            {
                m.pre_process();
                m.send(event_telemetry_callback);
            }
        }
    }


protected:
    /// Get the value of a property from the configuration.  If this property
    /// is not specified in the configuration, the default value from the
    /// parameter definition is used.
    ///
    /// @param  name  The name of the property.
    /// @param  value  The value of the property.
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
                            name, meta->configuration->get_algorithm());
        }
    }


    /// Get the number of channels for a terminal from the configuration.
    /// If this number of channels is not specified in the configuration, the
    /// default value from the parameter definition is used.
    ///
    /// @param  name  The name of the terminal.
    /// @param  num_channels  The number of channels for the terminal.
    void get_terminal_num_channels(const std::string &name, int &num_channels)
    {
        num_channels = get_terminal(name).get_num_channels();
    }


    /// Assign signal memory to a single-channel input terminal.
    /// The terminal will not be connected until after the algorithm's
    /// constructor (but before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<const T[]> &signal_memory)
    {
        get_terminal(name).assign(signal_memory);
    }


    /// Assign signal memory to a multi-channel input terminal.
    /// The terminal channels will not be connected until after the algorithm's
    /// constructor (but before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<const T*[]> &signal_memory)
    {
        get_terminal(name).assign(signal_memory);
    }


    /// Assign signal memory to a single-channel output terminal.
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<T[]> &signal_memory)
    {
        get_terminal(name).assign(signal_memory);
    }


    /// Assign signal memory to a multi-channel output terminal.
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<T*[]> &signal_memory)
    {
        get_terminal(name).assign(signal_memory);
    }


    /// Assign storage for a scalar parameter value that is a coefficient that
    /// can used directly by the algorithm without conversion.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, T *value)
    {
        get_parameter(name).assign(value);
    }


    /// Assign storage for a scalar parameter value.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `conversion_function()` is called to convert the value from its
    /// user-facing value to an internal representation.  For example,
    /// `db_to_linear()` in `conversion.h` can be used to convert the value
    /// from dB to linear gain.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  conversion_function  An function to be called to convert the
    ///             value before it is set.
    template <typename T>
    void assign_parameter(const std::string &name, T *value,
                          T (*conversion_function)(T))
    {
        get_parameter(name).assign(value, conversion_function);
    }


    /// Assign storage for a scalar parameter value that is intermediate and
    /// not used in real-time.  The post function is used to update the
    /// algorithm's coefficients with values derived from the parameter value.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_SCALAR()` can be used to facilitate creating the
    /// `post_function` argument from a member function, if needed.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign_parameter(const std::string &name, T *value,
                          std::function<void()> post_function)
    {
        get_parameter(name).assign(value, post_function);
    }


    /// Assign storage for vector parameter values that are coefficients that
    /// can used directly by the algorithm without conversion.
    /// The values are not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T[]> &value)
    {
        get_parameter(name).assign(value);
    }


    /// Assign storage for vector parameter values.
    /// The values are not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `conversion_function()` is called to convert the value from its
    /// user-facing value to an internal representation.  For example,
    /// `db_to_linear()` in `conversion.h` can be used to convert the value
    /// from dB to linear gain.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  conversion_function  An function to be called to convert the
    ///             value before it is set.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T[]> &value,
                          T (*conversion_function)(T))
    {
        get_parameter(name).assign(value, conversion_function);
    }


    /// Assign storage for vector parameter values that are intermediate and
    /// not used in real-time.  The post function is used to update the
    /// algorithm's coefficients with values derived from the parameter value.
    /// The values are not valid until after the algorithm's constructor (but
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
    /// can used directly by the algorithm without conversion.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T*[]> &value)
    {
        get_parameter(name).assign(value);
    }


    /// Assign storage for matrix parameter values that are coefficients that
    /// can used directly by the algorithm without conversion.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `conversion_function()` is called to convert the value from its
    /// user-facing value to an internal representation.  For example,
    /// `db_to_linear()` in `conversion.h` can be used to convert the value
    /// from dB to linear gain.
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    /// @param  conversion_function  An function to be called to convert the
    ///             value before it is set.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T*[]> &value,
                          T (*conversion_function)(T))
    {
        get_parameter(name).assign(value, conversion_function);
    }


    /// Assign storage for matrix parameter values that are intermediate and
    /// not used in real-time.  The post function is used to update the
    /// algorithm's coefficients with values derived from the parameter value.
    /// The value is not valid until after the algorithm's constructor (but
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


    /// Assign storage for a scalar meter value.
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_telemetry(const std::string &name, const T *value)
    {
        get_telemetry(name).assign(value);
    }


    /// Assign storage for vector meter values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_telemetry(const std::string &name, DspTelemetryMemory<T[]> &value)
    {
        get_telemetry(name).assign(value);
    }


    /// Assign storage for matrix meter values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_telemetry(const std::string &name, DspTelemetryMemory<T*[]> &value)
    {
        get_telemetry(name).assign(value);
    }


    void (*telemetry_callback)(const std::string &message);
    void (*event_telemetry_callback)(const std::string &message);


private:
    /// Stores the non-real-time data for managing the algorithm.
    DspParamMemory<AlgorithmMeta> meta;
    DspStateMemory<TerminalOutputProcessor[]> outputs_to_process;
    int output_process_count;
};


/// Declare an algorithm type that will be stored in the registry of algorithms.
/// This must be placed at the end of every algorithm class definition.
///
/// @param  algorithm_type  The algrithm class.
#define ALGORITHM_DECLARE(algorithm_type) \
    private: \
        static const bosepro::ChildCreatorImpl<bosepro::Algorithm, algorithm_type, const bosepro::BlockConfiguration &> creator


/// Register an algorithm type in the registry of algorithms. This must appear
/// in the source file for the algorithm.
///
/// @param  algorithm_type  The algorithm class.
/// @param  algorithm_name  The name use to reference the algorithm.
#define ALGORITHM_REGISTER(algorithm_type, algorithm_name) \
    const bosepro::ChildCreatorImpl<bosepro::Algorithm, algorithm_type, const bosepro::BlockConfiguration &> algorithm_type::creator(algorithm_name)


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
