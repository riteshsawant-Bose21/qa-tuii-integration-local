#pragma once

#include <bosepro/property.h>

#include <string>


namespace bosepro {


class AlgorithmParameters;
class ConstantParameter;
class TerminalParameter;
class ControlParameter;
class MeterParameter;


/// A definition of a parameter or set of parameters.
class Parameters : public PropertyNavigator {
public:
    /// Build the parameter definitions for the system from the given JSON file.
    ///
    /// @param  filename  A JSON file containing the parameter definitions.
    Parameters(const std::string &filename)
        : PropertyNavigator(filename)
    {
    }


    /// Get the name of the parameter.
    ///
    /// @return  The name of the parameter.
    const std::string &get_name() const
    {
        return get_string("name");
    }


    /// Get the name of the type of the parameter's value (for Constant, Control
    /// and Meter parameters).
    ///
    /// @return  The name of the type of the parameter's value.
    const std::string &get_value_type() const
    {
        return get_string("value_type");
    }


    /// Test whether parameters can be found for the algorithm of the given name.
    ///
    /// @param  name  The name of the algorithm.
    /// @return  True if parameters can be found for the algorithm, false
    ///          otherwise.
    bool has_algorithm(const std::string &name) const
    {
        return list_has_member("algorithms", "name", name);
    }


    /// Get the parameters for the algorithm of the given name.  The algorithm
    /// must exist: use `has_algorithm()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the algorithm.
    /// @return  The parameters for the algorithm.
    const AlgorithmParameters &get_algorithm(const std::string &name) const
    {
        return (const AlgorithmParameters &)list_get_member("algorithms",
                                                            "name", name);
    }


    /// Test whether a constant parameter of the given name exists.
    ///
    /// @param  name  The name of the constant parameter.
    /// @return  True if the constant parameter exists, false otherwise.
    bool has_constant(const std::string &name) const
    {
        return list_has_member("constants", "name", name);
    }


    /// Get the constant parameter of the given name.  The constant parameter
    /// must exist: use `has_constant()` to test for its existence before
    /// calling this method.
    ///
    /// @param  name  The name of the constant parameter.
    /// @return  The constant parameter.
    const ConstantParameter &get_constant(const std::string &name) const
    {
        return (const ConstantParameter &)list_get_member("constants", "name",
                                                          name);
    }


    /// Get the default value for the parameter (for Constant and Control
    /// parameters).  The default value must exist for this definition.
    ///
    /// @param  value  The default value for the parameter.
    template <typename T>
    void get_default_value(T &value) const
    {
        get_member_value<T>("default_value", value);
    }
};


/// The parameter definitions for an algorithm.
class AlgorithmParameters : public Parameters {
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
    const TerminalParameter &get_terminals() const
    {
        return (const TerminalParameter &)get_member("terminals");
    }


    /// Test whether the algorithm has control definitions.
    ///
    /// @return  True if the algorithm has control definitions, false
    ///          otherwise.
    bool has_controls() const
    {
        return has_member("controls");
    }


    /// Get the control definitions for the algorithm.  The control
    /// definitions must exist: use `has_controls()` to test for their
    /// existence before calling this method.
    ///
    /// @return  The control definitions for the algorithm.
    const ControlParameter &get_controls() const
    {
        return (const ControlParameter &)get_member("controls");
    }


    /// Test whether the algorithm has meter definitions.
    ///
    /// @return  True if the algorithm has meter definitions, false
    ///          otherwise.
    bool has_meters() const
    {
        return has_member("meters");
    }


    /// Get the meter definitions for the algorithm.  The meter definitions
    /// must exist: use `has_meters()` to test for their existence before
    /// calling this method.
    ///
    /// @return  The meter definitions for the algorithm.
    const MeterParameter &get_meters() const
    {
        return (const MeterParameter &)get_member("meters");
    }
};


/// The parameter definition for a constant.
class ConstantParameter : public Parameters {

};


/// The parameter definition for a terminal.
class TerminalParameter : public Parameters {
public:
    /// Test whether the terminal is an output terminal.
    bool is_output() const
    {
        return get_string("direction") == "output";
    }

    /// Get the default number of channels for the terminal.  The default
    /// number of channels must exist in the definition.
    ///
    /// @return  The default number of channels for the terminal.
    int get_default_channels() const
    {
        int default_channels;
        get_member_value("default_channels", default_channels);
        return default_channels;
    }
};


/// The parameter definition for a control.
class ControlParameter : public Parameters {

};


/// The parameter definition for a meter.
class MeterParameter : public Parameters {

};


} // namespace bosepro
