#pragma once

#include <bosepro/constants.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>

#include <string>
#include <functional>
#include <thread>
#include <atomic>
#include <sys/un.h>
#include <sys/socket.h>
#include <cstring>
#include <unistd.h>
#include <fcntl.h>
#include <sys/mman.h> 
#include <iostream>


namespace bosepro {


struct telemetry_cb_data {
    std::string message;
    std::string rate;
    std::string value_type;
    bool more_data;
};


/// A class for managing the data of a meter.
class Telemetry {
public:
    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  configuration  The configuration to use for the meter.
    Telemetry(const TelemetryDefinition &definition,
              const ProcessorDefinition &processor,
              const BlockConfiguration *configuration)
    {
        name = definition.get_name();
        value_type = definition.get_value_type();
        type = definition.get_type();
        rate = definition.get_rate();
        
        num_rows = 1;
        num_columns = 1;

        int dimensions = definition.get_num_dimensions();
        if (dimensions != 0)
        {
            std::string rows_name;
            std::string columns_name;
            definition.get_dimensions(num_rows, num_columns,
                                      rows_name, columns_name);

            if (!rows_name.empty())
            {
                if (processor.has_property(rows_name))
                {
                    if (configuration->has_property(rows_name))
                    {
                        const PropertyConfiguration &pc =
                            configuration->get_property(rows_name);
                        pc.get_value(num_rows);
                    }
                    else
                    {
                        const PropertyDefinition &pd =
                            processor.get_property(rows_name);
                        pd.get_default_value(num_rows);
                    }
                }
                else if (processor.has_terminal(rows_name))
                {
                    if (configuration->has_terminal(rows_name))
                    {
                        const TerminalConfiguration &tc =
                            configuration->get_terminal(rows_name);
                        num_rows = tc.get_num_channels();
                    }
                }
            }

            if (!columns_name.empty())
            {
                if (processor.has_property(columns_name))
                {
                    if (configuration->has_property(columns_name))
                    {
                        const PropertyConfiguration &pc =
                            configuration->get_property(columns_name);
                        pc.get_value(num_columns);
                    }
                    else
                    {
                        const PropertyDefinition &pd =
                            processor.get_property(columns_name);
                        pd.get_default_value(num_columns);
                    }
                }
                else if (processor.has_terminal(columns_name))
                {
                    if (configuration->has_terminal(columns_name))
                    {
                        const TerminalConfiguration &tc =
                            configuration->get_terminal(columns_name);
                        num_columns = tc.get_num_channels();
                    }
                }
            }
        }
    }

    virtual ~Telemetry() = default;

    /// Initialize the meter by resizing its storage to the configured
    /// dimensions.
    virtual void initialize() = 0;


    /// Assign a pointer to store the value of a scalar meter.
    ///
    /// @param  value  The pointer to store the value of the meter.
    template <typename T>
    void assign(const T *value);


    /// Assign a pointer to store the value of a scalar meter.
    ///
    /// @param  value  The pointer to store the value of the meter.
    template <typename T>
    void assign(const T *value, std::function<void()> pre_function);


    /// Assign meter memory to store the values of a vector meter.
    /// The memory will be re-sized to the length of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    template <typename T>
    void assign(DspTelemetryMemory<T[]> &value);


    /// Assign meter memory to store the values of a vector meter.
    /// The memory will be re-sized to the length of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    template <typename T>
    void assign(DspTelemetryMemory<T[]> &value, std::function<void(int)> pre_function);


    /// Assign meter memory to store the values of a matrix meter.
    /// The memory will be re-sized to the dimensions of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    template <typename T>
    void assign(DspTelemetryMemory<T*[]> &value);


    /// Assign meter memory to store the values of a matrix meter.
    /// The memory will be re-sized to the dimensions of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    template <typename T>
    void assign(DspTelemetryMemory<T*[]> &value, std::function<void(int, int)> pre_function);


    /// Get the number of rows in the meter, or 1 if the control is a scalar.
    ///
    /// @return  The number of rows in the meter.
    int get_num_rows() const
    {
        return num_rows;
    }


    /// Get the number of columns in the meter, or 1 if the control is a
    /// scalar or vector.
    int get_num_columns() const
    {
        return num_columns;
    }


    /// Get the name of the type of the meter's value.
    ///
    /// @return  The name of the type of the meter's value.
    const std::string &get_value_type() const
    {
        return value_type;
    }


    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  configuration  The configuration to use for the meter.
    /// @return  A pointer to the meter object.
    static Telemetry *create(const TelemetryDefinition &definition,
                             const ProcessorDefinition &processor,
                             const BlockConfiguration *configuration);


    /// Get the name of this meter.
    ///
    /// @return  The name of the meter.
    const std::string &get_name()
    {
        return name;
    }


    /// Set the name of the block that owns this meter.
    ///
    /// @param  name  The block name.
    void set_block_name(const std::string &name)
    {
        block_name = name;
    }


    /// Get the name of the block that owns this meter.
    ///
    /// @return  The block name.
    const std::string &get_block_name()
    {
        return block_name;
    }


    /// Get the telemetry type.
    ///
    /// @return  The block name.
    const std::string &get_rate() const
    {
        return rate;
    }


    /// Get the telemetry type.
    ///
    /// @return  The block name.
    const std::string &get_type() const
    {
        return type;
    }


    /// Get the telemetry size.
    ///
    /// @return  The telemetry size.
    virtual size_t get_meters_size() = 0;


    /// Pre-process the meters
    ///
    virtual void pre_process(void) = 0;


    /// Send a JSON-formatted meter string using the provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    virtual void send(std::function<void(telemetry_cb_data &)> meters_callback, int) = 0;
    virtual void send_event(std::function<void(telemetry_cb_data &)> event_callback) = 0;

private:
    std::string name;
    std::string block_name;
    std::string value_type;
    std::string type;
    std::string rate;
    int num_rows;
    int num_columns;
};


/// A type-specific version of `Telemetry` for storing meter values.
template <typename T>
class TelemetryData : public Telemetry {
public:
    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  configuration  The configuration to use for the meter.
    TelemetryData(const TelemetryDefinition &definition,
                  const ProcessorDefinition &processor,
                  const BlockConfiguration *configuration)
        : Telemetry(definition, processor, configuration)
    {
    }

    /// Format one meter value as a JSON-formatted value, and write it to the
    /// meter message.
    ///
    /// @param  message  A string stream to whith the value will be written.
    /// @param  value  The meter value.
    void print_value(std::ostringstream &message, const T &value);
};

/// A type-specific version of `Telemetry` for storing meter values.
template <typename T>
class TelemetryDataScalar : public TelemetryData<T> {
public:
    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  configuration  The configuration to use for the meter.
    TelemetryDataScalar(const TelemetryDefinition &definition,
                        const ProcessorDefinition &processor,
                        const BlockConfiguration *configuration)
        : TelemetryData<T>(definition, processor, configuration), 
          block_value(nullptr),
          pre_function(nullptr)
    {
    }


    /// Assign a pointer to store the value of a scalar meter.
    ///
    /// @param  value  The pointer to store the value of the meter.
    void assign(const T *value)
    {
        block_value = value;
    }


    /// Assign a pointer to store the value of a scalar meter.
    ///
    /// @param  value  The pointer to store the value of the meter.
    void assign(const T *value, std::function<void()> pre_function)
    {
        block_value = value;
        this->pre_function = pre_function;
    }


    /// Initialize the meter.
    ///
    virtual void initialize() override
    {
    }


    /// run the pre_function, if it exists, on the telemetry values
    ///
    virtual void pre_process() override
    {
        if (pre_function != nullptr)
        {
            pre_function();
        }
    }


    virtual size_t get_meters_size() override
    {
        size_t size = 0;
        if constexpr (std::is_same_v<T, std::string>) 
        {
            size = block_value->size();
        } 
        else if constexpr (std::is_same_v<T, bool>)
        {
            size = MAX_BOOL_STR_LEN;
        }
        else if constexpr (std::is_same_v<T, int>)
        {
            size = MAX_INT_STR_LEN;
        }
        if constexpr (std::is_same_v<T, float>)
        {
            size = MAX_FLOAT_STR_LEN;
        }

        size += MAX_NAME_STR_LEN + MAX_VALUE_TYPE_STR_LEN;

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    virtual void send(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"block_name\": \"" << this->get_block_name() << "\"";
        message << "{ \"meter_name\": \"" << this->get_name() << "\"";
        message << ", \"value_type\": \"" << this->get_value_type() << "\"";
        message << " \"dimensions\": 0,"; // Scalar telemetry
        message << ", \"value\": ";

        this->print_value(message, *block_value);

        message << " }\n";

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        cb_data.more_data = items_remaining ? true : false;
        meters_callback(cb_data);
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     meter data.
    virtual void send_event(std::function<void(telemetry_cb_data &)> event_callback) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"message_name\": \"alarm_data\",";
        message << " \"parameters\": {";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"alarm_name\": \"" << this->get_name() << "\",";
        message << " \"dimensions\": 0,"; // Scalar telemetry
        message << " \"value\": [";

        // Append scalar value
        this->print_value(message, *block_value);

        message << "] } }\n";

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        event_callback(cb_data);
    }


private:
    const T *block_value;
    std::function<void()> pre_function;
};

/// A type-specific version of `Telemetry` for storing meter values.
template <typename T>
class TelemetryDataVector : public TelemetryData<T> {
public:
    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  configuration  The configuration to use for the meter.
    TelemetryDataVector(const TelemetryDefinition &definition,
                        const ProcessorDefinition &processor,
                        const BlockConfiguration *configuration)
        : TelemetryData<T>(definition, processor, configuration), 
          block_value(nullptr),
          pre_function(nullptr)
    {
    }


    /// Assign meter memory to store the values of a vector meter.
    /// The memory will be re-sized to the length of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    void assign(DspTelemetryMemory<T[]> &value)
    {
        value.resize(this->get_num_rows());
        block_value = value.get();
    }


    /// Assign meter memory to store the values of a vector meter.
    /// The memory will be re-sized to the length of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    void assign(DspTelemetryMemory<T[]> &value, std::function<void(int)> pre_function)
    {
        value.resize(this->get_num_rows());
        block_value = value.get();
        this->pre_function = pre_function;
    }


    /// Initialize the meter.
    virtual void initialize() override
    {
    }

    /// run the pre_function (if it exists) on the telemetry values
    ///
    virtual void pre_process() override
    {
        if (pre_function != nullptr)
        {
            for (int row = 0; row < this->get_num_rows(); row++)
            {
                pre_function(row);
            }
        }
    }


    virtual size_t get_meters_size() override
    {
        size_t size = 0;
        if constexpr (std::is_same_v<T, std::string>)
        {
            for (int row = 0; row < this->get_num_rows(); row++)
            {
                size += static_cast<const std::string>(block_value[row]).size();
            }
        }
        else if constexpr (std::is_same_v<T, bool>)
        {
            size = MAX_BOOL_STR_LEN * this->get_num_rows();
        }
        else if constexpr (std::is_same_v<T, int>)
        {
            size = MAX_INT_STR_LEN * this->get_num_rows();
        }
        if constexpr (std::is_same_v<T, float>)
        {
            size = MAX_FLOAT_STR_LEN * this->get_num_rows();
        }

        // add name and type string sizes
        size += MAX_NAME_STR_LEN + MAX_VALUE_TYPE_STR_LEN;

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    virtual void send(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"block_name\": \"" << this->get_block_name() << "\"";
        message << "{ \"meter_name\": \"" << this->get_name() << "\"";
        message << ", \"value_type\": \"" << this->get_value_type() << "\"";
        message << " \"dimensions\": [" << this->get_num_rows() << "],"; // vector telemetry
        message << ", \"value\": [";

        for (int row = 0; row < this->get_num_rows() - 1; row++)
        {
            this->print_value(message, block_value[row]);
            message << ", ";
        }
        this->print_value(message, block_value[this->get_num_rows() - 1]);
        message << "]";

        message << " }\n";

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        cb_data.more_data = items_remaining ? true : false;
        meters_callback(cb_data);
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     meter data.
    virtual void send_event(std::function<void(telemetry_cb_data &)> event_callback) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"message_name\": \"alarm_data\",";
        message << " \"packet_id\": 0,";
        message << " \"parameters\": {";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"alarm_name\": \"" << this->get_name() << "\",";
        message << " \"dimensions\": [" << this->get_num_rows() << "],";
        message << " \"value\": [";

        // Append vector values
        for (int row = 0; row < this->get_num_rows(); row++)
        {
            this->print_value(message, block_value[row]);
            if (row < this->get_num_rows() - 1)
            {
                message << ", ";
            }
        }

        message << "] } }\n";

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        event_callback(cb_data);
    }


private:
    const T *block_value;
    std::function<void(int)> pre_function;
};

/// A type-specific version of `Telemetry` for storing meter values.
template <typename T>
class TelemetryDataMatrix : public TelemetryData<T> {
public:
    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  configuration  The configuration to use for the meter.
    TelemetryDataMatrix(const TelemetryDefinition &definition,
                        const ProcessorDefinition &processor,
                        const BlockConfiguration *configuration)
        : TelemetryData<T>(definition, processor, configuration), 
          block_value(nullptr),
          pre_function(nullptr)
    {
    }


    /// Assign meter memory to store the values of a matrix meter.
    /// The memory will be re-sized to the dimensions of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    void assign(DspTelemetryMemory<T*[]> &value)
    {
        value.resize(this->get_num_rows(), this->get_num_columns());
        block_value = value.get();
    }


    /// Assign meter memory to store the values of a matrix meter.
    /// The memory will be re-sized to the dimensions of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    void assign(DspTelemetryMemory<T*[]> &value, std::function<void(int, int)> pre_function)
    {
        value.resize(this->get_num_rows(), this->get_num_columns());
        block_value = value.get();
        this->pre_function = pre_function;
    }


    /// Initialize the meter.
    ///
    virtual void initialize() override
    {
    }


    /// run the pre_function (if it exists) on the telemetry values
    ///
    virtual void pre_process() override
    {
        if (pre_function != nullptr)
        {
            for (int row = 0; row < this->get_num_rows(); row++)
            {
                for (int column = 0; column < this->get_num_columns(); column++)
                {
                    pre_function(row, column);
                }
            }
        }
    }


    virtual size_t get_meters_size() override
    {
        size_t size = 0;
        if constexpr (std::is_same_v<T, std::string>)
        {
            for (int row = 0; row < this->get_num_rows(); row++)
            {
                for (int col = 0; col < this->get_num_columns(); col++)
                {
                    size += static_cast<const std::string>(block_value[row][col]).size();
                }
            }
        }
        // add [] for each column
        else if constexpr (std::is_same_v<T, bool>)
        {
            size = MAX_BOOL_STR_LEN * this->get_num_rows() * this->get_num_columns() + 2 * this->get_num_columns();
        }
        else if constexpr (std::is_same_v<T, int>)
        {
            size = MAX_INT_STR_LEN * this->get_num_rows() * this->get_num_columns() + 2 * this->get_num_columns();
        }
        if constexpr (std::is_same_v<T, float>)
        {
            size = MAX_FLOAT_STR_LEN * this->get_num_rows() * this->get_num_columns() + 2 * this->get_num_columns();
        }

        // tack on size for meter_name and value_type strings
        size += MAX_NAME_STR_LEN + MAX_VALUE_TYPE_STR_LEN;

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    /// @param  rate  The callback function used to send the
    ///     meter data.
    virtual void send(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;
        
        message << "{ \"block_name\": \"" << this->get_block_name() << "\"";
        message << "{ \"meter_name\": \"" << this->get_name() << "\"";
        message << ", \"value_type\": \"" << this->get_value_type() << "\"";
        message << " \"dimensions\": [" << this->get_num_rows() << ", " << this->get_num_columns() << "],"; // vector telemetry
        message << ", \"value\": [";
        
        for (int row = 0; row < this->get_num_rows(); row++)
        {
            for (int col = 0; col < this->get_num_columns() - 1; col++)
            {
                this->print_value(message, block_value[row][col]);
            }

            this->print_value(message,
                        block_value[row][this->get_num_columns() - 1]);
            message << "]";

            if (row != this->get_num_rows() - 1)
            {
                message << ", [";
            }
            else
            {
                message << "]";
            }
        }

        message << " }\n";
        
        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        cb_data.more_data = items_remaining ? true : false;
        meters_callback(cb_data);
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     meter data.
    virtual void send_event(std::function<void(telemetry_cb_data &)> event_callback) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"message_name\": \"alarm_data\",";
        message << " \"packet_id\": 0,";
        message << " \"parameters\": {";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"alarm_name\": \"" << this->get_name() << "\",";
        message << " \"dimensions\": [" << this->get_num_rows() 
                << ", " << this->get_num_columns() << "],";
        message << " \"value\": [";

        // Append matrix values row by row
        for (int row = 0; row < this->get_num_rows(); row++)
        {
            message << "[";
            for (int col = 0; col < this->get_num_columns(); col++)
            {
                this->print_value(message, block_value[row][col]);
                if (col < this->get_num_columns() - 1)
                {
                    message << ", ";
                }
            }
            message << "]";
            if (row < this->get_num_rows() - 1)
            {
                message << ", ";
            }
        }

        message << "] } }\n";

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        event_callback(cb_data);
    }


private:
    const T * const *block_value;
    std::function<void(int, int)> pre_function;
};


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


    /// Get the json blob for the command with name name.
    ///
    /// @return  The command json node
    TelemetryMessage get_default_command(const std::string name) const
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "message_name", name);
    }


    /// Get the json blob for the command with name name.
    ///
    /// @return  The command json node
    TelemetryMessage get_default_meter() const
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "meter_name", "default");
    }


    /// Get the name of the interface.
    ///
    /// @return  The name of the interface.
    const std::string &get_message_name() const
    {
        return get_string("message_name");
    }


    /// Get the json blob for the command with name name.
    ///
    /// @return  The name of the interface.
    TelemetryMessage &get_parameters() const
    {
        return (TelemetryMessage &)get_member("parameters");
    }


    /// Get the json blob for the command with name name.
    ///
    /// @return  The name of the interface.
    const std::string get_value() const
    {
        return get_string("value");
    }


    /// Get the "block_path" array.
    std::vector<std::string> get_block_path()
    {
        const std::string block_path_key = "block_path";
        std::vector<std::string> block_path(3, "");

        get_list_value(block_path_key, 0, block_path[0]);
        get_list_value(block_path_key, 1, block_path[1]);
        get_list_value(block_path_key, 2, block_path[2]);

        return block_path;
    }


    /// Get the "block_size" array.
    std::vector<std::string> get_block_size()
    {
        const std::string block_size_key = "block_size";
        std::vector<std::string> block_size(3, "");

        get_list_value(block_size_key, 0, block_size[0]);
        get_list_value(block_size_key, 1, block_size[1]);
        get_list_value(block_size_key, 2, block_size[2]);

        return block_size;
    }


    /// Set the parameters.<member_name> value.
    ///
    /// @param member_name  The name of the member under "parameters".
    /// @param value        The value to set for the specified member.
    template <typename T>
    void set_value(const T &value)
    {
        set_member("value", value);
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


    /// Get the json blob for the command with message_name name.
    ///
    /// @return  The name of the interface.
    const std::string serialize_command() const
    {
        return serialize();
    }
};


class TelemetryMonitor {
public:
    /// Constructor for singleton pattern--initialization in "initialize" method
    TelemetryMonitor()
        : serverpath("/tmp/telemetry_uds"),
          shm_addr(NUM_SHM_REGIONS, nullptr),
          telemetry_manager_addr(),
          timeout(5),
          stop_flag(false)
    {
    }


    /// Destructor
    ~TelemetryMonitor() 
    {
        stop();
    }


    /// Initialize the singleton object. Connect and register with Fusion Telemetry Manager
    ///
    /// @param filename 
    void initialize(const std::string &filename)
    {
        telemetry_messages = std::make_unique<TelemetryMessage>(filename);
        
        telemetry_fd = socket(AF_UNIX, SOCK_DGRAM, 0);
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Failed to create UDS socket.");
        }

        struct sockaddr_un client_addr {};
        client_addr.sun_family = AF_UNIX;
        std::string client_path = "/tmp/system_monitor_uds_" + std::to_string(getpid());
        strncpy(client_addr.sun_path, client_path.c_str(), sizeof(client_addr.sun_path) - 1);
        unlink(client_path.c_str());

        if (bind(telemetry_fd, (struct sockaddr *)&client_addr, sizeof(client_addr)) < 0)
        {
            close(telemetry_fd);
            telemetry_fd = -1;
            SPDLOG_CRITICAL("Failed to bind UDS client socket to {}", client_path);
        }

        // Set up the telemetry manager address
        telemetry_manager_addr.sun_family = AF_UNIX;
        strncpy(telemetry_manager_addr.sun_path, serverpath.c_str(), sizeof(telemetry_manager_addr.sun_path) - 1);

        struct stat statbuf;
        int n = 0;

        while (n < timeout)
        {
            if (stat(serverpath.c_str(), &statbuf) == 0 && S_ISSOCK(statbuf.st_mode)) 
            {
                SPDLOG_DEBUG("Telemetry Manager UDS exists at {}", serverpath);
                break;
            }

            sleep(1);
            if (++n >= timeout)
            {
                SPDLOG_CRITICAL("Telemetry Manager UDS does NOT exist at {}", serverpath);
            }
        }

        if (!pub_register_req())
        {
            SPDLOG_CRITICAL("Failed to register with Telemetry Manager");
        }

        setup_callbacks();
    }


    /// Get the singleton instance of TelemetryMonitor.
    static TelemetryMonitor& get_instance() 
    {
        static TelemetryMonitor instance;
        return instance;
    }


    /// Start the telemetry monitoring thread.
    void start() 
    {
        SPDLOG_INFO("Starting TelemetryMonitor thread...");
        stop_flag.store(false); // Reset stop flag
        monitor_thread = std::thread(&TelemetryMonitor::monitor_loop, this);
    }


    /// Stop the telemetry monitoring thread.
    void stop() 
    {
        stop_flag.store(true);
        if (monitor_thread.joinable()) 
        {
            monitor_thread.join();
        }
    }


    /// Register a telemetry item.
    void register_telemetry(std::unique_ptr<Telemetry> t) 
    {
        std::string qualified_name = t->get_block_name() + "::" + t->get_name();

        if (t->get_type() == "meter")
        {
            meters[qualified_name] = std::move(t);
        }
        else if (t->get_type() == "event")
        {
            events[qualified_name] = std::move(t);
        }
        else
        {
            SPDLOG_WARN("Unknown telemetry type '{}'", t->get_type());
        }
    }


    /// Unregister all telemetry items associated with a block.
    void unregister_block(const std::string &block_name) 
    {
        const std::string prefix = block_name + "::";

        for (auto it = meters.begin(); it != meters.end();) 
        {
            if (it->first.rfind(prefix, 0) == 0)
            {
                it = meters.erase(it); // Erase returns the next valid iterator
            }
            else
            {
                ++it; // Increment manually if no erase
            }
        }

        for (auto it = events.begin(); it != events.end();) 
        {
            if (it->first.rfind(prefix, 0) == 0)
            {
                it = events.erase(it); // Erase returns the next valid iterator
            }
            else
            {
                ++it;
            }
        }
    }


    bool has_telemetry(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            if (events.count(qualified_name) == 0)
            {
                return false;
            }
        }

        return true;
    }


    bool has_meter(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            return false;
        }

        return true;
    }


    bool has_event(const std::string &qualified_name)
    {
        if (events.count(qualified_name) == 0)
        {
            return false;
        }

        return true;
    }


    Telemetry &get_telemetry(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            if (events.count(qualified_name) == 0)
            {
                SPDLOG_CRITICAL("Unknown telemetry '{}'", qualified_name);
            }
            return *events[qualified_name];
        }

        return *meters[qualified_name];
    }


    Telemetry &get_meter(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}'", qualified_name);
        }

        return *meters[qualified_name];
    }


    Telemetry &get_event(const std::string &qualified_name)
    {
        if (events.count(qualified_name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}'", qualified_name);
        }

        return *events[qualified_name];
    }


    size_t get_meters_size(const std::string &telemetry_rate, size_t message_size)
    {
        size_t size = 0;
        for (auto &m : meters)
        {
            if (m.second->get_rate() == telemetry_rate)
            {
                size += m.second->get_meters_size();
                size += message_size;
            }
        }

        return size;
    }


    int get_num_meters(const std::string &telemetry_rate)
    {
        int num_items = 0;
        for (auto &m : meters)
        {
            if (m.second->get_type() == telemetry_rate)
            {
                ++num_items;
            }
        }

        return num_items;
    }


    // Accessors for callbacks
    std::function<void(telemetry_cb_data &)> get_meters_callback() const {
        return meters_callback;
    }


    std::function<void(telemetry_cb_data &)> get_event_callback() const {
        return event_callback;
    }


    /// Callback to send event telemetry on UDS
    ///
    /// @param message the message to send
    void send_event_uds(bosepro::telemetry_cb_data &cb_data)
    {
        if (sendto(telemetry_fd, cb_data.message.c_str(), cb_data.message.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_WARN("Couldn't send telemetry to socket.");
        }
    }


    /// Callback to update telemetry in shared memory
    ///
    /// @param cb_data the telemetry callback data to write
    void update_meters_shm(bosepro::telemetry_cb_data &cb_data)
    {
        static char* current_addr = nullptr; // Use char* for easier arithmetic
        static int offset = 0;

        int region_index = cb_data.rate == "HI"  ? 0 :
                           cb_data.rate == "MED" ? 1 :
                           cb_data.rate == "LO"  ? 2 : -1;

        // Validate the region index and ensure shared memory is available
        if (region_index >= 0 && shm_addr[region_index] != nullptr)
        {
            if (current_addr == nullptr)
            {
                current_addr = static_cast<char*>(shm_addr[region_index]);
            }

            // Write the telemetry message into the shared memory region
            memcpy(current_addr + offset, cb_data.message.c_str(), cb_data.message.length());

            if (cb_data.more_data)
            {
                offset += cb_data.message.length(); // Move the pointer forward
            }
            else
            {
                // Reset for the next telemetry write
                current_addr = nullptr;
                offset = 0;
            }
        }
    }


private:
    /// Send a pub_register_req to the telemetry manager
    bool pub_register_req()
    {
        TelemetryMessage message = telemetry_messages->get_default_command("pub_register_req");
        size_t meter_blob_size = telemetry_messages->get_default_meter().serialize_command().size();
        std::vector<size_t> block_size = {get_meters_size("HI", meter_blob_size),
                                          get_meters_size("MED", meter_blob_size),
                                          get_meters_size("LO", meter_blob_size)};
        message.get_parameters().set_block_size(block_size);

        // Send the registration request
        const std::string reg_req_str = message.serialize_command();
        if (sendto(telemetry_fd, reg_req_str.c_str(), reg_req_str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send registration request to telemetry manager.");
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        SPDLOG_INFO("Registration request sent to telemetry manager.");

        // Wait for a response
        char buf[1024];
        struct sockaddr_un response_addr {};
        socklen_t response_addr_len = sizeof(response_addr);
        ssize_t recv_len = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&response_addr, &response_addr_len);

        if (recv_len < 0)
        {
            SPDLOG_ERROR("Failed to receive response from telemetry manager.");
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        buf[recv_len] = '\0';

        std::stringstream ss(buf);
        TelemetryMessage response(ss);

        if (response.get_message_name() == "pub_register_rsp" && response.get_parameters().get_value() == "OK")
        {
            SPDLOG_INFO("Received valid registration response: \n\n{}", response.serialize_command());
        }
        else
        {
            SPDLOG_ERROR("Received NOK response: \n\n{}", response.serialize_command());
            close(telemetry_fd);
            telemetry_fd = -1;
            return false;
        }

        std::vector<std::string> shm_paths = response.get_parameters().get_block_path();
        std::vector<int> shm_fd(shm_paths.size(), -1);

        int i = 0;
        for (auto a : shm_paths)
        {
            if (block_size[i] == 0) 
            {
                ++i;
                continue;
            }

            shm_fd[i] = shm_open(shm_paths[i].c_str(), O_RDWR, 0666);
            if (shm_fd[i] < 0) 
            {
                SPDLOG_CRITICAL("shm_open failed for {}", shm_paths[i]);
                return false;
            }

            // Map the shared memory into the process's address space
            shm_addr[i] = mmap(nullptr, block_size[i], PROT_READ | PROT_WRITE, MAP_SHARED, shm_fd[i], 0);
            if (shm_addr[i] == MAP_FAILED) 
            {
                SPDLOG_CRITICAL("mmap failed for {}", shm_paths[i]);
                close(shm_fd[i]);
                return false;
            }

            ++i;
        }

        return true;
    }


    void pub_deregister_request()
    {
        TelemetryMessage pub_dereg_req = telemetry_messages->get_default_command("pub_deregister_req");


    }


    // void update_meters_req(const ParameterSetting&)
    // {
    //     for (auto &task : tasks)
    //     {
    //         task.second->send_meters();
    //     }
    //     for (auto &na_task : na_tasks)
    //     {
    //         na_task.second->send_meters();
    //     }
    // }


    void process_telemetry_message(TelemetryMessage message)
    {
        std::string name = message.get_message_name();
    }


    /// The main loop for monitoring telemetry data and executing commands.
    void monitor_loop() {
            // Ensure the socket exists
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Invalid connection socket.");
        }

        char buf[1024];
        struct sockaddr_un manager_addr;
        socklen_t manager_addr_len = sizeof(manager_addr);

        while (!stop_flag.load())
        {
            // Receive a message from the telemetry manager
            memset(buf, 0, sizeof(buf));
            ssize_t result = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&manager_addr, &manager_addr_len);

            if (result <= 0)
            {
                SPDLOG_ERROR("Error receiving data from telemetry manager.");
                continue;
            }

            buf[result] = '\0';

            SPDLOG_INFO("Received messagefrom telemetry manager: '{}'", buf);

            try
            {
                // Parse the received message into a ParameterSetting object
                std::stringstream ss(buf);
                TelemetryMessage ps = TelemetryMessage(ss);
                process_telemetry_message(ps);
            }
            catch (const std::exception &e)
            {
                SPDLOG_ERROR("Error processing received message: {}", e.what());
            }

            usleep(100);
        }

        // Clean up the socket
        close(telemetry_fd);
        SPDLOG_INFO("Telemetry manager command loop ended.");
    }


    void setup_callbacks() {
        meters_callback = [this](telemetry_cb_data &cb_data) {
            update_meters_shm(cb_data);
        };

        event_callback = [this](telemetry_cb_data &cb_data) {
            send_event_uds(cb_data);
        };
    }


    std::function<void(telemetry_cb_data &)> meters_callback;
    std::function<void(telemetry_cb_data &)> event_callback;

    std::string serverpath;
    int telemetry_fd;
    std::vector<void *> shm_addr;
    struct sockaddr_un telemetry_manager_addr;
    int timeout;
    std::atomic<bool> stop_flag;

    std::unique_ptr<TelemetryMessage> telemetry_messages;

    std::thread monitor_thread;

    std::map<std::string, std::unique_ptr<Telemetry>> meters;
    std::map<std::string, std::unique_ptr<Telemetry>> events;
};

} // namespace bosepro
