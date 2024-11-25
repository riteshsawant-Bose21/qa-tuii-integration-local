
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
    dimensions = 0;
    ParameterDataScalar<T> *parameter_data_scalar =
        dynamic_cast<ParameterDataScalar<T> *>(this);
    parameter_data_scalar->assign(value);
}


template <typename T>
void Parameter::assign(T *value, T (*conversion_function)(T))
{
    dimensions = 0;
    ParameterDataScalar<T> *parameter_data_scalar =
        dynamic_cast<ParameterDataScalar<T> *>(this);
    parameter_data_scalar->assign(value, conversion_function);
}


template <typename T>
void Parameter::assign(T *value, std::function<void()> post_function)
{
    dimensions = 0;
    ParameterDataScalar<T> *parameter_data_scalar =
        dynamic_cast<ParameterDataScalar<T> *>(this);
    parameter_data_scalar->assign(value, post_function);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T[]> &value)
{
    dimensions = 1;
    ParameterDataVector<T> *parameter_data_vector =
        dynamic_cast<ParameterDataVector<T> *>(this);
    parameter_data_vector->assign(value);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T[]> &value, T (*conversion_function)(T))
{
    dimensions = 1;
    ParameterDataVector<T> *parameter_data_vector =
        dynamic_cast<ParameterDataVector<T> *>(this);
    parameter_data_vector->assign(value, conversion_function);
}


template <typename T>
void Parameter::assign(DspParamMemory<T[]> &value,
                       std::function<void(int)> post_function)
{
    dimensions = 1;
    ParameterDataVector<T> *parameter_data_vector =
        dynamic_cast<ParameterDataVector<T> *>(this);
    parameter_data_vector->assign(value, post_function);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T*[]> &value)
{
    dimensions = 2;
    ParameterDataMatrix<T> *parameter_data_matrix =
        dynamic_cast<ParameterDataMatrix<T> *>(this);
    parameter_data_matrix->assign(value);
}


template <typename T>
void Parameter::assign(DspCoeffMemory<T*[]> &value, T (*conversion_function)(T))
{
    dimensions = 2;
    ParameterDataMatrix<T> *parameter_data_matrix =
        dynamic_cast<ParameterDataMatrix<T> *>(this);
    parameter_data_matrix->assign(value, conversion_function);
}


template <typename T>
void Parameter::assign(DspParamMemory<T*[]> &value,
                       std::function<void(int, int)> post_function)
{
    dimensions = 2;
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


Parameter *Parameter::create(const ParameterDefinition &definition,
                             const AlgorithmDefinition &algorithm,
                             const BlockConfiguration *configuration)
{
    const std::string &value_type = definition.get_value_type();
    int dimensions = definition.get_num_dimensions();

    switch (dimensions)
    {
    case 0:
        if (value_type == "bool")
        {
            return new ParameterDataScalar<bool>(definition, algorithm,
                                                 configuration);
        }
        else if (value_type == "integer")
        {
            return new ParameterDataScalar<int_fast32_t>(definition, algorithm,
                                                         configuration);
        }
        else if (value_type == "float")
        {
            return new ParameterDataScalar<float>(definition, algorithm,
                                                  configuration);
        }
        else if (value_type == "string")
        {
            return new ParameterDataScalar<std::string>(definition, algorithm,
                                                        configuration);
        }
        break;

    case 1:
        if (value_type == "bool")
        {
            return new ParameterDataVector<bool>(definition, algorithm,
                                                 configuration);
        }
        else if (value_type == "integer")
        {
            return new ParameterDataVector<int_fast32_t>(definition, algorithm,
                                                         configuration);
        }
        else if (value_type == "float")
        {
            return new ParameterDataVector<float>(definition, algorithm,
                                                  configuration);
        }
        else if (value_type == "string")
        {
            return new ParameterDataVector<std::string>(definition, algorithm,
                                                        configuration);
        }
        break;

    case 2:
        if (value_type == "bool")
        {
            return new ParameterDataMatrix<bool>(definition, algorithm,
                                                 configuration);
        }
        else if (value_type == "integer")
        {
            return new ParameterDataMatrix<int_fast32_t>(definition, algorithm,
                                                         configuration);
        }
        else if (value_type == "float")
        {
            return new ParameterDataMatrix<float>(definition, algorithm,
                                                  configuration);
        }
        else if (value_type == "string")
        {
            return new ParameterDataMatrix<std::string>(definition, algorithm,
                                                        configuration);
        }
        break;

    default:
        return nullptr;
    }

    return nullptr;
}


} // namespace bosepro
