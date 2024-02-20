#pragma once

#include <bosepro/child_factory.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/control.h>
#include <bosepro/meter.h>
#include <bosepro/parameters.h>
#include <bosepro/terminal.h>

#include <cstdint>
#include <functional>
#include <list>
#include <map>
#include <memory>
#include <string>
#include <vector>


namespace bosepro {


/// A structure for managing the non-real-time data of an algorithm.  This will
/// eventually help manage cache performance, keeping the real-time data more
/// localized.
struct AlgorithmMeta {
    const AlgorithmParameters *parameters;
    const BlockConfiguration *configuration;
    std::map<std::string, std::unique_ptr<Terminal>> terminals;
    std::map<std::string, std::unique_ptr<Control>> controls;
    std::map<std::string, std::unique_ptr<Meter>> meters;
};


/// A base class for all signal proessing algorithms.
class Algorithm : public Configurable {
public:
    /// Create an algorithm object based on the configuration for a block.
    ///
    /// @param  configuration  The configuration to use for the algorithm.
    Algorithm(const BlockConfiguration &configuration)
        : Configurable(configuration)
    {
        meta = std::unique_ptr<AlgorithmMeta>(new AlgorithmMeta());
        meta->configuration = &configuration;
        meta->parameters = get_parameters(configuration.get_algorithm());

        // There is no need to create constant data, because we just look it
        // up from the parameter definitions and configuration.

        // Create the terminal data for all of the terminals in the algorithm.
        // We use the parameters rather than the configuration, because the
        // configuration may not contain terminal settings if the number of
        // channels is fixed or set to the default.
        // We assume there must be terminals for all algorithms.
        for (auto &t : meta->parameters->get_terminals())
        {
            const TerminalParameter &tp =
                    reinterpret_cast<const TerminalParameter &>(t.second);
            const std::string &name = tp.get_name();
            const TerminalConfiguration *tc =
                configuration.has_terminal(name) ?
                &configuration.get_terminal(tp.get_name()) : nullptr;
            meta->terminals[name] =
                std::unique_ptr<Terminal>(new Terminal(tp, tc,
                                                       get_frame_size()));
        }

        // Create the control data for all of the controls in the algorithm.
        if (meta->parameters->has_controls())
        {
            for (auto &c: meta->parameters->get_controls())
            {
                const ControlParameter &cp =
                    reinterpret_cast<const ControlParameter &>(c.second);
                const std::string &name = cp.get_name();
                const ControlConfiguration *cc =
                    configuration.has_control(name) ?
                    &configuration.get_control(name) : nullptr;

                meta->controls[name] =
                    std::unique_ptr<Control>(Control::create(cp, cc));
            }
        }

        // Create the meter data for all of the meters in the algorithm.
        if (meta->parameters->has_meters())
        {
            for (auto &m: meta->parameters->get_meters())
            {
                const MeterParameter &mp =
                    reinterpret_cast<const MeterParameter &>(m.second);
                const std::string &name = mp.get_name();
                const MeterConfiguration *mc =
                    configuration.has_meter(name) ?
                    &configuration.get_meter(name) : nullptr;

                meta->meters[name] =
                    std::unique_ptr<Meter>(Meter::create(mp, mc));
            }
        }


        // Assign universal controls and meters to the associated output
        // terminals.
        for (auto &t : meta->parameters->get_terminals())
        {
            const TerminalParameter &tp =
                    reinterpret_cast<const TerminalParameter &>(t.second);
            const std::string &name = tp.get_name();
            Terminal &terminal = *meta->terminals[name];

            if (terminal.is_output())
            {
                const std::string gain_name = name + "_gain";
                const std::string mute_name = name + "_mute";
                const std::string meter_name = name + "_meter";
                bool requires_processing = false;

                if (meta->controls.count(gain_name) != 0)
                {
                    assign_control(gain_name, terminal.get_gain());
                    requires_processing = true;
                }

                if (meta->controls.count(mute_name) != 0)
                {
                    assign_control(mute_name, terminal.get_mute());
                    requires_processing = true;
                }

                if (meta->meters.count(meter_name) != 0)
                {
                    assign_meter(meter_name, terminal.get_meter());
                    requires_processing = true;
                }

                if (tp.has_bypass_source()
                    && meta->controls.count("bypass") != 0)
                {
                    assign_control("bypass", terminal.get_bypass());
                    terminal.set_bypass_source(
                        meta->terminals[tp.get_bypass_source()].get());
                    requires_processing = true;
                }

                if (requires_processing)
                {
                    outputs_to_process.push_back(&terminal);
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


    /// Get a reference to a control by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the control.
    /// @return  A reference to the control.
    Control &get_control(const std::string &name)
    {
        if (meta->controls.count(name) == 0)
        {
            SPDLOG_CRITICAL("Unknown control '{}' in '{}'.",
                            name, meta->configuration->get_algorithm());
        }

        return *meta->controls[name];
    }


    /// Initialize all of the controls.  This is called by the framework,
    /// not by the algorithm.  This will allocate storage for the control
    /// values, and set them to their defaults.  Then, if any control settings
    /// are present in the configuration, they will be applied.
    void initialize_controls()
    {
        SPDLOG_TRACE("Initializing controls for '{}'.",
                     meta->configuration->get_algorithm());

        for (auto &c : meta->controls)
        {
            c.second->initialize();
        }

        for (auto &c : meta->controls)
        {
            c.second->initialize_post();
        }

        if (meta->configuration->has_control_settings())
        {
            for (auto &s: meta->configuration->get_control_settings())
            {
                const ControlSetting &cs =
                    reinterpret_cast<const ControlSetting &>(s.second);
                set_control(cs);
            }
        }
    }


    /// Set a control value.  This is called by the framework, not by the
    /// algorithm.
    ///
    /// @param  setting  The setting to apply.
    /// @return  True if the setting was applied, false if the control was
    ///          not found.
    bool set_control(const ControlSetting &setting)
    {
        if (meta->controls.count(setting.get_name()) == 0)
        {
            SPDLOG_WARN("Unknown control '{}' in '{}'.", setting.get_name(),
                        meta->configuration->get_algorithm());
            return false;
        }

        get_control(setting.get_name()).set(setting);

        return true;
    }


    /// Get a reference to a meter by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the meter.
    /// @return  A reference to the meter.
    Meter &get_meter(const std::string &name)
    {
        if (meta->meters.count(name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}' in '{}'.",
                            name, meta->configuration->get_algorithm());
        }

        return *meta->meters[name];
    }


    /// Initialize all of the meters.  This is called by the framework,
    /// not by the algorithm. This will allocate storage for the meter values.
    void initialize_meters()
    {
        SPDLOG_TRACE("Initializing meters for '{}'.",
                     meta->configuration->get_algorithm());

        for (auto &m : meta->meters)
        {
            m.second->initialize();
        }
    }


    /// For any output terminals that have default gain, bypass, or meters,
    /// process the output after the algorithm has finished processing.
    void process_outputs()
    {
        for (auto &t : outputs_to_process)
        {
            t->process_output();
        }
    }


protected:
    /// Get the value of a constant from the configuration.  If this constant
    /// is not specified in the configuration, the default value from the
    /// parameter definition is used.
    ///
    /// @param  name  The name of the constant.
    /// @param  value  The value of the constant.
    template <typename T>
    void get_constant(const std::string &name, T &value)
    {
        if (meta->configuration->has_constant(name))
        {
            meta->configuration->get_constant(name).get_value(value);
        }
        else if (meta->parameters->has_constant(name))
        {

            meta->parameters->get_constant(name).get_default_value(value);
        }
        else
        {
            SPDLOG_CRITICAL("Unknown constant '{}' in '{}'.",
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


    /// Assign a buffer pointer to a single-channel input terminal.
    /// The buffer is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  buffer  The buffer pointer to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name, const T **buffer)
    {
        get_terminal(name).assign(buffer);
    }


    /// Assign a buffer pointer to a multi-channel input terminal.
    /// The buffer is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  buffer  The buffer pointer to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name, std::vector<const T *> *buffer)
    {
        get_terminal(name).assign(buffer);
    }


    /// Assign a buffer pointer to a single-channel output terminal.
    /// The buffer is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  buffer  The buffer pointer to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name, T **buffer)
    {
        get_terminal(name).assign(buffer);
    }


    /// Assign buffer pointer to a multi-channel output terminal.
    /// The buffer is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  buffer  The buffer pointer to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name, std::vector<T *> *buffer)
    {
        get_terminal(name).assign(buffer);
    }


    /// Assign storage for a scalar control value.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_SCALAR()` can be used to facilitate creating the
    /// `post_function` argument from a member function, if needed.
    ///
    /// @param  name  The name of the control.
    /// @param  value  The storage for the control value.
    /// @param  post_function  An optional function to be called after the value
    ///                        is set.
    template <typename T>
    void assign_control(const std::string &name, T *value,
                        std::function<void()> post_function = nullptr)
    {
        get_control(name).assign(value, post_function);
    }


    /// Assign storage for vector control values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_VECTOR()` can be used to facilitate creating the
    /// `post_function` argument from a member function, if needed.
    ///
    /// @param  name  The name of the control.
    /// @param  value  The storage for the control value.
    /// @param  post_function  An optional function to be called after the value
    ///                        is set.
    template <typename T>
    void assign_control(const std::string &name, std::vector<T> *value,
                        std::function<void(int)> post_function = nullptr)
    {
        get_control(name).assign(value, post_function);
    }


    /// Assign storage for matrix control values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    /// `POST_FUNCTION_MATRIX()` can be used to facilitate creating the
    /// `post_function` argument from a member function, if needed.
    ///
    /// @param  name  The name of the control.
    /// @param  value  The storage for the control value.
    /// @param  post_function  An optional function to be called after the value
    ///                        is set.
    template <typename T>
    void assign_control(const std::string &name,
                        std::vector<std::vector<T>> *value,
                        std::function<void(int, int)> post_function = nullptr)
    {
        get_control(name).assign(value, post_function);
    }


    /// Assign storage for a scalar meter value.
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_meter(const std::string &name, const T *value)
    {
        get_meter(name).assign(value);
    }


    /// Assign storage for vector meter values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_meter(const std::string &name, std::vector<T> *value)
    {
        get_meter(name).assign(value);
    }


    /// Assign storage for matrix meter values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_meter(const std::string &name,
                      std::vector<std::vector<T>> *value)
    {
        get_meter(name).assign(value);
    }


private:
    /// Stores the non-real-time data for managing the algorithm.
    std::unique_ptr<AlgorithmMeta> meta;
    std::list<Terminal *> outputs_to_process;
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
/// `assign_control()` for scalar controls.
#define POST_FUNCTION_SCALAR(func) \
    [this]() { \
        this->func(); \
    }


/// Create a lambda function that calls a member function on this object.
/// This can be used to facilitate creating the post function in 
/// `assign_control()` for vector controls.
#define POST_FUNCTION_VECTOR(func) \
    [this](int row_index) { \
        this->func(row_index); \
    }


/// Create a lambda function that calls a member function on this object.
/// This can be used to facilitate creating the post function in 
/// `assign_control()` for matrix controls.
#define POST_FUNCTION_MATRIX(func) \
    [this](int row_index, int column_index) { \
        this->func(row_index, column_index); \
    }


} // namespace bosepro
