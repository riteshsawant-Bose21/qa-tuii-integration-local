
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/parameter.h>

#include <cstdint>
#include <functional>
#include <string>


namespace bosepro {


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


} // namespace bosepro
