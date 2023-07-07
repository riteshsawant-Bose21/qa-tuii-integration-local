#pragma once

#include <bosepro/configuration.h>
#include <bosepro/parameters.h>

#include <string>
#include <vector>


namespace bosepro {


/// A class for managing the data of a control.
class Control {
public:
    /// Create a control object based on the type of the parameter.
    ///
    /// @param  parameter  The parameter that defines the control.
    /// @param  configuration  The configuration to use for the control.
    Control(const ControlParameter &parameter, 
            const ControlConfiguration *configuration)
    {
        value_type = parameter.get_value_type();

        if (configuration != nullptr)
        {
            configuration->get_dimensions(num_rows, num_columns);
        }
    }

    virtual ~Control() = default;


    /// Initialize the control by resizing its storage to the configured
    /// dimensions, and initializing the values to the default values.
    virtual void initialize() = 0;


    /// Assign a pointer to store the value of a scalar control.
    ///
    /// @param  value  The pointer to store the value of the control.
    template <typename T>
    void assign(T *value);


    /// Assign a vector to store the values of a vector control. The vector will
    /// be re-sized to the length of the control.
    ///
    /// @param  value  The vector to store the values of the control.
    template <typename T>
    void assign(std::vector<T> *value);


    /// Assign a two-demensional vector to store the values of a matrix control.
    /// The vector will be re-sized to the dimensions of the control.
    ///
    /// @param  value  The vector to store the values of the control.
    template <typename T>
    void assign(std::vector<std::vector<T>> *value);


    /// Set the value of the control.
    ///
    /// @param  setting  The new setting for the control.
    virtual void set(const ControlSetting &setting) = 0;


    /// Get the number of rows in the control, or 1 if the control is a scalar.
    ///
    /// @return  The number of rows in the control.
    int get_num_rows() const
    {
        return num_rows;
    }


    /// Get the number of columns in the control, or 1 if the control is a
    /// scalar or vector.
    ///
    /// @return  The number of columns in the control.
    int get_num_columns() const
    {
        return num_columns;
    }


    /// Get the name of the type of the control's value.
    ///
    /// @return  The name of the type of the control's value.
    const std::string &get_value_type() const
    {
        return value_type;
    }


    /// Create a Control object based on the type of the parameter.
    ///
    /// @param  parameter  The parameter to create the control from.
    /// @param  configuration  The configuration to use for the control.
    /// @return  A pointer to the created control object.
    static Control *create(const ControlParameter &parameter,
                           const ControlConfiguration *configuration);


private:
    std::string value_type;
    int num_rows;
    int num_columns;
};


/// A type-specific version of `Control` with storage for the control's values.
template <typename T>
class ControlData : public Control {
public:
    /// Create a control object for managing control values.
    ///
    /// @param  parameter  The parameter that defines the control.
    /// @param  configuration  The configuration to use for the control.
    ControlData(const ControlParameter &parameter,
                const ControlConfiguration *configuration)
        : Control(parameter, configuration)
    {
        parameter.get_default_value(default_value);
        scalar_value = nullptr;
        vector_value = nullptr;
        matrix_value = nullptr;
    }


    /// Assign a pointer to store the value of a scalar control.
    ///
    /// @param  value  The pointer to store the value of the control.
    void assign(T *value)
    {
        scalar_value = value;
    }


    /// Assign a vector to store the values of a vector control. The vector will
    /// be re-sized to the length of the control.
    ///
    /// @param  value  The vector to store the values of the control.
    void assign(std::vector<T> *value)
    {
        vector_value = value;
    }


    /// Assign a two-demensional vector to store the values of a matrix control.
    /// The vector will be re-sized to the dimensions of the control.
    ///
    /// @param  value  The vector to store the values of the control.
    void assign(std::vector<std::vector<T>> *value)
    {
        matrix_value = value;
    }


    /// Initialize the control by resizing its storage to the configured
    /// dimensions, and initializing the values to the default values.
    virtual void initialize() override
    {
        if (scalar_value != nullptr)
        {
            *scalar_value = default_value;
        }
        else if (vector_value != nullptr)
        {
            vector_value->resize(get_num_rows());
            std::fill(vector_value->begin(), vector_value->end(), default_value);
        }
        else if (matrix_value != nullptr)
        {
            matrix_value->resize(get_num_rows());
            for (auto &row : *matrix_value)
            {
                row.resize(get_num_columns());
                std::fill(row.begin(), row.end(), default_value);
            }
        }
    }


    /// Set the value of the control.
    ///
    /// @param  setting  The new setting for the control.
    virtual void set(const ControlSetting &setting) override
    {
        int row = setting.get_row();
        int column = setting.get_column();
        T value;
        setting.get_value(value);

        if (scalar_value)
        {
            *scalar_value = value;
        }
        else if (vector_value)
        {
            (*vector_value)[row] = value;
        }
        else if (matrix_value)
        {
            (*matrix_value)[row][column] = value;
        }
    }


private:
    T default_value;
    T *scalar_value;
    std::vector<T> *vector_value;
    std::vector<std::vector<T>> *matrix_value;
};


} // namespace bosepro
