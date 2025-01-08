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
class ConnectionConfiguration;
class TelemetryConfiguration;
class ParameterSetting;


/// A configuration or set of configurations.
class Configuration : public Navigator {
public:
    /// Build the configuration from the given JSON file.  This is used to
    /// load entire configurations from a JSON file.
    ///
    /// @param  filename  The name of a JSON configuration file.
    Configuration(const std::string &filename)
        : Navigator(filename)
    {
    }


    /// Build the configuration from the given JSON string.  This is used to
    /// create configurations from single JSON command strings.
    ///
    /// @param  ss  A string stream containing a JSON string.
    Configuration(std::stringstream &ss)
        : Navigator(ss)
    {
    }


    /// Get the configuration for a session.
    ///
    /// @return  The session configuration.
    const SessionConfiguration &get_session() const
    {
        return (const SessionConfiguration &)get_member("session");
    }


    /// Test whether a list of tasks exists in this configuration.
    ///
    /// @return  True if the configuration contains a list of tasks.
    bool has_audio_tasks() const
    {
        return has_member("audio_tasks");
    }


    /// Get the list of tasks in this configuration.
    /// The list of tasks must exist: use `has_tasks()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of tasks.
    const TaskConfiguration &get_audio_tasks() const
    {
        return (const TaskConfiguration &)get_member("audio_tasks");
    }


    /// Test whether a list of non-audio tasks exists in this configuration.
    ///
    /// @return  True if the configuration contains a list of tasks.
    bool has_periodic_tasks() const
    {
        return has_member("periodic_tasks");
    }


    /// Get the list of non-audio tasks in this configuration.
    /// The list of tasks must exist: use `has_tasks()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of tasks.
    const TaskConfiguration &get_periodic_tasks() const
    {
        return (const TaskConfiguration &)get_member("periodic_tasks");
    }


    /// Test whether list of parameter settings exists in this configuration.
    ///
    /// @return  True if the configuration contains a list of parameter
    ///          settings.
    bool has_parameter_settings() const
    {
        return has_member("parameter_settings");
    }


    /// Get the list of parameter settings in this configuration.
    /// The list of parameter settings must exist: use
    /// `has_parameter_settings()` to test whether it exists before calling
    /// this function.
    ///
    /// @return  The list of parameter settings.
    const ParameterSetting &get_parameter_settings() const
    {
        return (const ParameterSetting &)get_member("parameter_settings");
    }


    /// Get the name of this configuration.
    ///
    /// @return  The name of this configuration.
    const std::string &get_name() const
    {
        return get_string("name");
    }


    /// Get the value of a property or parameter setting.
    ///
    /// @param  value  The value of this property or parameter setting.
    template <typename T>
    void get_value(T &value) const
    {
        get_member_value("value", value);
    }


    /// Test whether this configuration has a property with the given name.
    ///
    /// @param  name  The name of the property.
    /// @return  True if the property exists, false otherwise.
    bool has_property(const std::string &name) const
    {
        return list_has_member("property_settings", "name", name);
    }


    /// Get the configuration for the property with the given name.  The
    /// property must exist: use `has_property()` to test for its existence
    /// before calling this function.
    ///
    /// @param  name  The name of the property.
    /// @return  The property configuration.
    const PropertyConfiguration &get_property(const std::string &name) const
    {
        return (const PropertyConfiguration &)list_get_member("property_settings",
                                                              "name", name);
    }
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
    const BlockConfiguration &get_blocks() const
    {
        return (const BlockConfiguration &)get_member("blocks");
    }


    /// Test whether the task configuration has block connections specified.
    ///
    /// @return  True if the task configuration has block connections specified.
    bool has_block_connections() const
    {
        return has_member("block_connections");
    }


    /// Get the list of connections configured for this task.  The list of
    /// connections must exist: use `has_block_connections()` to test whether it
    /// exists before calling this function.
    ///
    /// @return  The list of connections.
    const ConnectionConfiguration &get_block_connections() const
    {
        return (const ConnectionConfiguration &)get_member("block_connections");
    }
};


/// The configuration for a block.
class BlockConfiguration : public Configuration {
public:
    /// Get the name of the algorithm to use for this block.
    ///
    /// @return  The name of the algorithm.
    const std::string &get_algorithm() const
    {
        return get_string("algorithm");
    }


    /// Get the name of the algorithm to use for this block.
    ///
    /// @return  The name of the algorithm.
    const std::string &get_module() const
    {
        return get_string("module");
    }


    /// Test whether the block configuration has a terminal of the given name.
    ///
    /// @param  name  The name of the terminal.
    /// @return  True if the block configuration has a terminal of the given
    ///          name, false otherwise.
    bool has_terminal(const std::string &name) const
    {
        return list_has_member("terminal_channels", "name", name);
    }


    /// Get the terminal configuration for the terminal of the given name.
    /// The terminal configuration must exist: use `has_terminal()` to test
    /// whether it exists before calling this function.
    ///
    /// @param  name  The name of the terminal.
    /// @return  The terminal configuration.
    const TerminalConfiguration &get_terminal(const std::string &name) const
    {
        return (TerminalConfiguration &)list_get_member("terminal_channels",
                                                        "name", name);
    }
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
    int get_num_channels() const
    {
        return get_count("channels");
    }
};


/// The configuration for a parameter setting.
class ParameterSetting : public Configuration {
public:
    /// Create the parameter setting from a JSON string.
    ///
    /// @param  ss  A string stream containing the JSON string.
    ParameterSetting(std::stringstream &ss)
        : Configuration(ss)
    {
    }


    /// Get the name of the target (usually a block) for this parameter setting.
    ///
    /// @return  The name of the target object for the parameter setting.
    const std::string &get_target() const
    {
        return get_string("target");
    }


    /// Get the row index for this parameter setting.  If the row is not set,
    /// this function returns 0.
    ///
    /// @return  The row index.
    int get_row() const
    {
        int row;
        get_list_value("index", 0, row);
        return row - 1;
    }


    /// Get the column index for this parameter setting.  If the column is not
    /// set, this function returns 0.
    ///
    /// @return  The column index.
    int get_column() const
    {
        int column;
        get_list_value("index", 1, column);
        return column - 1;
    }
};


/// The configuration for a signal connection.
class ConnectionConfiguration: public Configuration {
public:
    /// Get the name of the source block for the signal in this connection.
    ///
    /// @return  The name of the source block.
    const std::string &get_source_block() const
    {
        return get_string("source_block");
    }


    /// Get the name of the destination block for the signal in this connection.
    ///
    /// @return  The name of the destination block.
    const std::string &get_destination_block() const
    {
        return get_string("destination_block");
    }


    /// Get the name of the output terminal in the source block for the signal
    /// in this connection.
    ///
    /// @return  The name of the output terminal.
    const std::string &get_output_terminal() const
    {
        return get_string("output_terminal");
    }


    /// Get the name of the input terminal in the destination block for the
    /// signal in this connection.
    ///
    /// @return  The name of the input terminal.
    const std::string &get_input_terminal() const
    {
        return get_string("input_terminal");
    }


    /// Get the index of the output channel in the source block for the signal
    /// in this connection.
    ///
    /// @return  The index of the output channel.
    int get_output_channel() const
    {
        return get_index("output_channel");
    }


    /// Get the index of the input channel in the destination block for the
    /// signal in this connection.
    ///
    /// @return  The index of the input channel.
    int get_input_channel() const
    {
        return get_index("input_channel");
    }
};


/// The configuration for telemetry services.
class TelemetryConfiguration : public Configuration {
public:
    TelemetryConfiguration(const std::string& filename)
        : Configuration(filename)
    {
    }
    
    /// Get the number of channels for this terminal.
    ///
    /// @return  The number of channels.
    const std::string& get_socket_path() const
    {
        TelemetryConfiguration &socket_path((TelemetryConfiguration &)list_get_member("telemetry_configuration",
                                                        "name", "socket_path"));
        return socket_path.get_string("property");
    }
};


} // namespace bosepro
