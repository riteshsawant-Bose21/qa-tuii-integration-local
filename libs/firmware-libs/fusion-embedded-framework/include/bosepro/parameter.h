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
              const BlockConfiguration *configuration);


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
    int get_num_rows() const;


    /// Get the number of columns in the parameter, or 1 if the parameter is a
    /// scalar or vector.
    ///
    /// @return  The number of columns in the parameter.
    int get_num_columns() const;


    /// Get the name of the type of the parameter's value.
    ///
    /// @return  The name of the type of the parameter's value.
    const std::string &get_value_type() const;


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
                  const BlockConfiguration *configuration);


protected:
    T default_value;
    T (*conversion_function)(T);


    /// Get the value for a parameter setting.  If the value is not valid
    /// (out of range, not allowed, etc.), an exception is thrown.
    ///
    /// @param  setting  The setting to get the value from.
    /// @param  value  The value to set.
    void get_setting_value(const ParameterSetting &setting, T &value) const;


private:
    T minimum_value;
    T maximum_value;
    size_t maximum_length;
    std::set<T> allowed_values;
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
                        const BlockConfiguration *configuration);


    /// Assign a pointer to store the value of a scalar parameter.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    void assign(T *value);


    /// Assign a pointer to store the value of a scalar parameter with a simple
    /// conversion function to convert from user-facing values to the internal
    /// representation of the processor.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    void assign(T *value, T (*conversion_function)(T));


    /// Assign a pointer to store the value of a scalar parameter with a
    /// function to be called after the value is set.
    ///
    /// @param  value  The pointer to store the value of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    void assign(T *value, std::function<void()> post_function);


    /// Initialize the parameter by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the parameters, in
    /// case more than one parameter uses the same post function.
    virtual void initialize_post() override;


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) override;


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
                        const BlockConfiguration *configuration);


    /// Assign coefficient memory to store the values of a vector parameter.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    void assign(DspCoeffMemory<T[]> &value);


    /// Assign coefficient memory to store the values of a vector parameter with
    /// a simple conversion function to convert from user-facing values to the
    /// internal representation of the processor.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    void assign(DspCoeffMemory<T[]> &value, T (*conversion_function)(T));


    /// Assign parameter memory to store the values of a vector parameter with
    /// a function to be called after the value is set.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    void assign(DspParamMemory<T[]> &value,
                std::function<void(int)> post_function);


    /// Initialize the parameter by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the parameters, in
    /// case more than one parameter uses the same post function.
    virtual void initialize_post() override;


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) override;


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
                        const BlockConfiguration *configuration);


    /// Assign coefficient memory to store the values of a matrix parameter.
    /// The memory will be re-sized to the length of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    void assign(DspCoeffMemory<T*[]> &value);


    /// Assign coefficient memory to store the values of a matrix parameter with
    /// a simple conversion function to convert from user-facing values to the
    /// internal representation of the processor.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  conversion_function  A function to convert the value before it
    ///                              is set.
    void assign(DspCoeffMemory<T*[]> &value, T (*conversion_function)(T));


    /// Assign parameter memory to store the values of a matrix parameter with a
    /// function to be called after the value is set.
    /// The memory will be re-sized to the dimensions of the parameter.
    ///
    /// @param  value  The memory to store the values of the parameter.
    /// @param  post_function  A function to be called after the value is set.
    void assign(DspParamMemory<T*[]> &value,
                std::function<void(int, int)> post_function);


    /// Initialize the parameter by calling the post function, if it exists.
    /// This is done after `initialize()` is called on all of the parameters, in
    /// case more than one parameter uses the same post function.
    virtual void initialize_post() override;


    /// Set the value of the parameter.
    ///
    /// @param  setting  The new setting for the parameter.
    virtual void set(const ParameterSetting &setting) override;


private:
    T **block_value;
    std::function<void(int, int)> post_function;
};


} // namespace bosepro
