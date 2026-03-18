#pragma once

#include <bosepro/navigator.h>
#include <bosepro/telemetry_version.h>

#include <cstdint>
#include <string>
#include <vector>


namespace bosepro {


/// A navigator with mutability for telemetry message json file
class TelemetryMessage : public Navigator {
public:
    /// Build the command definitions for the system from the given JSON file.
    ///
    /// @param  filename  A JSON file containing the interface definitions.
    TelemetryMessage(const std::string &filename);


    /// Build the command definitions for the system from the given JSON file.
    ///
    /// @param  ss  A string stream containing a JSON string.
    TelemetryMessage(std::stringstream &ss);


    /// Get the json blob for the default command with name "name".
    ///
    /// @return  TelemetryMessage of the command node
    TelemetryMessage get_default_command(const std::string name);


    /// Get the json blob for the default meter update node.
    ///
    /// @return  TelemetryMessage of the meter update node
    TelemetryMessage get_default_meter();


    /// Get the json blob for the default event node.
    ///
    /// @return  TelemetryMessage of the event node
    TelemetryMessage get_default_event();


    /// Get the name of the TelemetryMessage.
    ///
    /// @return  The name of the TelemetryMessage.
    const std::string get_message_name() const;


    /// Get the parameters node json 
    ///
    /// @return  TelemetryMessage of parameters node.
    TelemetryMessage &get_parameters() const;


    /// Get the name of the TelemetryMessage.
    ///
    /// @return  The name of the TelemetryMessage.
    const std::string get_name() const;


    /// Get the string from "value" property.
    ///
    /// @return  The string value of "value"
    const std::string get_value() const;


    /// Get the string from "type" property.
    ///
    /// @return  The string value of "type"
    const std::string get_type() const;


    /// Get the string from "period_type" property.
    ///
    /// @return  The string value of "period_type"
    const std::string get_period_type() const;


    /// Get the string from "packet_id" property.
    ///
    /// @return  The string value of "packet_id"
    const std::string get_packet_id() const;

    /// Get the integer protocol version from "protocol_version".
    int_fast32_t get_protocol_version() const;

    /// Get the integer schema version from "schema_version".
    int_fast32_t get_schema_version() const;

    /// Try to get the integer protocol version from "protocol_version".
    bool try_get_protocol_version(int_fast32_t &value) const;

    /// Try to get the integer schema version from "schema_version".
    bool try_get_schema_version(int_fast32_t &value) const;

    /// Check whether the message parameters contain supported telemetry
    /// protocol/schema versions using the current `N` / `N-1` policy.
    bool has_supported_telemetry_versions() const;


    /// Get the "block_name" array.
    ///
    /// @return  The block_name array
    std::vector<std::string> get_block_name() const;


    /// Get the "block_size" array.
    ///
    /// @return  The block_size array
    std::vector<std::string> get_block_size() const;


    /// Set the name value.
    ///
    /// @param value  The value to set name.
    void set_name(const std::string &value);


    /// Set the block_name value.
    ///
    /// @param value  The value to set block_name.
    void set_block_name(const std::string &value);


    /// Set the meter_name value.
    ///
    /// @param value  The value to set meter_name.
    void set_meter_name(const std::string &value);


    /// Set the event_name value.
    ///
    /// @param value  The value to set event_name.
    void set_event_name(const std::string &value);


    /// Set the dimensions value.
    ///
    /// @param value  The value to set dimensions.
    void set_dimensions(const std::string &value);


    /// Set the value value.
    ///
    /// @param value  The value to set value_type.
    void set_value_type(const std::string &value);


    /// Set the value value.
    ///
    /// @param value  The value to set value.
    template <typename T>
    void set_value(const T &value);


    /// Set the value value for value is a vector.
    ///
    /// @param vec  The value to set value.
    template <typename T>
    void set_value(const std::vector<T>& vec);


    /// Set the value value for value is a matrix.
    ///
    /// @param value  The value to set value.
    template <typename T>
    void set_value(const std::vector<std::vector<T>>& mat);


    /// Set the type value.
    ///
    /// @param value  The value to set type.
    template <typename T>
    void set_type(const T &value);


    /// Generate a timestamp and set the packet_id with it.
    void set_packet_id();


    /// Set the packet_id value with the specified timestamp.
    ///
    /// @param timestamp  The value to set packet_id.
    void set_packet_id(std::string timestamp);


    /// Set the "block_size" array in the "parameters" object.
    /// If "block_size" exists, it will be updated with the new values.
    /// If it does not exist, an error is logged, and an exception is thrown.
    ///
    /// @param block_size The array of block sizes to set.
    void set_block_size(const std::vector<int_fast32_t> &block_size);


    /// Serialize the telemetry message.
    ///
    /// @return  The json blob string
    const std::string serialize_message() const;
};


} // namespace bosepro
