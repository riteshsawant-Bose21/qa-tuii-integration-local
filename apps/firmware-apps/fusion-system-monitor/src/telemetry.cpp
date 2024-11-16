
#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/telemetry.h>
#include <bosepro/parameters.h>

#include <cstdint>
#include <string>


namespace bosepro {


template <typename T>
void Telemetry::assign(const T *value)
{
    TelemetryData<T> *meter_data = dynamic_cast<TelemetryData<T> *>(this);
    meter_data->assign(value);
}


template <typename T>
void Telemetry::assign(DspTelemetryMemory<T[]> &value)
{
    TelemetryData<T> *meter_data = dynamic_cast<TelemetryData<T> *>(this);
    meter_data->assign(value);
}


template <typename T>
void Telemetry::assign(DspTelemetryMemory<T*[]> &value)
{
    TelemetryData<T> *meter_data = dynamic_cast<TelemetryData<T> *>(this);
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
    template void Telemetry::assign<t>(const t *value); \
    template void Telemetry::assign<t>(DspTelemetryMemory<t[]> &value); \
    template void Telemetry::assign<t>(DspTelemetryMemory<t*[]> &value);
DECLARE_TEMPLATE_METER_TYPES
#undef X


Telemetry *Telemetry::create(const TelemetryParameter &parameter,
                     const TelemetryConfiguration *configuration)
{
    const std::string &value_type = parameter.get_value_type();

    if (value_type == "bool")
    {
        return new TelemetryData<bool>(parameter, configuration);
    }
    else if (value_type == "int")
    {
        return new TelemetryData<int_fast32_t>(parameter, configuration);
    }
    else if (value_type == "float")
    {
        return new TelemetryData<float>(parameter, configuration);
    }
    else if (value_type == "string")
    {
        return new TelemetryData<std::string>(parameter, configuration);
    }

    return nullptr;
}


template<>
void TelemetryData<int_fast32_t>::print_value(std::ostringstream &message, const int_fast32_t &value)
{
    message << value;
}


template<>
void TelemetryData<float>::print_value(std::ostringstream &message, const float &value)
{
    message << value;
}


template<>
void TelemetryData<bool>::print_value(std::ostringstream &message, const bool &value)
{
    message << (value ? "true" : "false");
}


template<>
void TelemetryData<std::string>::print_value(std::ostringstream &message, const std::string &value)
{
    message << "\"" << value << "\"";
}


} // namespace bosepro
