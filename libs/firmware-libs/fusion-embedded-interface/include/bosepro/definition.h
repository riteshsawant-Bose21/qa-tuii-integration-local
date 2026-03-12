#pragma once

#include <bosepro/navigator.h>

#include <set>
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
    Definition(const std::string &filename);


    /// Get the name of the interface.
    ///
    /// @return  The name of the interface.
    const std::string &get_name() const;


    /// Get the name of the type of the interface's value (for Property,
    /// Parameter, and Telemetry interfaces).
    ///
    /// @return  The name of the type of the interface's value.
    const std::string &get_value_type() const;


    /// Get the number of dimensions for a parameter or telemetry (0 for scalar,
    /// 1 for vector, 2 for matrix).
    ///
    /// @return  The number of dimensions for the parameter or telemetry.
    int get_num_dimensions() const;


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
                        std::string &rows_name, std::string &columns_name) const;


    /// Test whether a definition can be found for the algorithm of the given
    /// name.
    ///
    /// @param  name  The name of the algorithm.
    /// @return  True if a definition can be found for the algorithm, false
    ///          otherwise.
    bool has_algorithm(const std::string &name) const;


    /// Get the definition for the algorithm of the given name.  The algorithm
    /// must exist: use `has_algorithm()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the algorithm.
    /// @return  The definition for the algorithm.
    const AlgorithmDefinition &get_algorithm(const std::string &name) const;


    /// Test whether a definition can be found for the module of the given
    /// name.
    ///
    /// @param  name  The name of the module.
    /// @return  True if a definition can be found for the module, false
    ///          otherwise.
    bool has_module(const std::string &name) const;


    /// Get the definition for the module of the given name.  The module
    /// must exist: use `has_module()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the module.
    /// @return  The definition for the module.
    const ModuleDefinition &get_module(const std::string &name) const;


    /// Test whether a property definition of the given name exists.
    ///
    /// @param  name  The name of the property.
    /// @return  True if the property definition exists, false otherwise.
    bool has_property(const std::string &name) const;


    /// Get the property definition of the given name.  The property definition
    /// must exist: use `has_property()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the property.
    /// @return  The property definition.
    const PropertyDefinition &get_property(const std::string &name) const;


    /// Get the default value for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The default value must exist for this definition.
    ///
    /// @param  value  The default value for the interface.
    template <typename T>
    void get_default_value(T &value) const;


    /// Test whether the interface has a minimum value.
    ///
    /// @return  True if the interface has a minimum value, false otherwise.
    bool has_minimum_value() const;


    /// Get the minimum value for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The minimum value must exist for this
    /// definition.
    ///
    /// @param  value  The minimum value for the interface.
    template <typename T>
    void get_minimum_value(T &value) const;


    /// Test whether the interface has a maximum value.
    ///
    /// @return  True if the interface has a maximum value, false otherwise.
    bool has_maximum_value() const;


    /// Get the maximum value for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The maximum value must exist for this
    /// definition.
    ///
    /// @param  value  The maximum value for the interface.
    template <typename T>
    void get_maximum_value(T &value) const;


    /// Get the maximum value for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The maximum value must exist for this
    /// definition.
    ///
    /// @param  value  The maximum value for the interface.
    /// @param  maximum_name  The name of the property or terminal that
    ///                       determines the maximum value for the interface.
    template <typename T>
    void get_maximum_value(T &value, std::string &maximum_name) const;


    /// Test whether the interface has a maximum length.
    ///
    /// @return  True if the interface has a maximum length, false otherwise.
    bool has_maximum_length() const;


    /// Get the maximum length for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The maximum length must exist for this
    /// definition.
    ///
    /// @return  length  The maximum length for a string-valued interface.
    size_t get_maximum_length() const;


    /// Test whether the interface has allowed values.
    ///
    /// @return  True if the interface has allowed values, false otherwise.
    bool has_allowed_values() const;


    /// Get the allowed values for the interface (for Property, Parameter,
    /// and Telemetry interfaces).  The allowed values must exist for this
    /// definition.
    ///
    /// @param  values  A set that will be populated with the allowed values
    ///                 for the interface.
    template <typename T>
    void get_allowed_values(std::set<T> &values) const;


    /// Test whether the provided value is allowed for the interface.  The
    /// allowed values must exist for this definition.
    ///
    /// @param  value  The value to test.
    template <typename T>
    bool is_allowed_value(const T &value) const;
};


class ProcessorDefinition : public Definition {
public:
    /// Test whether the algorithm has terminal definitions.
    ///
    /// @return  True if the algorithm has terminal definitions, false
    ///          otherwise.
    bool has_terminals() const;


    /// Get the terminal definitions for the algorithm.  The terminal
    /// definitions must exist: use `has_terminals()` to test for their
    /// existence before calling this method.
    ///
    /// @return  The terminal definitions for the algorithm.
    const TerminalDefinition &get_terminals() const;


    /// Test whether a terminal definition of the given name exists.
    ///
    /// @param  name  The name of the terminal.
    /// @return  True if the terminal definition exists, false otherwise.
    bool has_terminal(const std::string &name) const;


    /// Get the terminal definition of the given name.  The terminal definition
    /// must exist: use `has_terminal()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the terminal.
    /// @return  The terminal definition.
    const TerminalDefinition &get_terminal(const std::string &name) const;


    /// Test whether the processor has parameter definitions.
    ///
    /// @return  True if the processor has parameter definitions, false
    ///          otherwise.
    bool has_parameters() const;


    /// Get the parameter definitions for the algorithm.  The parameter
    /// definitions must exist: use `has_parameters()` to test for their
    /// existence before calling this method.
    ///
    /// @return  The parameter definitions for the processor.
    const ParameterDefinition &get_parameters() const;


    /// Test whether the processor has telemetry definitions.
    ///
    /// @return  True if the processor has telemetry definitions, false
    ///          otherwise.
    bool has_telemetry() const;


    /// Get the meter definitions for the algorithm.  The meter definitions
    /// must exist: use `has_telemetry()` to test for their existence before
    /// calling this method.
    ///
    /// @return  The meter definitions for the algorithm.
    const TelemetryDefinition &get_telemetry() const;
};


/// The interface definitions for an algorithm.
class AlgorithmDefinition : public ProcessorDefinition {

};


/// The interface definitions for a module.
class ModuleDefinition : public ProcessorDefinition {

};


/// The interface definition for a property.
class PropertyDefinition : public Definition {

};


/// The interface definition for a terminal.
class TerminalDefinition : public Definition {
public:
    /// Test whether the terminal is an output terminal.
    bool is_output() const;


    /// Test whether this terminal has its channels explicitly defined, either
    /// as an integer, or a string indicating a property that defines the
    /// number of channels for this terminal.
    bool has_channels() const;


    /// Get the number of channels for the terminal, or the name of the property
    /// that is used to specify the number of channels.
    ///
    /// @param  A string to contain the name of the property specifying the
    ///     of channels, or an empty string if the number of channels is fixed.
    /// @return  The number of channels for the terminal, if the number
    ///     of channels is fixed, or 0 otherwise.
    int get_channels(std::string &property_name) const;


    /// Return the minimum number of channels that can be specified in a
    /// configuration for this terminal.
    int get_minimum_channels() const;


    /// Return the maximum number of channels that can be specified in a
    /// configuration for this terminal.
    int get_maximum_channels() const;


    /// Test whether this terminal has a bypass source.
    bool has_bypass_source() const;


    /// Get the name of the bypass source for the terminal.  This is an input
    /// terminal that is used as the source for the bypass signal to be copied
    /// to this output terminal.  If no bypass source is defined, an empty
    /// string is returned.
    ///
    /// @return  The name of an input terminal.
    const std::string &get_bypass_source() const;
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
    const std::string &get_period_type() const;


    /// Get the telemetry type
    ///
    /// @return  The telemetry type.
    const std::string &get_telemetry_type() const;
};


} // namespace bosepro
