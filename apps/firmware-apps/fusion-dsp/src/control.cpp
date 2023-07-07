
#include <bosepro/configuration.h>
#include <bosepro/control.h>
#include <bosepro/parameters.h>

#include <cstdint>
#include <string>
#include <vector>


namespace bosepro {


template <typename T>
void Control::assign(T *value)
{
    ControlData<T> *control_data = dynamic_cast<ControlData<T> *>(this);
    control_data->assign(value);
}


template <typename T>
void Control::assign(std::vector<T> *value)
{
    ControlData<T> *control_data = dynamic_cast<ControlData<T> *>(this);
    control_data->assign(value);
}


template <typename T>
void Control::assign(std::vector<std::vector<T>> *value)
{
    ControlData<T> *control_data = dynamic_cast<ControlData<T> *>(this);
    control_data->assign(value);
}


template void Control::assign<bool>(bool *value);
template void Control::assign<float>(float *value);
template void Control::assign<int_fast32_t>(int_fast32_t *value);
template void Control::assign<std::string>(std::string *value);
template void Control::assign<bool>(std::vector<bool> *value);
template void Control::assign<float>(std::vector<float> *value);
template void Control::assign<int_fast32_t>(std::vector<int_fast32_t> *value);
template void Control::assign<std::string>(std::vector<std::string> *value);
template void Control::assign<bool>(std::vector<std::vector<bool>> *value);
template void Control::assign<float>(std::vector<std::vector<float>> *value);
template void Control::assign<int_fast32_t>(
        std::vector<std::vector<int_fast32_t>> *value);
template void Control::assign<std::string>(
        std::vector<std::vector<std::string>> *value);


Control *Control::create(const ControlParameter &parameter,
                         const ControlConfiguration *configuration)
{
    const std::string &value_type = parameter.get_value_type();

    if (value_type == "bool")
    {
        return new ControlData<bool>(parameter, configuration);
    }
    else if (value_type == "int")
    {
        return new ControlData<int_fast32_t>(parameter, configuration);
    }
    else if (value_type == "float")
    {
        return new ControlData<float>(parameter, configuration);
    }
    else if (value_type == "string")
    {
        return new ControlData<std::string>(parameter, configuration);
    }

    return nullptr;
}


} // namespace bosepro
