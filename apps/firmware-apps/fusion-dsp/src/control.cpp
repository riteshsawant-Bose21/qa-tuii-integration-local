
#include <bosepro/configuration.h>
#include <bosepro/control.h>
#include <bosepro/parameters.h>

#include <cstdint>
#include <functional>
#include <string>
#include <vector>


namespace bosepro {


template <typename T>
void Control::assign(T *value, std::function<void()> post_function)
{
    dimensions = 0;
    ControlDataScalar<T> *control_data_scalar =
        dynamic_cast<ControlDataScalar<T> *>(this);
    control_data_scalar->assign(value, post_function);
}


template <typename T>
void Control::assign(std::vector<T> *value,
                     std::function<void(int)> post_function)
{
    dimensions = 1;
    ControlDataVector<T> *control_data_vector =
        dynamic_cast<ControlDataVector<T> *>(this);
    control_data_vector->assign(value, post_function);
}


template <typename T>
void Control::assign(std::vector<std::vector<T>> *value, 
                     std::function<void(int, int)> post_function)
{
    dimensions = 2;
    ControlDataMatrix<T> *control_data_matrix =
        dynamic_cast<ControlDataMatrix<T> *>(this);
    control_data_matrix->assign(value, post_function);
}


template void Control::assign<bool>(bool *value,
                                    std::function<void()> post_function);
template void Control::assign<float>(float *value, 
                                     std::function<void()> post_function);
template void Control::assign<int_fast32_t>(int_fast32_t *value, 
                                            std::function<void()> post_function);
template void Control::assign<std::string>(std::string *value, 
                                           std::function<void()> post_function);
template void Control::assign<bool>(std::vector<bool> *value, 
                                    std::function<void(int)> post_function);
template void Control::assign<float>(std::vector<float> *value, 
                                     std::function<void(int)> post_function);
template void Control::assign<int_fast32_t>(std::vector<int_fast32_t> *value, 
                                            std::function<void(int)> post_function);
template void Control::assign<std::string>(std::vector<std::string> *value, 
                                           std::function<void(int)> post_function);
template void Control::assign<bool>(std::vector<std::vector<bool>> *value, 
                                    std::function<void(int, int)> post_function);
template void Control::assign<float>(std::vector<std::vector<float>> *value, 
                                     std::function<void(int, int)> post_function);
template void Control::assign<int_fast32_t>(
        std::vector<std::vector<int_fast32_t>> *value,
        std::function<void(int, int)> post_function);
template void Control::assign<std::string>(
        std::vector<std::vector<std::string>> *value,
        std::function<void(int, int)> post_function);


Control *Control::create(const ControlParameter &parameter,
                         const ControlConfiguration *configuration)
{
    const std::string &value_type = parameter.get_value_type();
    int dimensions = parameter.get_dimensions();

    switch (dimensions)
    {
    case 0:
        if (value_type == "bool")
        {
            return new ControlDataScalar<bool>(parameter, configuration);
        }
        else if (value_type == "int")
        {
            return new ControlDataScalar<int_fast32_t>(parameter, configuration);
        }
        else if (value_type == "float")
        {
            return new ControlDataScalar<float>(parameter, configuration);
        }
        else if (value_type == "string")
        {
            return new ControlDataScalar<std::string>(parameter, configuration);
        }
        break;

    case 1:
        if (value_type == "bool")
        {
            return new ControlDataVector<bool>(parameter, configuration);
        }
        else if (value_type == "int")
        {
            return new ControlDataVector<int_fast32_t>(parameter, configuration);
        }
        else if (value_type == "float")
        {
            return new ControlDataVector<float>(parameter, configuration);
        }
        else if (value_type == "string")
        {
            return new ControlDataVector<std::string>(parameter, configuration);
        }
        break;

    case 2:
        if (value_type == "bool")
        {
            return new ControlDataMatrix<bool>(parameter, configuration);
        }
        else if (value_type == "int")
        {
            return new ControlDataMatrix<int_fast32_t>(parameter, configuration);
        }
        else if (value_type == "float")
        {
            return new ControlDataMatrix<float>(parameter, configuration);
        }
        else if (value_type == "string")
        {
            return new ControlDataMatrix<std::string>(parameter, configuration);
        }
        break;

    default:
        return nullptr;
    }

    return nullptr;
}


} // namespace bosepro
