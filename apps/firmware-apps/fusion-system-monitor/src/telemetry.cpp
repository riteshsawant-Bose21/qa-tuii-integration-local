
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/telemetry.h>

#include <cstdint>
#include <functional>
#include <string>


namespace bosepro {


template <typename T>
void Telemetry::assign(const T *value)
{
    TelemetryDataScalar<T> *telemetry_data = dynamic_cast<TelemetryDataScalar<T> *>(this);
    telemetry_data->assign(value);
}


template <typename T>
void Telemetry::assign(const T *value, std::function<void()> pre_function)
{
    TelemetryDataScalar<T> *telemetry_data = dynamic_cast<TelemetryDataScalar<T> *>(this);
    telemetry_data->assign(value, pre_function);
}


template <typename T>
void Telemetry::assign(DspTelemetryMemory<T[]> &value)
{
    TelemetryDataVector<T> *telemetry_data = dynamic_cast<TelemetryDataVector<T> *>(this);
    telemetry_data->assign(value);
}


template <typename T>
void Telemetry::assign(DspTelemetryMemory<T[]> &value, std::function<void(int)> pre_function)
{
    TelemetryDataVector<T> *telemetry_data = dynamic_cast<TelemetryDataVector<T> *>(this);
    telemetry_data->assign(value, pre_function);
}


template <typename T>
void Telemetry::assign(DspTelemetryMemory<T*[]> &value)
{
    TelemetryDataMatrix<T> *telemetry_data = dynamic_cast<TelemetryDataMatrix<T> *>(this);
    telemetry_data->assign(value);
}


template <typename T>
void Telemetry::assign(DspTelemetryMemory<T*[]> &value, std::function<void(int, int)> pre_function)
{
    TelemetryDataMatrix<T> *telemetry_data = dynamic_cast<TelemetryDataMatrix<T> *>(this);
    telemetry_data->assign(value, pre_function);
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
    template void Telemetry::assign<t>(const t *value, std::function<void()> pre_function); \
    template void Telemetry::assign<t>(DspTelemetryMemory<t[]> &value); \
    template void Telemetry::assign<t>(DspTelemetryMemory<t[]> &value, std::function<void(int)> pre_function); \
    template void Telemetry::assign<t>(DspTelemetryMemory<t*[]> &value); \
    template void Telemetry::assign<t>(DspTelemetryMemory<t*[]> &value, std::function<void(int, int)> pre_function);
DECLARE_TEMPLATE_METER_TYPES
#undef X


Telemetry *Telemetry::create(const TelemetryDefinition &definition,
                             const ProcessorDefinition &processor,
                             const BlockConfiguration *configuration)
{
    const std::string &value_type = definition.get_value_type();
    int dimensions = definition.get_num_dimensions();

    switch(dimensions) {
    case 0:
        if (value_type == "bool")
        {
            return new TelemetryDataScalar<bool>(definition, processor, configuration);
        }
        else if (value_type == "int")
        {
            return new TelemetryDataScalar<int_fast32_t>(definition,  processor, configuration);
        }
        else if (value_type == "float")
        {
            return new TelemetryDataScalar<float>(definition,  processor, configuration);
        }
        else if (value_type == "string")
        {
            return new TelemetryDataScalar<std::string>(definition,  processor, configuration);
        }
        break;
    case 1:
        if (value_type == "bool")
        {
            return new TelemetryDataVector<bool>(definition, processor, configuration);
        }
        else if (value_type == "int")
        {
            return new TelemetryDataVector<int_fast32_t>(definition, processor, configuration);
        }
        else if (value_type == "float")
        {
            return new TelemetryDataVector<float>(definition, processor, configuration);
        }
        else if (value_type == "string")
        {
            return new TelemetryDataVector<std::string>(definition, processor, configuration);
        }
        break;
    case 2:
        if (value_type == "bool")
        {
            return new TelemetryDataMatrix<bool>(definition, processor, configuration);
        }
        else if (value_type == "int")
        {
            return new TelemetryDataMatrix<int_fast32_t>(definition, processor, configuration);
        }
        else if (value_type == "float")
        {
            return new TelemetryDataMatrix<float>(definition, processor, configuration);
        }
        else if (value_type == "string")
        {
            return new TelemetryDataMatrix<std::string>(definition, processor, configuration);
        }
        break;
    default:
        return nullptr;
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
