#pragma once

#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/definition.h>

#include <functional>
#include <string>
#include <vector>


namespace bosepro {


/// A class for managing the data of a parameter.
class Parameter {
public:
    /// Create a parameter object based on the type of its value.
    ///
    /// @
    /// @param  definition  The definition that defines the parameter.
    /// @param  configuration  The configuration of the block owning the
    ///     parameter.
    Parameter(const ParameterDefinition &definition,
              const ProcessorDefinition &processor,
              const BlockConfiguration *configuration)
    {
        value_type = definition.get_value_type();
        num_rows = 1;
        num_columns = 1;
        dimensions = definition.get_num_dimensions();

        if (dimensions != 0)
        {
            std::string rows_name;
            std::string columns_name;
            definition.get_dimensions(num_rows, num_columns,
                                      rows_name, columns_name);

            if (!rows_name.empty())
            {
                if (processor.has_property(rows_name))
                {
                    if (configuration->has_property(rows_name))
                    {
                        const PropertyConfiguration &pc =
                            configuration->get_property(rows_name);
                        pc.get_value(num_rows);
                    }
                    else
                    {
                        const PropertyDefinition &pd =
                            processor.get_property(rows_name);
                        pd.get_default_value(num_rows);
                    }
                }
                else if (processor.has_terminal(rows_name))
                {
                    if (configuration->has_terminal(rows_name))
                    {
                        const TerminalConfiguration &tc =
                            configuration->get_terminal(rows_name);
                        num_rows = tc.get_num_channels();
                    }
                }
            }

            if (!columns_name.empty())
            {
                if (processor.has_property(columns_name))
                {
                    if (configuration->has_property(columns_name))
                    {
                        const PropertyConfiguration &pc =
                            configuration->get_property(columns_name);
                        pc.get_value(num_columns);
                    }
                    else
                    {
                        const PropertyDefinition &pd =
                            processor.get_property(columns_name);
                        pd.get_default_value(num_columns);
                    }
                }
                else if (processor.has_terminal(columns_name))
                {
                    if (configuration->has_terminal(columns_name))
                    {
                        const TerminalConfiguration &tc =
                            configuration->get_terminal(columns_name);
                        num_columns = tc.get_num_channels();
                    }
                }
            }
        }
    }

    virtual ~Parameter() = default;


    /// Initialize the parameter by calling the post function, if it exists.
    virtual void initialize_post() = 0;


    /// Assign a pointer to store the value of a scalar parameter.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    template <typename T>
    void assign(T *value);


    /// Assign a pointer to store the value of a scalar parameter with a simple
    /// conversion function to convert from user-facing values to the internal
    /// representation of the processor.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    template <typename T>
    void assign(T *value, T (*conversion_function)(T));


    /// Assign a pointer to store the value of a scalar parameter with a
    /// function to be called after the value is set.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign(T *value, std::function<void()> post_function);


    /// Assign coefficient memory to store the values of a vector parameter.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    template <typename T>
    void assign(DspCoeffMemory<T[]> &value);


    /// Assign coefficient memory to store the values of a vector parameter with
    /// a simple conversion function to convert from user-facing values to the
    /// internal representation of the processor.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    template <typename T>
    void assign(DspCoeffMemory<T[]> &value, T (*conversion_function)(T));


    /// Assign parameter memory to store the values of a vector parameter with
    /// a function to be called after the value is set.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign(DspParamMemory<T[]> &value,
                std::function<void(int)> post_function);


    /// Assign coefficient memory to store the values of a matrix parameter.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    template <typename T>
    void assign(DspCoeffMemory<T*[]> &value);


    /// Assign coefficient memory to store the values of a matrix parameter with
    /// a simple conversion function to convert from user-facing values to the
    /// internal representation of the processor.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    template <typename T>
    void assign(DspCoeffMemory<T*[]> &value, T (*conversion_function)(T));


    /// Assign parameter memory to store the values of a matrix parameter with a
    /// function to be called after the value is set.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    template <typename T>
    void assign(DspParamMemory<T*[]> &value,
                std::function<void(int, int)> post_function);


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) = 0;


    /// Get the number of rows in the parameter, or 1 if the parameter is a
    /// scalar.
    ///
    /// @return  The number of rows in the parameter.
    int get_num_rows() const
    {
        return num_rows;
    }


    /// Get the number of columns in the parameter, or 1 if the parameter is a
    /// scalar or vector.
    ///
    /// @return  The number of columns in the parameter.
    int get_num_columns() const
    {
        return num_columns;
    }


    /// Get the name of the type of the parameter's value.
    ///
    /// @return  The name of the type of the parameter's value.
    const std::string &get_value_type() const
    {
        return value_type;
    }


    /// Create a Parameter object based on the type of the parameter.
    ///
    /// @param  definition  The definition to create the parameter from.
    /// @param  configuration  The configuration of the block owning the
    ///     parameter.
    /// @return  A pointer to the created parameter object.
    static Parameter *create(const ParameterDefinition &definition,
                             const ProcessorDefinition &processor,
                             const BlockConfiguration *configuration);


private:
    std::string value_type;
    int dimensions;
    int num_rows;
    int num_columns;
};


/// A type-specific version of `Parameter`.
template <typename T>
class ParameterData : public Parameter {
public:
    /// Create a parameter object for managing parameter values.
    ///
    /// @param  definition  The definition that defines the parameter.
    /// @param  configuration  The configuration of the block owning the
    ///     parameter.
    ParameterData(const ParameterDefinition &definition,
                  const ProcessorDefinition &processor,
                  const BlockConfiguration *configuration)
        : Parameter(definition, processor, configuration),
          conversion_function(nullptr)
    {
        definition.get_default_value(default_value);
    }

protected:
    T default_value;
    T (*conversion_function)(T);
};


/// A type-specific version of `Parameter` with storage for scalar values.
template <typename T>
class ParameterDataScalar : public ParameterData<T> {
public:
    /// Create a parameter object for managing scalar parameter values.
    ///
    /// @param  definition  The definition that defines the parameter.
    /// @param  configuration  The configuration of the block that owns the
    ///     parameter.
    ParameterDataScalar(const ParameterDefinition &definition,
                        const ProcessorDefinition &processor,
                        const BlockConfiguration *configuration)
        : ParameterData<T>(definition, processor, configuration),
          block_value(nullptr), post_function(nullptr)
    {
    }


    /// Assign a pointer to store the value of a scalar parameter.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    void assign(T *value)
    {
        block_value = value;
        *block_value = this->default_value;
    }


    /// Assign a pointer to store the value of a scalar parameter with a simple
    /// conversion function to convert from user-facing values to the internal
    /// representation of the processor.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    void assign(T *value, T (*conversion_function)(T))
    {
        block_value = value;
        this->conversion_function = conversion_function;
        *block_value = conversion_function(this->default_value);
    }


    /// Assign a pointer to store the value of a scalar parameter with a
    /// function to be called after the value is set.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    void assign(T *value, std::function<void()> post_function)
    {
        block_value = value;
        *block_value = this->default_value;
        this->post_function = post_function;
    }


    /// Initialize the parameter by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the parameters, in
    /// case more than one parameter uses the same post function.
    virtual void initialize_post() override
    {
        if (post_function != nullptr)
        {
            post_function();
        }
    }


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) override
    {
        if (setting.has_value())
        {
            T value;
            setting.get_value(value);

            if (this->conversion_function == nullptr)
            {
                *block_value = value;
            }
            else
            {
                *block_value = this->conversion_function(value);
            }
        }

        if (post_function != nullptr)
        {
            post_function();
        }
    }


private:
    T *block_value;
    std::function<void()> post_function;
};


/// A type-specific version of `Parameter` with storage for vector values.
template <typename T>
class ParameterDataVector : public ParameterData<T> {
public:
    /// Create a parameter object for managing vector parameter values.
    ///
    /// @param  definition  The definition that defines the parameter.
    /// @param  configuration  The configuration of the block owning the
    ///     parameter.
    ParameterDataVector(const ParameterDefinition &definition,
                        const ProcessorDefinition &processor,
                        const BlockConfiguration *configuration)
        : ParameterData<T>(definition, processor, configuration),
          block_value(nullptr), post_function(nullptr)
    {
    }


    /// Assign coefficient memory to store the values of a vector parameter.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    void assign(DspCoeffMemory<T[]> &value)
    {
        SPDLOG_TRACE("resizing {}", this->get_num_rows());
        value.resize(this->get_num_rows());
        block_value = value.get();

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            value[row] = this->default_value;
        }
    }


    /// Assign coefficient memory to store the values of a vector parameter with
    /// a simple conversion function to convert from user-facing values to the
    /// internal representation of the processor.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    void assign(DspCoeffMemory<T[]> &value, T (*conversion_function)(T))
    {
        value.resize(this->get_num_rows());
        block_value = value.get();
        this->conversion_function = conversion_function;
        T dv = conversion_function(this->default_value);

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            value[row] = dv;
        }
    }


    /// Assign parameter memory to store the values of a vector parameter with
    /// a function to be called after the value is set.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
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


    /// Initialize the parameter by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the parameters, in
    /// case more than one parameter uses the same post function.
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


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) override
    {
        int row = setting.get_row();
        if (setting.has_value())
        {
            T value;
            setting.get_value(value);

            if (this->conversion_function == nullptr)
            {
                block_value[row] = value;
            }
            else
            {
                block_value[row] = this->conversion_function(value);
            }
        }

        if (post_function != nullptr)
        {
            post_function(row);
        }
    }


private:
    T *block_value;
    std::function<void(int)> post_function;
};


/// A type-specific version of `Parameter` with storage for matrix values.
template <typename T>
class ParameterDataMatrix : public ParameterData<T> {
public:
    /// Create a parameter object for managing matrix parameter values.
    ///
    /// @param  definition  The definition that defines the parameter.
    /// @param  configuration  The configuration for the block owning the
    ///     parameter.
    ParameterDataMatrix(const ParameterDefinition &definition,
                        const ProcessorDefinition &processor,
                        const BlockConfiguration *configuration)
        : ParameterData<T>(definition, processor, configuration),
          block_value(nullptr), post_function(nullptr)
    {
    }


    /// Assign coefficient memory to store the values of a matrix parameter.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
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


    /// Assign coefficient memory to store the values of a matrix parameter with
    /// a simple conversion function to convert from user-facing values to the
    /// internal representation of the processor.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    void assign(DspCoeffMemory<T*[]> &value, T (*conversion_function)(T))
    {
        value.resize(this->get_num_rows(), this->get_num_columns());
        block_value = value.get();
        this->conversion_function = conversion_function;
        T dv = conversion_function(this->default_value);

        for (int row = 0; row < this->get_num_rows(); row++)
        {
            for (int column = 0; column < this->get_num_columns(); column++)
            {
                block_value[row][column] = dv;
            }
        }
    }


    /// Assign parameter memory to store the values of a matrix parameter with a
    /// function to be called after the value is set.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
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


    /// Initialize the parameter by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the parameters, in
    /// case more than one parameter uses the same post function.
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


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) override
    {
        int row = setting.get_row();
        int column = setting.get_column();
        if (setting.has_value())
        {
            T value;
            setting.get_value(value);

            if (this->conversion_function == nullptr)
            {
                block_value[row][column] = value;
            }
            else
            {
                block_value[row][column] = this->conversion_function(value);
            }
        }

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
