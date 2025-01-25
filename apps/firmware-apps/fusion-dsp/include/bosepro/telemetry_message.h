#pragma once

#include <bosepro/navigator.h>

#include <string>
#include <unistd.h>
#include <iostream>


namespace bosepro {


/// A navigator with mutability for telemetry message json file
class TelemetryMessage : public Navigator {
public:
    /// Build the command definitions for the system from the given JSON file.
    ///
    /// @param  filename  A JSON file containing the interface definitions.
    TelemetryMessage(const std::string &filename)
        : Navigator(filename)
    {
    }


    /// Build the command definitions for the system from the given JSON file.
    ///
    /// @param  ss  A string stream containing a JSON string.
    TelemetryMessage(std::stringstream &ss)
        : Navigator(ss)
    {
    }


    /// Get the json blob for the default command with name "name".
    ///
    /// @return  TelemetryMessage of the command node
    TelemetryMessage get_default_command(const std::string name)
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "message_name", name);
    }


    /// Get the json blob for the default meter update node.
    ///
    /// @return  TelemetryMessage of the meter update node
    TelemetryMessage get_default_meter()
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "meter_name", "");
    }


    /// Get the json blob for the default event node.
    ///
    /// @return  TelemetryMessage of the event node
    TelemetryMessage get_default_event()
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "message_name", "event");
    }


    /// Get the name of the TelemetryMessage.
    ///
    /// @return  The name of the TelemetryMessage.
    const std::string get_message_name() const
    {
        return get_string("message_name");
    }


    /// Get the parameters node json 
    ///
    /// @return  TelemetryMessage of parameters node.
    TelemetryMessage &get_parameters() const
    {
        return (TelemetryMessage &)get_member("parameters");
    }


    /// Get the string from "value" property.
    ///
    /// @return  The string value of "value"
    const std::string get_value() const
    {
        return get_string("value");
    }


    /// Get the string from "type" property.
    ///
    /// @return  The string value of "type"
    const std::string get_type() const
    {
        return get_string("type");
    }


    /// Get the string from "period_type" property.
    ///
    /// @return  The string value of "period_type"
    const std::string get_period_type() const
    {
        return get_string("period_type");
    }


    /// Get the string from "packet_id" property.
    ///
    /// @return  The string value of "packet_id"
    const std::string get_packet_id() const
    {
        return get_string("packet_id");
    }


    /// Get the "block_name" array.
    ///
    /// @return  The block_name array
    std::vector<std::string> get_block_name() const
    {
        const std::string block_name_key = "block_name";
        std::vector<std::string> block_name(3, "");

        get_list_value(block_name_key, 0, block_name[0]);
        get_list_value(block_name_key, 1, block_name[1]);
        get_list_value(block_name_key, 2, block_name[2]);

        return block_name;
    }


    /// Get the "block_size" array.
    ///
    /// @return  The block_size array
    std::vector<std::string> get_block_size() const
    {
        const std::string block_size_key = "block_size";
        std::vector<std::string> block_size(3, "");

        get_list_value(block_size_key, 0, block_size[0]);
        get_list_value(block_size_key, 1, block_size[1]);
        get_list_value(block_size_key, 2, block_size[2]);

        return block_size;
    }


    /// Set the parameters.name value.
    ///
    /// @param value  The value to set parameters.value.
    void set_name(const std::string &value)
    {
        set_member("name", value);
    }


    /// Set the parameters.value value.
    ///
    /// @param value  The value to set parameters.value.
    template <typename T>
    void set_value(const T &value)
    {
        set_member("value", value);
    }


    /// Set the parameters.value value for value is a vector.
    ///
    /// @param vec  The value to set parameters.value.
    template <typename T>
    void set_value(const std::vector<T>& vec)
    {
        // Vector type, so set it as a list/array
        set_list("value", vec);
    }


    /// Set the parameters.value value for value is a matrix.
    ///
    /// @param value  The value to set parameters.value.
    template <typename T>
    void set_value(const std::vector<std::vector<T>>& mat)
    {
        // Vector type, so set it as a list/array
        set_list("value", mat);
    }


    /// Set the parameters.type value.
    ///
    /// @param value  The value to set parameters.type.
    template <typename T>
    void set_type(const T &value)
    {
        set_member("type", value);
    }


    /// Generate a timestamp and set the packet_id with it.
    void set_packet_id()
    {
        auto now = std::chrono::steady_clock::now();
        auto now_us = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();
        set_member("packet_id", static_cast<uint64_t>(now_us));
    }


    /// Set the packet_id value with the specified timestamp.
    ///
    /// @param timestamp  The value to set packet_id.
    void set_packet_id(std::string timestamp)
    {
        set_member("packet_id", timestamp);
    }


    /// Set the "block_size" array in the "parameters" object.
    /// If "block_size" exists, it will be updated with the new values.
    /// If it does not exist, an error is logged, and an exception is thrown.
    ///
    /// @param block_size The array of block sizes to set.
    void set_block_size(const std::vector<size_t> &block_size)
    {
        set_list("block_size", block_size);
    }


    /// Serialize the telemetry message.
    ///
    /// @return  The json blob string
    const std::string serialize_message() const
    {
        return serialize();
    }
};


} // namespace bosepro
