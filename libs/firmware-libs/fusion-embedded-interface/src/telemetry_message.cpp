
#include <bosepro/telemetry_message.h>

#include <unistd.h>

#include <chrono>
#include <iostream>
#include <string>
#include <vector>

namespace bosepro {


TelemetryMessage::TelemetryMessage(const std::string &filename)
    : Navigator(filename)
{
}


TelemetryMessage::TelemetryMessage(std::stringstream &ss)
    : Navigator(ss)
{
}


TelemetryMessage TelemetryMessage::get_default_command(const std::string name)
{
    return (TelemetryMessage &)list_get_member("telemetry_messages",
                                               "message_name", name);
}


TelemetryMessage TelemetryMessage::get_default_meter()
{
    return (TelemetryMessage &)list_get_member("telemetry_messages",
                                               "meter_name", "");
}


TelemetryMessage TelemetryMessage::get_default_event()
{
    return (TelemetryMessage &)list_get_member("telemetry_messages",
                                               "message_name", "event");
}


const std::string TelemetryMessage::get_message_name() const
{
    return get_string("message_name");
}


TelemetryMessage &TelemetryMessage::get_parameters() const
{
    return (TelemetryMessage &)get_member("parameters");
}


const std::string TelemetryMessage::get_name() const
{
    return get_string("name");
}


const std::string TelemetryMessage::get_value() const
{
    return get_string("value");
}


const std::string TelemetryMessage::get_type() const
{
    return get_string("type");
}


const std::string TelemetryMessage::get_period_type() const
{
    return get_string("period_type");
}


const std::string TelemetryMessage::get_packet_id() const
{
    return get_string("packet_id");
}

int_fast32_t TelemetryMessage::get_protocol_version() const
{
    int_fast32_t value = 0;
    get_member_value("protocol_version", value);
    return value;
}

int_fast32_t TelemetryMessage::get_schema_version() const
{
    int_fast32_t value = 0;
    get_member_value("schema_version", value);
    return value;
}

bool TelemetryMessage::try_get_protocol_version(int_fast32_t &value) const
{
    return try_member_value("protocol_version", value);
}

bool TelemetryMessage::try_get_schema_version(int_fast32_t &value) const
{
    return try_member_value("schema_version", value);
}

bool TelemetryMessage::has_supported_telemetry_versions() const
{
    int_fast32_t protocol_version = 0;
    int_fast32_t schema_version = 0;
    const auto &parameters = get_parameters();

    if (!parameters.try_get_protocol_version(protocol_version)) {
        return false;
    }

    if (!parameters.try_get_schema_version(schema_version)) {
        return false;
    }

    return is_supported_telemetry_protocol_version(protocol_version) &&
           is_supported_telemetry_schema_version(schema_version);
}


std::vector<std::string> TelemetryMessage::get_block_name() const
{
    const std::string block_name_key = "block_name";
    std::vector<std::string> block_name(3, "");

    get_list_value(block_name_key, 0, block_name[0]);
    get_list_value(block_name_key, 1, block_name[1]);
    get_list_value(block_name_key, 2, block_name[2]);

    return block_name;
}


std::vector<std::string> TelemetryMessage::get_block_size() const
{
    const std::string block_size_key = "block_size";
    std::vector<std::string> block_size(3, "");

    get_list_value(block_size_key, 0, block_size[0]);
    get_list_value(block_size_key, 1, block_size[1]);
    get_list_value(block_size_key, 2, block_size[2]);

    return block_size;
}


void TelemetryMessage::set_name(const std::string &value)
{
    set_member("name", value);
}


void TelemetryMessage::set_block_name(const std::string &value)
{
    set_member("block_name", value);
}


void TelemetryMessage::set_meter_name(const std::string &value)
{
    set_member("meter_name", value);
}


void TelemetryMessage::set_event_name(const std::string &value)
{
    set_member("event_name", value);
}


void TelemetryMessage::set_dimensions(const std::string &value)
{
    set_member("dimensions", value);
}


void TelemetryMessage::set_value_type(const std::string &value)
{
    set_member("value_type", value);
}


template <typename T>
void TelemetryMessage::set_value(const T &value)
{
    set_member("value", value);
}


template <typename T>
void TelemetryMessage::set_value(const std::vector<T>& vec)
{
    set_list("value", vec);
}


template <typename T>
void TelemetryMessage::set_value(const std::vector<std::vector<T>>& mat)
{
    set_list("value", mat);
}


template <typename T>
void TelemetryMessage::set_type(const T &value)
{
    set_member("type", value);
}


void TelemetryMessage::set_packet_id()
{
    auto now = std::chrono::steady_clock::now();
    auto now_us = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();
    set_member("packet_id", static_cast<uint64_t>(now_us));
}


void TelemetryMessage::set_packet_id(std::string timestamp)
{
    set_member("packet_id", timestamp);
}


void TelemetryMessage::set_block_size(const std::vector<int_fast32_t> &block_size)
{
    set_list("block_size", block_size);
}


const std::string TelemetryMessage::serialize_message() const
{
    return serialize();
}


#define DECLARE_TEMPLATE_TELEMETRY_MESSAGE_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(std::string)
#define X(t) \
    template void TelemetryMessage::set_value<t>(const t &value); \
    template void TelemetryMessage::set_value<t>(const std::vector<t> &value); \
    template void TelemetryMessage::set_value<t>(const std::vector<std::vector<t>> &value); \
    template void TelemetryMessage::set_type<t>(const t &value);
DECLARE_TEMPLATE_TELEMETRY_MESSAGE_TYPES
#undef X


} // namespace bosepro
