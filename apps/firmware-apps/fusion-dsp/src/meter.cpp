
#include <bosepro/configuration.h>
#include <bosepro/meter.h>
#include <bosepro/parameters.h>

#include <cstdint>
#include <string>
#include <vector>


namespace bosepro {


template <typename T>
void Meter::assign(const T *value)
{
    MeterData<T> *meter_data = dynamic_cast<MeterData<T> *>(this);
    meter_data->assign(value);
}


template <typename T>
void Meter::assign(std::vector<T> *value)
{
    MeterData<T> *meter_data = dynamic_cast<MeterData<T> *>(this);
    meter_data->assign(value);
}


template <typename T>
void Meter::assign(std::vector<std::vector<T>> *value)
{
    MeterData<T> *meter_data = dynamic_cast<MeterData<T> *>(this);
    meter_data->assign(value);
}


template void Meter::assign<bool>(const bool *value);
template void Meter::assign<float>(const float *value);
template void Meter::assign<int_fast32_t>(const int_fast32_t *value);
template void Meter::assign<std::string>(const std::string *value);
template void Meter::assign<bool>(std::vector<bool> *value);
template void Meter::assign<float>(std::vector<float> *value);
template void Meter::assign<int_fast32_t>(std::vector<int_fast32_t> *value);
template void Meter::assign<std::string>(std::vector<std::string> *value);
template void Meter::assign<bool>(std::vector<std::vector<bool>> *value);
template void Meter::assign<float>(std::vector<std::vector<float>> *value);
template void Meter::assign<int_fast32_t>(
        std::vector<std::vector<int_fast32_t>> *value);
template void Meter::assign<std::string>(
        std::vector<std::vector<std::string>> *value);


Meter *Meter::create(const MeterParameter &parameter,
                     const MeterConfiguration *configuration)
{
    const std::string &value_type = parameter.get_value_type();

    if (value_type == "bool")
    {
        return new MeterData<bool>(parameter, configuration);
    }
    else if (value_type == "int")
    {
        return new MeterData<int_fast32_t>(parameter, configuration);
    }
    else if (value_type == "float")
    {
        return new MeterData<float>(parameter, configuration);
    }
    else if (value_type == "string")
    {
        return new MeterData<std::string>(parameter, configuration);
    }

    return nullptr;
}


} // namespace bosepro
