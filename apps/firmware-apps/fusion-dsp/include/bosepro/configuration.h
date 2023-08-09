#pragma once

#include <bosepro/property.h>

#include <string>


namespace bosepro {


class SessionConfiguration;
class TaskConfiguration;
class BlockConfiguration;
class ConstantConfiguration;
class TerminalConfiguration;
class ControlConfiguration;
class MeterConfiguration;
class ConnectionConfiguration;
class ControlSetting;


/// A configuration or set of configurations.
class Configuration : public PropertyNavigator {
public:
    /// Build the configuration from the given JSON file.
    Configuration(const std::string &filename)
        : PropertyNavigator(filename)
    {
    }


    /// Get the configuration for a session.
    ///
    /// @return  The session configuration.
    const SessionConfiguration &get_session() const
    {
        return (const SessionConfiguration &)get_member("session");
    }


    /// Get the name of this configuration.
    ///
    /// @return  The name of this configuration.
    const std::string &get_name() const
    {
        return get_string("name");
    }


    /// Get the value of a constant or control setting.
    ///
    /// @param  value  The value of this constant or control setting.
    template <typename T>
    void get_value(T &value) const
    {
        get_member_value("value", value);
    }


    /// Test whether this configuration has a constant with the given name.
    ///
    /// @param  name  The name of the constant.
    /// @return  True if the constant exists, false otherwise.
    bool has_constant(const std::string &name) const
    {
        return list_has_member("constants", "name", name);
    }


    /// Get the configuration for the constant with the given name.  The
    /// constant must exist: use `has_constant()` to test for its existence
    /// before calling this method.
    ///
    /// @param  name  The name of the constant.
    /// @return  The constant configuration.
    const ConstantConfiguration &get_constant(const std::string &name) const
    {
        return (const ConstantConfiguration &)list_get_member("constants",
                                                              "name", name);
    }


    /// Get the number of rows and columns for this control or meter.
    ///
    /// @param  rows  The number of rows.
    /// @param  columns  The number of columns.
    void get_dimensions(int &rows, int &columns) const
    {
        rows = get_count("num_rows");
        columns = get_count("num_columns");
    }
};


/// The configuration for a session.
class SessionConfiguration : public Configuration {
public:
    /// Get the list of tasks configured for this session.
    ///
    /// @return  The list of tasks.
    const TaskConfiguration &get_tasks() const
    {
        return (const TaskConfiguration &)get_member("tasks");
    }
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


    /// Test whether the block configuration has a terminal of the given name.
    ///
    /// @param  name  The name of the terminal.
    /// @return  True if the block configuration has a terminal of the given
    ///          name, false otherwise.
    bool has_terminal(const std::string &name) const
    {
        return list_has_member("terminals", "name", name);
    }


    /// Get the terminal configuration for the terminal of the given name.
    /// The terminal configuration must exist: use `has_terminal()` to test
    /// whether it exists before calling this method.
    ///
    /// @param  name  The name of the terminal.
    /// @return  The terminal configuration.
    const TerminalConfiguration &get_terminal(const std::string &name) const
    {
        return (TerminalConfiguration &)list_get_member("terminals", "name",
                                                        name);
    }


    /// Test whether the block configuration has a control of the given name.
    ///
    /// @param  name  The name of the control.
    /// @return  True if the block configuration has a control of the given
    ///          name, false otherwise.
    bool has_control(const std::string &name) const
    {
        return list_has_member("controls", "name", name);
    }


    /// Get the control configuration for the control of the given name.  The
    /// control configuration must exist: use `has_control()` to test whether
    /// it exists before calling this method.
    ///
    /// @param  name  The name of the control.
    /// @return  The control configuration.
    const ControlConfiguration &get_control(const std::string &name) const
    {
        return (ControlConfiguration &)list_get_member("controls", "name", name);
    }


    /// Test whether the block configuration has a meter of the given name.
    ///
    /// @param  name  The name of the meter.
    /// @return  True if the block configuration has a meter of the given
    ///          name, false otherwise.
    bool has_meter(const std::string &name) const
    {
        return list_has_member("meters", "name", name);
    }


    /// Get the meter configuration for the meter of the given name.  The
    /// meter configuration must exist: use `has_meter()` to test whether it
    /// exists before calling this method.
    ///
    /// @param  name  The name of the meter.
    /// @return  The meter configuration.
    const MeterConfiguration &get_meter(const std::string &name) const
    {
        return (MeterConfiguration &)list_get_member("meters", "name", name);
    }


    /// Test whether the block configuration has connections specified.
    ///
    /// @return  True if the block configuration has connections specified,
    bool has_connections() const
    {
        return has_member("connections");
    }


    /// Get the list of connections configured for this block.  The list of
    /// connections must exist: use `has_connections()` to test whether it
    /// exists before calling this method.
    ///
    /// @return  The list of connections.
    const ConnectionConfiguration &get_connections() const
    {
        return (const ConnectionConfiguration &)get_member("connections");
    }


    /// Test whether the block configuration has control settings specified.
    ///
    /// @return  True if the block configuration has control settings
    ///          specified, false otherwise.
    bool has_control_settings() const
    {
        return has_member("control_settings");
    }


    /// Get the list of control settings configured for this block.  The list
    /// of control settings must exist: use `has_control_settings()` to test
    /// whether it exists before calling this method.
    ///
    /// @return  The list of control settings.
    const ControlSetting &get_control_settings() const
    {
        return (const ControlSetting &)get_member("control_settings");
    }
};


/// The configuration for a constant.
class ConstantConfiguration : public Configuration {


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


/// The configuration for a control.
class ControlConfiguration : public Configuration {

};


/// The configuration for a meter.
class MeterConfiguration : public Configuration {

};


/// The configuration for a control setting.
class ControlSetting : public Configuration {
public:
    /// Get the row index for this control setting.  If the row is not set,
    /// this method returns 0.
    ///
    /// @return  The row index.
    int get_row() const
    {
        return get_index("row");
    }


    /// Get the column index for this control setting.  If the column is not
    /// set, this method returns 0.
    ///
    /// @return  The column index.
    int get_column() const
    {
        return get_index("column");
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


} // namespace bosepro
