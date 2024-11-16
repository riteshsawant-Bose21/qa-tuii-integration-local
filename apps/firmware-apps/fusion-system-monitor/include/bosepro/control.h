#pragma once

#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/parameters.h>

#include <functional>
#include <string>
#include <vector>


namespace bosepro {

class Algorithm;

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


    /// Initialize the control by calling the post function, if it exists.
    virtual void initialize_post() = 0;


    /// Assign a pointer to store the value of a scalar control.
    ///
    /// @param  value  The pointer to store the value of the control.
    /// @param  post_function  An optional function to be called after the value
    ///                        is set (set to `nullptr` if not needed).
    template <typename T>
    void assign(T *value, std::function<void()> post_function);


    /// Assign coefficient memory to store the values of a vector control.
    /// The memory will be re-sized to the length of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    template <typename T>
    void assign(DspCoeffMemory<T[]> &value);


    /// Assign parameter memory to store the values of a vector control.
    /// The memory will be re-sized to the length of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign(DspParamMemory<T[]> &value,
                std::function<void(int)> post_function);


    /// Assign coefficient memory to store the values of a matrix control.
    /// The memory will be re-sized to the dimensions of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign(DspCoeffMemory<T*[]> &value);


    /// Assign parameter memory to store the values of a matrix control.
    /// The memory will be re-sized to the dimensions of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign(DspParamMemory<T*[]> &value,
                std::function<void(int, int)> post_function);


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
    int dimensions;
    int num_rows;
    int num_columns;
};


/// A type-specific version of `Control`.
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
    }

protected:
    T default_value;
};


/// A type-specific version of `Control` with storage for scalar values.
template <typename T>
class ControlDataScalar : public ControlData<T> {
public:
    /// Create a control object for managing scalar control values.
    ///
    /// @param  parameter  The parameter that defines the control.
    /// @param  configuration  The configuration to use for the control.
    ControlDataScalar(const ControlParameter &parameter,
                      const ControlConfiguration *configuration)
        : ControlData<T>(parameter, configuration), block_value(nullptr),
          post_function(nullptr)
    {
    }

    /// Assign a pointer to store the value of a scalar control.
    ///
    /// @param  value  The pointer to store the value of the control.
    /// @param  post_function  An optional function to be called after the value
    ///                        is set (set to `nullptr` if not needed).
    void assign(T *value, std::function<void()> post_function)
    {
        block_value = value;
        *block_value = this->default_value;
        this->post_function = post_function;
    }


    /// Initialize the control by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the controls, in
    /// case more than one control uses the same post function.
    virtual void initialize_post() override
    {
        if (post_function != nullptr)
        {
            post_function();
        }
    }


    /// Set the value of the control.
    ///
    /// @param  setting  The new setting for the control.
    virtual void set(const ControlSetting &setting) override
    {
        T value;
        setting.get_value(value);

        *block_value = value;

        if (post_function != nullptr)
        {
            post_function();
        }
    }


private:
    T *block_value;
    std::function<void()> post_function;
};


/// A type-specific version of `Control` with storage for vector values.
template <typename T>
class ControlDataVector : public ControlData<T> {
public:
    /// Create a control object for managing vector control values.
    ///
    /// @param  parameter  The parameter that defines the control.
    /// @param  configuration  The configuration to use for the control.
    ControlDataVector(const ControlParameter &parameter,
                      const ControlConfiguration *configuration)
        : ControlData<T>(parameter, configuration), block_value(nullptr),
          post_function(nullptr)
    {
    }


    /// Assign coefficient memory to store the values of a vector control.
    /// The memory will be re-sized to the length of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    void assign(DspCoeffMemory<T[]> &value)
    {
        value.resize(this->get_num_rows());
        block_value = value.get();

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            value[row] = this->default_value;
        }
    }


    /// Assign parameter memory to store the values of a vector control.
    /// The memory will be re-sized to the length of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    /// @param  post_function  A function to be called after the value is set.
    void assign(DspParamMemory<T[]> &value,
                std::function<void(int)> post_function)
    {
        value.resize(this->get_num_rows());
        block_value = value.get();

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            value[row] = this->default_value;
        }

        this->post_function = post_function;
    }


    /// Initialize the control by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the controls, in
    /// case more than one control uses the same post function.
    virtual void initialize_post() override
    {
        if (post_function != nullptr)
        {
            for (int row = 0; row < this->get_num_rows(); row++)
            {
                post_function(row);
            }
        }
    }


    /// Set the value of the control.
    ///
    /// @param  setting  The new setting for the control.
    virtual void set(const ControlSetting &setting) override
    {
        int row = setting.get_row();
        T value;
        setting.get_value(value);

        block_value[row] = value;

        if (post_function != nullptr)
        {
            post_function(row);
        }
    }


private:
    T *block_value;
    std::function<void(int)> post_function;
};


/// A type-specific version of `Control` with storage for matrix values.
template <typename T>
class ControlDataMatrix : public ControlData<T> {
public:
    /// Create a control object for managing matrix control values.
    ///
    /// @param  parameter  The parameter that defines the control.
    /// @param  configuration  The configuration to use for the control.
    ControlDataMatrix(const ControlParameter &parameter,
                      const ControlConfiguration *configuration)
        : ControlData<T>(parameter, configuration), block_value(nullptr),
          post_function(nullptr)
    {
    }


    /// Assign coefficient memory to store the values of a matrix control.
    /// The memory will be re-sized to the length of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    void assign(DspCoeffMemory<T*[]> &value)
    {
        value.resize(this->get_num_rows(), this->get_num_columns());
        block_value = value.get();

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            for (int column = 0; column < this->get_num_columns(); column++)
            {
                block_value[row][column] = this->default_value;
            }
        }
    }


    /// Assign parameter memory to store the values of a matrix control.
    /// The memory will be re-sized to the length of the control.
    ///
    /// @param  value  The memory to store the values of the control.
    /// @param  post_function  A function to be called after the value is set.
    void assign(DspParamMemory<T*[]> &value,
                std::function<void(int, int)> post_function)
    {
        value.resize(this->get_num_rows(), this->get_num_columns());
        block_value = value.get();

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            for (int column = 0; column < this->get_num_columns(); column++)
            {
                block_value[row][column] = this->default_value;
            }
        }

        this->post_function = post_function;
    }


    /// Initialize the control by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the controls, in
    /// case more than one control uses the same post function.
    virtual void initialize_post() override
    {
        if (post_function != nullptr)
        {
            for (int row = 0; row < this->get_num_rows(); row++)
            {
                for (int column = 0; column < this->get_num_columns(); column++)
                {
                    post_function(row, column);
                }
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

        block_value[row][column] = value;

        if (post_function != nullptr)
        {
            post_function(row, column);
        }
    }


private:
    T **block_value;
    std::function<void(int, int)> post_function;
};


} // namespace bosepro
