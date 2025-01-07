#pragma once

#include <bosepro/navigator.h>

#include <string>


namespace bosepro {


class AlgorithmDefinition;
class ModuleDefinition;
class PropertyDefinition;
class TerminalDefinition;
class ParameterDefinition;
class TelemetryDefinition;


/// A definition of an interface or set of definitions.
class Definition : public Navigator {
public:
    /// Build the interface definitions for the system from the given JSON file.
    ///
    /// @param  filename  A JSON file containing the interface definitions.
    Definition(const std::string &filename)
        : Navigator(filename)
    {
    }


    /// Get the name of the interface.
    ///
    /// @return  The name of the interface.
    const std::string &get_name() const
    {
        return get_string("name");
    }


    /// Get the name of the type of the interface's value (for Property,
    /// Parameter, and Telemetry interfaces).
    ///
    /// @return  The name of the type of the interface's value.
    const std::string &get_value_type() const
    {
        return get_string("value_type");
    }


    /// Get the number of dimensions for a parameter or telemetry (0 for scalar,
    /// 1 for vector, 2 for matrix).
    int get_num_dimensions() const
    {
        return list_size("dimensions");
    }


    /// Get the sizes of each dimension for a parameters or telemetry.  These may
    /// be specified as fixed integer values (causing `num_rows` and/or
    /// `num_columns` to be updated), or as the names of properties or
    /// terminals from which the sizes are inherited (causing `rows_name` and/or
    /// `column_name` to be updated.  For scalar or vector parameters, the
    /// integer values are unchanged or empty strings as appropriate for the
    /// number of dimensions.
    ///
    /// @param  num_rows  The integer number of rows, if specified as fixed.
    ///                   Otherwise, the value is unchanged.
    /// @param  num_columns  The integer number of columns, if specified as
    ///                      fixed. Otherwise, the value is unchanged.
    /// @param  rows_name  The name of the property or terminal that the number
    ///                    of rows is inherited from, or an empty string if the
    ///                    number of rows is fixed.
    /// @param  columns_name  The name of the property or terminal that the
    ///                       number of columns is inherited from, or an empty
    ///                       string if the number of columns is fixed.
    void get_dimensions(int &num_rows, int &num_columns,
                        std::string &rows_name, std::string &columns_name) const
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
            try_list_value("dimensions", 0, num_rows);
        }

        if (get_num_dimensions() == 1)
        {
            columns_name = "";
            return;
        }

        if (!try_list_value("dimensions", 1, columns_name))
        {
            columns_name = "";
            try_list_value("dimensions", 1, num_columns);
        }
    }


    /// Test whether a definition can be found for the algorithm of the given
    /// name.
    ///
    /// @param  name  The name of the algorithm.
    /// @return  True if a definition can be found for the algorithm, false
    ///          otherwise.
    bool has_algorithm(const std::string &name) const
    {
        return list_has_member("algorithms", "name", name);
    }


    /// Get the definition for the algorithm of the given name.  The algorithm
    /// must exist: use `has_algorithm()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the algorithm.
    /// @return  The definition for the algorithm.
    const AlgorithmDefinition &get_algorithm(const std::string &name) const
    {
        return (const AlgorithmDefinition &)list_get_member("algorithms",
                                                            "name", name);
    }


    /// Test whether a definition can be found for the module of the given
    /// name.
    ///
    /// @param  name  The name of the module.
    /// @return  True if a definition can be found for the module, false
    ///          otherwise.
    bool has_module(const std::string &name) const
    {
        return list_has_member("modules", "name", name);
    }


    /// Get the definition for the module of the given name.  The module
    /// must exist: use `has_module()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the module.
    /// @return  The definition for the module.
    const ModuleDefinition &get_module(const std::string &name) const
    {
        return (const ModuleDefinition &)list_get_member("modules",
                                                            "name", name);
    }


    /// Test whether a property definition of the given name exists.
    ///
    /// @param  name  The name of the property.
    /// @return  True if the property definition exists, false otherwise.
    bool has_property(const std::string &name) const
    {
        return list_has_member("properties", "name", name);
    }


    /// Get the property definition of the given name.  The property definition
    /// must exist: use `has_property()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the property.
    /// @return  The property definition.
    const PropertyDefinition &get_property(const std::string &name) const
    {
        return (const PropertyDefinition &)list_get_member("properties", "name",
                                                           name);
    }


    /// Get the default value for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The default value must exist for this definition.
    ///
    /// @param  value  The default value for the interface.
    template <typename T>
    void get_default_value(T &value) const
    {
        get_member_value<T>("default_value", value);
    }
};


class ProcessorDefinition : public Definition {
public:
    /// Test whether the algorithm has terminal definitions.
    ///
    /// @return  True if the algorithm has terminal definitions, false
    ///          otherwise.
    bool has_terminals() const
    {
        return has_member("terminals");
    }


    /// Get the terminal definitions for the algorithm.  The terminal
    /// definitions must exist: use `has_terminals()` to test for their
    /// existence before calling this method.
    ///
    /// @return  The terminal definitions for the algorithm.
    const TerminalDefinition &get_terminals() const
    {
        return (const TerminalDefinition &)get_member("terminals");
    }


    /// Test whether a terminal definition of the given name exists.
    ///
    /// @param  name  The name of the terminal.
    /// @return  True if the terminal definition exists, false otherwise.
    bool has_terminal(const std::string &name) const
    {
        return list_has_member("terminals", "name", name);
    }


    /// Get the terminal definition of the given name.  The terminal definition
    /// must exist: use `has_terminal()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the terminal.
    /// @return  The terminal definition.
    const TerminalDefinition &get_terminal(const std::string &name) const
    {
        return (const TerminalDefinition &)list_get_member("terminals", "name",
                                                           name);
    }


    /// Test whether the algorithm has parameter definitions.
    ///
    /// @return  True if the algorithm has parameter definitions, false
    ///          otherwise.
    bool has_parameters() const
    {
        return has_member("parameters");
    }


    /// Get the parameter definitions for the algorithm.  The parameter
    /// definitions must exist: use `has_parameters()` to test for their
    /// existence before calling this method.
    ///
    /// @return  The parameter definitions for the algorithm.
    const ParameterDefinition &get_parameters() const
    {
        return (const ParameterDefinition &)get_member("parameters");
    }


    /// Test whether the algorithm has meter definitions.
    ///
    /// @return  True if the algorithm has meter definitions, false
    ///          otherwise.
    bool has_telemetry() const
    {
        return has_member("telemetry");
    }


    /// Get the meter definitions for the algorithm.  The meter definitions
    /// must exist: use `has_telemetry()` to test for their existence before
    /// calling this method.
    ///
    /// @return  The meter definitions for the algorithm.
    const TelemetryDefinition &get_telemetry() const
    {
        return (const TelemetryDefinition &)get_member("telemetry");
    }
};


/// The interface definitions for an algorithm.
class AlgorithmDefinition : public ProcessorDefinition {

};


/// The interface definitions for an module.
class ModuleDefinition : public ProcessorDefinition {

};


/// The interface definition for a property.
class PropertyDefinition : public Definition {

};


/// The interface definition for a terminal.
class TerminalDefinition : public Definition {
public:
    /// Test whether the terminal is an output terminal.
    bool is_output() const
    {
        return get_string("direction") == "output";
    }


    /// Test whether this terminal has its channels explicitly defined, either
    /// as an integer, or a string indicating a property that defines the
    /// number of channels for this terminal.
    bool has_channels() const
    {
        return has_member("channels");
    }


    /// Get the number of channels for the terminal, or the name of the property
    /// that is used to specify the number of channels.
    ///
    /// @param  A string to contain the name of the property specifying the
    ///     of channels, or an empty string if the number of channels is fixed.
    /// @return  The number of channels for the terminal, if the number
    ///     of channels is fixed, or 0 otherwise.
    int get_channels(std::string &property_name) const
    {
        int channels = 0;

        if (try_member_value<int>("channels", channels))
        {
            SPDLOG_DEBUG("Got channels from definition: {}.", channels);
        }
        else if (try_member_value<std::string>("channels", property_name))
        {
            SPDLOG_DEBUG("Got channels from definition: {}.", property_name);
        }
        else
        {
            SPDLOG_CRITICAL("Failed to get channels from definition.");
        }

        return channels;
    }


    /// Return the minimum number of channels that can be specified in a
    /// configuration for this terminal.
    int get_minimum_channels() const
    {
        int minimum_channels = 0;
        get_member_value("minimum_channels", minimum_channels);
        return minimum_channels;
    }


    /// Return the maximum number of channels that can be specified in a
    /// configuration for this terminal.
    int get_maximum_channels() const
    {
        int maximum_channels = 0;
        get_member_value("maximum_channels", maximum_channels);
        return maximum_channels;
    }


    /// Test whether this terminal has a bypass source.
    bool has_bypass_source() const
    {
        return has_member("bypass_source");
    }


    /// Get the name of the bypass source for the terminal.  This is an input
    /// terminal that is used as the source for the bypass signal to be copied
    /// to this output terminal.  If no bypass source is defined, an empty
    /// string is returned.
    ///
    /// @return  The name of an input terminal.
    const std::string &get_bypass_source() const
    {
        return get_string("bypass_source");
    }
};


/// The interface definition for a parameter.
class ParameterDefinition : public Definition {

};


/// The parameter definition for a meter.
class TelemetryDefinition : public Definition {
public:
    /// Get the telemetry reate
    ///
    /// @return  The telemetry type.
    const std::string &get_period_type() const
    {
        return get_string("period_type");
    }


    /// Get the telemetry type
    ///
    /// @return  The telemetry type.
    const std::string &get_telemetry_type() const
    {
        return get_string("telemetry_type");
    }
};


} // namespace bosepro
