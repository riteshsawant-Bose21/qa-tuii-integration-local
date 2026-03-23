#pragma once

#include <bosepro/child_factory.h>
#include <bosepro/configurable.h>
#include <bosepro/configuration.h>
#include <bosepro/parameter.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/terminal.h>

#include <cstdint>
#include <functional>
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
    std::string block_name;
    std::string algorithm_name;
};


/// A base class for all signal proessing algorithms.
class Algorithm : public Configurable {
public:
    /// Create an algorithm object based on the configuration for a block.
    ///
    /// @param  configuration  The configuration to use for the algorithm.
    Algorithm(const BlockConfiguration &configuration);


    virtual ~Algorithm();


    /// Process one frame of audio. Every algorithm must implement this.
    virtual void process() = 0;


    /// Return the name of this block.
    const std::string &get_block_name() const;


    /// Return the name of this algorithm.
    const std::string &get_algorithm_name() const;


    /// Allocate buffers for all of the terminals.  This is called by the
    /// framework, not by the algorithm.
    void initialize_terminals();


    /// Get a reference to a terminal by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the terminal.
    /// @return  A reference to the terminal.
    Terminal &get_terminal(const std::string &name);


    /// Connect a terminal to another terminal.  This is called by the
    /// framework, not by the algorithm.
    ///
    /// @param  name  The name of the input terminal in this block.
    /// @param  input_channel  The channel of the input terminal.
    /// @param  output_terminal  The terminal to connect to.
    /// @param  output_channel  The channel of the output terminal.
    void connect_terminal(const std::string &name, int input_channel,
                          Terminal &output_terminal, int output_channel);


    /// Get the largest frame size of any empty (unconnected) input terminal in
    /// this block.  This is called by the framework, not by the algorithm.
    int get_empty_frame_size() const;


    /// Connect any unconnected input terminals to the provided signal memory.
    /// This is called by the framework, not by the algorithm.
    void set_empty_signal(DspSignalMemory<const float[]> &signal_memory);


    /// Get a reference to a parameter by name.  This is called by the framework,
    /// not by the algorithm.
    ///
    /// @param  name  The name of the parameter.
    /// @return  A reference to the parameter.
    Parameter &get_parameter(const std::string &name);


    /// Initialize all of the parameters.  This is called by the framework,
    /// not by the algorithm.  This will allocate storage for the parameter
    /// values, and set them to their defaults.  Then, if any parameter settings
    /// are present in the configuration, they will be applied.
    void initialize_parameters();


    /// Set a parameter value.  This is called by the framework, not by the
    /// algorithm.
    ///
    /// @param  setting  The setting to apply.
    /// @return  True if the setting was applied, false if the parameter was
    ///          not found.
    bool set_parameter(const ParameterSetting &setting);


    /// For any output terminals that have default gain, bypass, or telemetry,
    /// process the output after the algorithm has finished processing.
    inline void process_outputs()
    {
        for (int top_index = 0; top_index < output_process_count; top_index++)
        {
            outputs_to_process[top_index].process();
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
    void get_property(const std::string &name, T &value);


    /// Get the number of channels for a terminal from the configuration.
    /// If this number of channels is not specified in the configuration, the
    /// default value from the parameter definition is used.
    ///
    /// @param  name  The name of the terminal.
    /// @param  num_channels  The number of channels for the terminal.
    void get_terminal_num_channels(const std::string &name, int &num_channels);


    /// Assign signal memory to a single-channel input terminal.
    /// The terminal will not be connected until after the algorithm's
    /// constructor (but before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<const T[]> &signal_memory);


    /// Assign signal memory to a multi-channel input terminal.
    /// The terminal channels will not be connected until after the algorithm's
    /// constructor (but before `process()` is called).
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<const T*[]> &signal_memory);


    /// Assign signal memory to a single-channel output terminal.
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<T[]> &signal_memory);


    /// Assign signal memory to a multi-channel output terminal.
    ///
    /// @param  name  The name of the terminal.
    /// @param  signal_memory  The signal memory to assign to the terminal.
    template <typename T>
    void assign_terminal(const std::string &name,
                         DspSignalMemory<T*[]> &signal_memory);


    /// Assign storage for a scalar parameter value that is a coefficient that
    /// can used directly by the algorithm without conversion.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, T *value);


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
                          T (*conversion_function)(T));


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
                          std::function<void()> post_function);


    /// Assign storage for vector parameter values that are coefficients that
    /// can used directly by the algorithm without conversion.
    /// The values are not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T[]> &value);


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
                          T (*conversion_function)(T));


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
                          std::function<void(int)> post_function);


    /// Assign storage for matrix parameter values that are coefficients that
    /// can used directly by the algorithm without conversion.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the parameter.
    /// @param  value  The storage for the parameter value.
    template <typename T>
    void assign_parameter(const std::string &name, DspCoeffMemory<T*[]> &value);


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
                          T (*conversion_function)(T));


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
                          std::function<void(int, int)> post_function);


    /// Assign storage for a scalar meter value.
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_telemetry(const std::string &name, const T *value);


    /// Assign storage for a scalar meter value, along with a conversion
    /// function to convert the value from its internal representation to a
    /// user-facing value.  For example, `linear_to_db()` in `conversion.h`
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    /// @param  conversion_function  An function to be called to convert the
    ///                              value before meter data is sent.
    template <typename T>
    void assign_telemetry(const std::string &name, const T *value,
                          T (*conversion_function)(T));


    /// Assign storage for vector meter values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_telemetry(const std::string &name,
                          DspTelemetryMemory<T[]> &value);


    /// Assign storage for vector meter values, along with a conversion
    /// function to convert the value from its internal representation to a
    /// user-facing value.  For example, `linear_to_db()` in `conversion.h`
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    /// @param  conversion_function  An function to be called to convert the
    ///                              value before meter data is sent.
    template <typename T>
    void assign_telemetry(const std::string &name,
                          DspTelemetryMemory<T[]> &value,
                          T (*conversion_function)(T));


    /// Assign storage for matrix meter values.
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    template <typename T>
    void assign_telemetry(const std::string &name,
                          DspTelemetryMemory<T*[]> &value);


    /// Assign storage for matrix meter values, along with a conversion
    /// function to convert the value from its internal representation to a
    /// user-facing value.  For example, `linear_to_db()` in `conversion.h`
    /// The value is not valid until after the algorithm's constructor (but
    /// before `process()` is called).
    ///
    /// @param  name  The name of the meter.
    /// @param  value  The storage for the meter value.
    /// @param  conversion_function  An function to be called to convert the
    ///                              value before meter data is sent.
    template <typename T>
    void assign_telemetry(const std::string &name,
                          DspTelemetryMemory<T*[]> &value,
                          T (*conversion_function)(T));


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
