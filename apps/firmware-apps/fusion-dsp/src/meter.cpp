
#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/meter.h>
#include <bosepro/parameters.h>

#include <cstdint>
#include <string>


namespace bosepro {


template <typename T>
void Meter::assign(const T *value)
{
    MeterData<T> *meter_data = dynamic_cast<MeterData<T> *>(this);
    meter_data->assign(value);
}


template <typename T>
void Meter::assign(DspMeterMemory<T[]> &value)
{
    MeterData<T> *meter_data = dynamic_cast<MeterData<T> *>(this);
    meter_data->assign(value);
}


template <typename T>
void Meter::assign(DspMeterMemory<T*[]> &value)
{
    MeterData<T> *meter_data = dynamic_cast<MeterData<T> *>(this);
    meter_data->assign(value);
}


// Using an X Macro to declare all the template specializations for each
// meter type.
#define DECLARE_TEMPLATE_METER_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string)
#define X(t) \
    template void Meter::assign<t>(const t *value); \
    template void Meter::assign<t>(DspMeterMemory<t[]> &value); \
    template void Meter::assign<t>(DspMeterMemory<t*[]> &value);
DECLARE_TEMPLATE_METER_TYPES
#undef X


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


template<>
void MeterData<int_fast32_t>::print_value(std::ostringstream &message, const int_fast32_t &value)
{
    message << value;
}


template<>
void MeterData<float>::print_value(std::ostringstream &message, const float &value)
{
    message << value;
}


template<>
void MeterData<bool>::print_value(std::ostringstream &message, const bool &value)
{
    message << (value ? "true" : "false");
}


template<>
void MeterData<std::string>::print_value(std::ostringstream &message, const std::string &value)
{
    message << "\"" << value << "\"";
}


} // namespace bosepro
