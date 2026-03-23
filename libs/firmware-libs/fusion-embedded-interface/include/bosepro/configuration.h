#pragma once

#include <bosepro/navigator.h>

#include <sstream>
#include <string>


namespace bosepro {


class SessionConfiguration;
class TaskConfiguration;
class BlockConfiguration;
class PropertyConfiguration;
class TerminalConfiguration;
class BlockConnectionConfiguration;
class TaskConnectionConfiguration;
class TelemetryConfiguration;
class ParameterSetting;


/// A configuration or set of configurations.
class Configuration : public Navigator {
public:
    /// Build the configuration from the given JSON file.  This is used to
    /// load entire configurations from a JSON file.
    ///
    /// @param  filename  The name of a JSON configuration file.
    Configuration(const std::string &filename);


    /// Build the configuration from the given JSON string.  This is used to
    /// create configurations from single JSON command strings.
    ///
    /// @param  ss  A string stream containing a JSON string.
    Configuration(std::stringstream &ss);


    /// Get the configuration for a session.
    ///
    /// @return  The session configuration.
    const SessionConfiguration &get_session() const;


    /// Test whether a list of tasks exists in this configuration.
    ///
    /// @return  True if the configuration contains a list of tasks.
    bool has_audio_tasks() const;


    /// Get the list of tasks in this configuration.
    /// The list of tasks must exist: use `has_tasks()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of tasks.
    const TaskConfiguration &get_audio_tasks() const;


    /// Test whether a list of non-audio tasks exists in this configuration.
    ///
    /// @return  True if the configuration contains a list of tasks.
    bool has_periodic_tasks() const;


    /// Get the list of non-audio tasks in this configuration.
    /// The list of tasks must exist: use `has_tasks()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of tasks.
    const TaskConfiguration &get_periodic_tasks() const;


    /// Test whether list of parameter settings exists in this configuration.
    ///
    /// @return  True if the configuration contains a list of parameter
    ///          settings.
    bool has_parameter_settings() const;


    /// Get the list of parameter settings in this configuration.
    /// The list of parameter settings must exist: use
    /// `has_parameter_settings()` to test whether it exists before calling
    /// this function.
    ///
    /// @return  The list of parameter settings.
    const ParameterSetting &get_parameter_settings() const;


    /// Test whether the configuration has a name specified.
    ///
    /// @return  True if the configuration has a name specified.
    bool has_name() const;


    /// Get the name of this configuration.
    ///
    /// @return  The name of this configuration.
    const std::string &get_name() const;


    /// Get the value of a property or parameter setting.
    ///
    /// @param  value  The value of this property or parameter setting.
    template <typename T>
    void get_value(T &value) const;


    /// Test whether this configuration has property settings.
    ///
    /// @return  True if property settings exist, false otherwise.
    bool has_properties() const;


    /// Test whether this configuration has a property with the given name.
    ///
    /// @param  name  The name of the property.
    /// @return  True if the property exists, false otherwise.
    bool has_property(const std::string &name) const;


    /// Get the configuration for the property with the given name.  The
    /// property must exist: use `has_property()` to test for its existence
    /// before calling this function.
    ///
    /// @param  name  The name of the property.
    /// @return  The property configuration.
    const PropertyConfiguration &get_property(const std::string &name) const;


    /// Get the list of property settings in this configuration.  The list of
    /// properties must exist: use `has_properties()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of property settings.
    const PropertyConfiguration &get_properties() const;


    /// Test whether the configuration has task connections specified.
    ///
    /// @return  True if the configuration has task connections specified.
    bool has_task_connections() const;


    /// Get the list of task connections in this configuration.  The list of
    /// connections must exist: use `has_task_connections()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of task connections.
    const TaskConnectionConfiguration &get_task_connections() const;
};


/// The configuration for a session.
class SessionConfiguration : public Configuration {
public:
};


/// The configuration for a task.
class TaskConfiguration : public Configuration {
public:
    /// Get the list of blocks configured for this task.
    ///
    /// @return  The list of blocks.
    const BlockConfiguration &get_blocks() const;


    /// Test whether the task configuration has block connections specified.
    ///
    /// @return  True if the task configuration has block connections specified.
    bool has_block_connections() const;


    /// Get the list of connections configured for this task.  The list of
    /// connections must exist: use `has_block_connections()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of connections.
    const BlockConnectionConfiguration &get_block_connections() const;
};


/// The configuration for a block.
class BlockConfiguration : public Configuration {
public:
    /// Get the name of the algorithm to use for this block.
    ///
    /// @return  The name of the algorithm.
    const std::string &get_algorithm() const;


    /// Get the name of the algorithm to use for this block.
    ///
    /// @return  The name of the algorithm.
    const std::string &get_module() const;


    /// Get the name of the processor to use for this block.
    ///
    /// @return  The name of the processor.
    const std::string &get_processor() const;


    /// Test whether the block configuration has a terminal of the given name.
    ///
    /// @param  name  The name of the terminal.
    /// @return  True if the block configuration has a terminal of the given
    ///          name, false otherwise.
    bool has_terminal(const std::string &name) const;


    /// Get the terminal configuration for the terminal of the given name.
    /// The terminal configuration must exist: use `has_terminal()` to test
    /// whether it exists before calling this function.
    ///
    /// @param  name  The name of the terminal.
    /// @return  The terminal configuration.
    const TerminalConfiguration &get_terminal(const std::string &name) const;


    /// Test whether the block configuration has any terminals.
    ///
    /// @return  True if the block configuration has any terminals, false
    ///         otherwise.
    bool has_terminals() const;


    /// Get the list of terminal configurations for this block.  The list of
    /// terminals must exist: use `has_terminals()` to test whether it exists
    /// before calling this function.
    ///
    /// @return  The list of terminal configurations.
    const TerminalConfiguration &get_terminals() const;
};


/// The configuration for a property.
class PropertyConfiguration : public Configuration {


};


/// The configuration for a terminal.
class TerminalConfiguration : public Configuration {
public:
    /// Get the number of channels for this terminal.
    ///
    /// @return  The number of channels.
    int get_num_channels() const;
};


/// The configuration for a parameter setting.
class ParameterSetting : public Configuration {
public:
    /// Create the parameter setting from a JSON string.
    ///
    /// @param  ss  A string stream containing the JSON string.
    ParameterSetting(std::stringstream &ss);


    /// Get the name of the target (usually a block) for this parameter setting.
    ///
    /// @return  The name of the target object for the parameter setting.
    const std::string &get_target() const;


    /// Test whether the parameter setting has a value specified.
    bool has_value() const;


    /// Test whether the parameter setting has a row index specified.
    bool has_row() const;


    /// Get the row index for this parameter setting.  If the row is not set,
    /// this function returns 0.
    ///
    /// @return  The row index.
    int get_row() const;


    /// Test whether the parameter setting has a column index specified.
    bool has_column() const;


    /// Get the column index for this parameter setting.  If the column is not
    /// set, this function returns 0.
    ///
    /// @return  The column index.
    int get_column() const;
};


/// The configuration for a signal connection between blocks.
class BlockConnectionConfiguration: public Configuration {
public:
    /// Get the name of the source block for the signal in this connection.
    ///
    /// @return  The name of the source block.
    const std::string &get_source_block() const;


    /// Get the name of the destination block for the signal in this connection.
    ///
    /// @return  The name of the destination block.
    const std::string &get_destination_block() const;


    /// Get the name of the output terminal in the source block for the signal
    /// in this connection.
    ///
    /// @return  The name of the output terminal.
    const std::string &get_output_terminal() const;


    /// Get the name of the input terminal in the destination block for the
    /// signal in this connection.
    ///
    /// @return  The name of the input terminal.
    const std::string &get_input_terminal() const;


    /// Get the index of the output channel in the source block for the signal
    /// in this connection.
    ///
    /// @return  The index of the output channel.
    int get_output_channel() const;


    /// Get the index of the input channel in the destination block for the
    /// signal in this connection.
    ///
    /// @return  The index of the input channel.
    int get_input_channel() const;
};


/// The configuration for a signal connection between tasks.
class TaskConnectionConfiguration: public Configuration {
public:
    /// Get the name of the source task for the signal in this connection.
    ///
    /// @return  The name of the source task.
    const std::string &get_source_task() const;


    /// Get the name of the destination task for the signal in this connection.
    ///
    /// @return  The name of the destination task.
    const std::string &get_destination_task() const;


    /// Get the name of the output block in the source task for the signal
    /// in this connection.
    ///
    /// @return  The name of the output block.
    const std::string &get_output_block() const;


    /// Get the name of the input block in the destination task for the
    /// signal in this connection.
    ///
    /// @return  The name of the input block.
    const std::string &get_input_block() const;


    /// Get the index of the output channel in the output block for the signal
    /// in this connection.
    ///
    /// @return  The index of the output channel.
    int get_output_channel() const;


    /// Get the index of the input channel in the input block for the
    /// signal in this connection.
    ///
    /// @return  The index of the input channel.
    int get_input_channel() const;
};


/// The configuration for telemetry services.
class TelemetryConfiguration : public Configuration {
public:
    TelemetryConfiguration(const std::string& filename);


    /// Get the number of channels for this terminal.
    ///
    /// @return  The number of channels.
    const std::string& get_socket_path() const;
};


} // namespace bosepro
