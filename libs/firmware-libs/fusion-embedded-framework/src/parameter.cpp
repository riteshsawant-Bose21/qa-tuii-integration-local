
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/parameter.h>

#include <cstdint>
#include <functional>
#include <string>


namespace bosepro {


Parameter::Parameter(const ParameterDefinition &definition,
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
                int_fast32_t rows_value;

                if (configuration->has_property(rows_name))
                {
                    const PropertyConfiguration &pc =
                        configuration->get_property(rows_name);
                    pc.get_value(rows_value);
                    num_rows = static_cast<int>(rows_value);

                    const PropertyDefinition &pd =
                        processor.get_property(rows_name);
                    int_fast32_t minimum_rows;
                    int_fast32_t maximum_rows;
                    pd.get_minimum_value(minimum_rows);
                    pd.get_maximum_value(maximum_rows);

                    if (num_rows < minimum_rows || num_rows > maximum_rows)
                    {
                        throw std::runtime_error("Invalid number of rows for property '"
                                                  + rows_name + "'.");
                    }
                }
                else
                {
                    const PropertyDefinition &pd =
                        processor.get_property(rows_name);
                    pd.get_default_value(rows_value);
                    num_rows = static_cast<int>(rows_value);
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
                int_fast32_t columns_value;

                if (configuration->has_property(columns_name))
                {
                    const PropertyConfiguration &pc =
                        configuration->get_property(columns_name);
                    pc.get_value(columns_value);
                    num_columns = static_cast<int>(columns_value);

                    const PropertyDefinition &pd =
                        processor.get_property(columns_name);
                    int_fast32_t minimum_columns;
                    int_fast32_t maximum_columns;
                    pd.get_minimum_value(minimum_columns);
                    pd.get_maximum_value(maximum_columns);

                    if (num_columns < minimum_columns
                        || num_columns > maximum_columns)
                    {
                        throw std::runtime_error("Invalid number of columns for property '"
                                                 + columns_name + "'.");
                    }
                }
                else
                {
                    const PropertyDefinition &pd =
                        processor.get_property(columns_name);
                    pd.get_default_value(columns_value);
                    num_columns = static_cast<int>(columns_value);
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


template <typename T>
void Parameter::assign(T *value)
{
    if (dimensions != 0)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataScalar<T> *parameter_data_scalar =
        dynamic_cast<ParameterDataScalar<T> *>(this);
    parameter_data_scalar->assign(value);
}


template <typename T>
void Parameter::assign(T *value, T (*conversion_function)(T))
{
    if (dimensions != 0)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataScalar<T> *parameter_data_scalar =
        dynamic_cast<ParameterDataScalar<T> *>(this);
    parameter_data_scalar->assign(value, conversion_function);
}


template <typename T>
void Parameter::assign(T *value, std::function<void()> post_function)
{
    if (dimensions != 0)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataScalar<T> *parameter_data_scalar =
        dynamic_cast<ParameterDataScalar<T> *>(this);
    parameter_data_scalar->assign(value, post_function);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T[]> &value)
{
    if (dimensions != 1)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataVector<T> *parameter_data_vector =
        dynamic_cast<ParameterDataVector<T> *>(this);
    parameter_data_vector->assign(value);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T[]> &value, T (*conversion_function)(T))
{
    if (dimensions != 1)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataVector<T> *parameter_data_vector =
        dynamic_cast<ParameterDataVector<T> *>(this);
    parameter_data_vector->assign(value, conversion_function);
}


template <typename T>
void Parameter::assign(DspParamMemory<T[]> &value,
                       std::function<void(int)> post_function)
{
    if (dimensions != 1)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataVector<T> *parameter_data_vector =
        dynamic_cast<ParameterDataVector<T> *>(this);
    parameter_data_vector->assign(value, post_function);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T*[]> &value)
{
    if (dimensions != 2)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataMatrix<T> *parameter_data_matrix =
        dynamic_cast<ParameterDataMatrix<T> *>(this);
    parameter_data_matrix->assign(value);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T*[]> &value, T (*conversion_function)(T))
{
    if (dimensions != 2)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataMatrix<T> *parameter_data_matrix =
        dynamic_cast<ParameterDataMatrix<T> *>(this);
    parameter_data_matrix->assign(value, conversion_function);
}


template <typename T>
void Parameter::assign(DspParamMemory<T*[]> &value,
                       std::function<void(int, int)> post_function)
{
    if (dimensions != 2)
    {
        SPDLOG_CRITICAL("Parameter assigned wrong number of dimensions.");
        return;
    }

    ParameterDataMatrix<T> *parameter_data_matrix =
        dynamic_cast<ParameterDataMatrix<T> *>(this);
    parameter_data_matrix->assign(value, post_function);
}


// Using an X Macro to declare all the template specializations for each
// parameter type.
#define DECLARE_TEMPLATE_CONTROL_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string)
#define X(t) \
    template void Parameter::assign<t>(t *value); \
    template void Parameter::assign<t>(t *value, t (*conversion_function)(t)); \
    template void Parameter::assign<t>(t *value, \
                                       std::function<void()> post_function); \
    template void Parameter::assign<t>(DspCoeffMemory<t[]> &value); \
    template void Parameter::assign<t>(DspCoeffMemory<t[]> &value, \
                                       t (*conversion_function)(t)); \
    template void Parameter::assign<t>(DspParamMemory<t[]> &value, \
                                       std::function<void(int)> post_function); \
    template void Parameter::assign<t>(DspCoeffMemory<t*[]> &value); \
    template void Parameter::assign<t>(DspCoeffMemory<t*[]> &value, \
                                       t (*conversion_function)(t)); \
    template void Parameter::assign<t>(DspParamMemory<t*[]> &value, \
                                       std::function<void(int, int)> post_function);
DECLARE_TEMPLATE_CONTROL_TYPES
#undef X


int Parameter::get_num_rows() const
{
    return num_rows;
}


int Parameter::get_num_columns() const
{
    return num_columns;
}


const std::string &Parameter::get_value_type() const
{
    return value_type;
}


// Macro to create the appropriate ParameterData
#define CREATE_PARAMETER(dimension, t, definition, processor, configuration) \
    if (t == "bool")                                                        \
        return new ParameterData##dimension<bool>(definition, processor, configuration); \
    else if (t == "integer")                                                    \
        return new ParameterData##dimension<int_fast32_t>(definition, processor, configuration); \
    else if (t == "float")                                                  \
        return new ParameterData##dimension<float>(definition, processor, configuration); \
    else if (t == "string")                                                 \
        return new ParameterData##dimension<std::string>(definition, processor, configuration);


Parameter *Parameter::create(const ParameterDefinition& definition,
                             const ProcessorDefinition& processor,
                             const BlockConfiguration* configuration)
{
    const std::string& value_type = definition.get_value_type();
    int dimensions = definition.get_num_dimensions();

    switch (dimensions) {
    case 0:
        CREATE_PARAMETER(Scalar, value_type, definition, processor, configuration)
        break;

    case 1:
        CREATE_PARAMETER(Vector, value_type, definition, processor, configuration)
        break;

    case 2:
        CREATE_PARAMETER(Matrix, value_type, definition, processor, configuration)
        break;

    default:
        return nullptr;
    }

    return nullptr;
}


template <typename T>
ParameterData<T>::ParameterData(const ParameterDefinition &definition,
                                const ProcessorDefinition &processor,
                                const BlockConfiguration *configuration)
    : Parameter(definition, processor, configuration),
      conversion_function(nullptr)
{
    definition.get_default_value(default_value);

    if (definition.has_minimum_value())
    {
        definition.get_minimum_value(minimum_value);
    }

    if (definition.has_maximum_value())
    {
        std::string maximum_name;

        definition.get_maximum_value(maximum_value, maximum_name);

        if (!maximum_name.empty())
        {
            if (processor.has_property(maximum_name))
            {
                if (configuration->has_property(maximum_name))
                {
                    const PropertyConfiguration &pc =
                        configuration->get_property(maximum_name);
                    pc.get_value(maximum_value);

                    const PropertyDefinition &pd =
                        processor.get_property(maximum_name);
                    T property_minimum;
                    T property_maximum;
                    pd.get_minimum_value(property_minimum);
                    pd.get_maximum_value(property_maximum);

                    if (maximum_value < property_minimum
                        || maximum_value > property_maximum)
                    {
                        throw std::runtime_error("Invalid maximum_value for property '"
                                                 + maximum_name + "'.");
                    }
                }
                else
                {
                    const PropertyDefinition &pd =
                        processor.get_property(maximum_name);
                    pd.get_default_value(maximum_value);
                }
            }
            else if (processor.has_terminal(maximum_name))
            {
                if (configuration->has_terminal(maximum_name))
                {
                    const TerminalConfiguration &tc =
                        configuration->get_terminal(maximum_name);
                    maximum_value = tc.get_num_channels();
                }
            }
            else
            {
                SPDLOG_ERROR("Parameter '{}' has maximum_value '{}' but no property or terminal with that name.",
                             definition.get_name(), maximum_name);
                maximum_value = default_value;
            }
        }
    }

    if (definition.has_maximum_length())
    {
        maximum_length = definition.get_maximum_length();
    }

    if (definition.has_allowed_values())
    {
        definition.get_allowed_values(allowed_values);
    }
}

template <typename T>
void ParameterData<T>::get_setting_value(const ParameterSetting &setting,
                                         T &value) const
{
    T preliminary_value;

    setting.get_value(preliminary_value);

    if (!allowed_values.empty())
    {
        // Both numeric types and strings can have allowed values, so check
        // that first.
        if (allowed_values.count(preliminary_value) == 0)
        {
            throw std::runtime_error("Parameter setting value not allowed.");
        }
    }
    else if constexpr(std::is_same_v<T, int_fast32_t>
                      || std::is_same_v<T, float>)
    {
        // Numeric types must have minimum/maximum if they don't have
        // allowed values.
        if (preliminary_value < minimum_value
            || preliminary_value > maximum_value)
        {
            throw std::runtime_error("Parameter setting value out of range.");
        }
    }
    else if constexpr(std::is_same_v<T, std::string>)
    {
        // Strings must have a maximum length if they don't have allowed
        // values.
        if (maximum_length > 0 && preliminary_value.length() > maximum_length)
        {
            throw std::runtime_error("Parameter setting value string too long.");
        }
    }

    if (conversion_function != nullptr)
    {
        value = conversion_function(preliminary_value);
    }
    else
    {
        value = preliminary_value;
    }
}


template <typename T>
ParameterDataScalar<T>::ParameterDataScalar(const ParameterDefinition &definition,
                                            const ProcessorDefinition &processor,
                                            const BlockConfiguration *configuration)
    : ParameterData<T>(definition, processor, configuration),
      block_value(nullptr), post_function(nullptr)
{
}


template <typename T>
void ParameterDataScalar<T>::assign(T *value)
{
    block_value = value;
    *block_value = this->default_value;
}


template <typename T>
void ParameterDataScalar<T>::assign(T *value, T (*conversion_function)(T))
{
    block_value = value;
    this->conversion_function = conversion_function;
    *block_value = conversion_function(this->default_value);
}


template <typename T>
void ParameterDataScalar<T>::assign(T *value, std::function<void()> post_function)
{
    block_value = value;
    *block_value = this->default_value;
    this->post_function = post_function;
}


template <typename T>
void ParameterDataScalar<T>::initialize_post()
{
    if (post_function != nullptr)
    {
        post_function();
    }
}


template <typename T>
void ParameterDataScalar<T>::set(const ParameterSetting &setting)
{
    if (setting.has_row())
    {
        throw std::runtime_error("Parameter setting has unexpected index.");
    }

    T value;

    this->get_setting_value(setting, value);

    *block_value = value;

    if (post_function != nullptr)
    {
        post_function();
    }
}


template <typename T>
ParameterDataVector<T>::ParameterDataVector(const ParameterDefinition &definition,
                                            const ProcessorDefinition &processor,
                                            const BlockConfiguration *configuration)
    : ParameterData<T>(definition, processor, configuration),
      block_value(nullptr), post_function(nullptr)
{
}


template <typename T>
void ParameterDataVector<T>::assign(DspCoeffMemory<T[]> &value)
{
    SPDLOG_TRACE("resizing {}", this->get_num_rows());
    value.resize(this->get_num_rows());
    block_value = value.get();

    for (int row = 0; row < this->get_num_rows(); row++)
    {
        value[row] = this->default_value;
    }
}


template <typename T>
void ParameterDataVector<T>::assign(DspCoeffMemory<T[]> &value,
                                    T (*conversion_function)(T))
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


template <typename T>
void ParameterDataVector<T>::assign(DspParamMemory<T[]> &value,
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


template <typename T>
void ParameterDataVector<T>::initialize_post()
{
    if (post_function != nullptr)
    {
        for (int row = 0; row < this->get_num_rows(); row++)
        {
            post_function(row);
        }
    }
}


template <typename T>
void ParameterDataVector<T>::set(const ParameterSetting &setting)
{
    int row = setting.get_row();
    T value;
    setting.get_value(value);

    if (row < 0 || row >= this->get_num_rows())
    {
        throw std::runtime_error("Parameter setting index out of range.");
    }

    if (setting.has_column())
    {
        throw std::runtime_error("Parameter setting has unexpected index.");
    }

    this->get_setting_value(setting, value);

    block_value[row] = value;

    if (post_function != nullptr)
    {
        post_function(row);
    }
}


template <typename T>
ParameterDataMatrix<T>::ParameterDataMatrix(const ParameterDefinition &definition,
                                            const ProcessorDefinition &processor,
                                            const BlockConfiguration *configuration)
    : ParameterData<T>(definition, processor, configuration),
      block_value(nullptr), post_function(nullptr)
{
}


template <typename T>
void ParameterDataMatrix<T>::assign(DspCoeffMemory<T*[]> &value)
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


template <typename T>
void ParameterDataMatrix<T>::assign(DspCoeffMemory<T*[]> &value,
                                    T (*conversion_function)(T))
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


template <typename T>
void ParameterDataMatrix<T>::assign(DspParamMemory<T*[]> &value,
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


template <typename T>
void ParameterDataMatrix<T>::initialize_post()
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


template <typename T>
void ParameterDataMatrix<T>::set(const ParameterSetting &setting)
{
    int row = setting.get_row();
    int column = setting.get_column();
    T value;
    setting.get_value(value);

    if (row < 0 || row >= this->get_num_rows()
        || column < 0 || column >= this->get_num_columns())
    {
        throw std::runtime_error("Parameter setting index out of range.");
    }

    this->get_setting_value(setting, value);

    block_value[row][column] = value;

    if (post_function != nullptr)
    {
        post_function(row, column);
    }
}


} // namespace bosepro
