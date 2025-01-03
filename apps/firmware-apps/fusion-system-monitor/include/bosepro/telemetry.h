#pragma once

#include <bosepro/constants.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>

#include <string>
#include <functional>
#include <optional>
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


/// struct to hold data for meters/event callbacks
struct telemetry_cb_data {
    std::string message;
    std::string rate;
    std::string value_type;
    bool more_data;
};


/// A class for managing Telemetry data.
class Telemetry {
public:
    /// Create a telemetry object based on the type of the definition.
    ///
    /// @param  definition  The telemetry definition.
    /// @param  processor  The processor (algorithm or module) definition
    /// @param  configuration  The configuration to use for the telemetry.
    Telemetry(const TelemetryDefinition &definition,
              const ProcessorDefinition &processor,
              const BlockConfiguration *configuration)
    {
        name = definition.get_name();
        value_type = definition.get_value_type();
        type = definition.get_type(); // type is unsed internally--meter or event
        rate = definition.get_rate(); // rate is HI, MED, or LO
        
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

    /// Initialize the telemetry by resizing its storage to the configured
    /// dimensions.
    virtual void initialize() = 0;


    /// Assign a pointer to store the value of a scalar telemetry.
    ///
    /// @param  value  The pointer to store the value of the telemetry.
    template <typename T>
    void assign(const T *value);


    /// Assign a pointer to store the value of a scalar telemetry.
    ///
    /// @param  value  The pointer to store the value of the telemetry.
    /// @param  pre_function  A function to pre-process telemetry data.
    template <typename T>
    void assign(const T *value, std::function<void()> pre_function);


    /// Assign telemetry memory to store the values of a vector telemetry.
    /// The memory will be re-sized to the length of the telemetry.
    ///
    /// @param  value  The memory to store the values of the telemetry.
    template <typename T>
    void assign(DspTelemetryMemory<T[]> &value);


    /// Assign telemetry memory to store the values of a vector telemetry.
    /// The memory will be re-sized to the length of the telemetry.
    ///
    /// @param  value  The memory to store the values of the telemetry.
    template <typename T>
    void assign(DspTelemetryMemory<T[]> &value, std::function<void(int)> pre_function);


    /// Assign telemetry memory to store the values of a matrix telemetry.
    /// The memory will be re-sized to the dimensions of the telemetry.
    ///
    /// @param  value  The memory to store the values of the telemetry.
    template <typename T>
    void assign(DspTelemetryMemory<T*[]> &value);


    /// Assign telemetry memory to store the values of a matrix telemetry.
    /// The memory will be re-sized to the dimensions of the telemetry.
    ///
    /// @param  value  The memory to store the values of the telemetry.
    template <typename T>
    void assign(DspTelemetryMemory<T*[]> &value, std::function<void(int, int)> pre_function);


    /// Get the number of rows in the telemetry, or 1 if the control is a scalar.
    ///
    /// @return  The number of rows in the telemetry.
    int get_num_rows() const
    {
        return num_rows;
    }


    /// Get the number of columns in the telemetry, or 1 if the control is a
    /// scalar or vector.
    int get_num_columns() const
    {
        return num_columns;
    }


    /// Get the name of the type of the telemetry's value.
    ///
    /// @return  The name of the type of the telemetry's value.
    const std::string &get_value_type() const
    {
        return value_type;
    }


    /// Create a telemetry object based on the type of the definition.
    ///
    /// @param  definition  The telemetry definition.
    /// @param  definition  The processor definition.
    /// @param  configuration  The configuration to use for the telemetry.
    /// @return  A pointer to the telemetry object.
    static Telemetry *create(const TelemetryDefinition &definition,
                             const ProcessorDefinition &processor,
                             const BlockConfiguration *configuration);


    /// Get the name of this telemetry.
    ///
    /// @return  The name of the telemetry.
    const std::string &get_name()
    {
        return name;
    }


    /// Set the name of the block that owns this telemetry.
    ///
    /// @param  name  The block name.
    void set_block_name(const std::string &name)
    {
        block_name = name;
    }


    /// Get the name of the block that owns this telemetry.
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


    /// Try to calculate the minimum size the meters will take up in memory
    ///
    /// @return  The size of the meters json blob
    virtual size_t get_meters_size() = 0;


    /// Pre-process the telemetry
    virtual void pre_process() = 0;


    /// Send a JSON-formatted meter string using the provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the meter data.
    /// @param  items_remaining  The number of meters remaining in the block.
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) = 0;


    /// Send a JSON-formatted event string using the provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the event data.
    virtual void send_event(std::function<void(telemetry_cb_data &)> event_callback) = 0;


    /// Wrapper for send_event that checks for changed values
    ///
    /// @param  meters_callback  The callback function used to send the event data.
    virtual void send_event_if_changed(std::function<void(telemetry_cb_data &)> event_callback) = 0;


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
    /// @param  processor  The processor (algorithm or module) definition
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
    /// @param  pre_function  A function to be called before a meter is sent.
    void assign(const T *value, std::function<void()> pre_function)
    {
        assign(value);
        this->pre_function = pre_function;
    }


    /// Initialize the telemetry.
    virtual void initialize() override
    {
    }


    /// Run the pre_function, if it exists, on the telemetry values
    virtual void pre_process() override
    {
        if (pre_function != nullptr)
        {
            pre_function();
        }
    }


    /// Try to calculate the minimum size the meters will take up in memory
    ///
    /// @return  The size of the meters json blob
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

        size += this->get_block_name().size() + 2 +
                this->get_name().size() + 2 +
                this->get_value_type().size() + 1;

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    /// @param  items_remaining  The number of meters left in the block.
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"meter_name\": \"" << this->get_name() << "\",";
        message << " \"value_type\": \"" << this->get_value_type() << "\",";
        message << " \"dimensions\": 0,"; // Scalar telemetry
        message << " \"value\": ";

        this->print_value(message, *block_value);

        message << " }\n";

        SPDLOG_DEBUG("Message size: {}", message.str().size());

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        cb_data.more_data = items_remaining ? true : false;
        meters_callback(cb_data);
    }


    /// Send the data for this event as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event(std::function<void(telemetry_cb_data &)> event_callback) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"message_name\": \"event\",";
        message << " \"parameters\": {";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"alarm_name\": \"" << this->get_name() << "\",";
        message << " \"dimensions\": 0,"; // Scalar telemetry
        message << " \"value\": ";

        // Append scalar value
        this->print_value(message, *block_value);

        message << "] } }\n";

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        event_callback(cb_data);
    }


    /// Wrapper for send_event to check for changed value
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event_if_changed(std::function<void(telemetry_cb_data &)> event_callback)
    {
        if (!block_value_prev || *block_value_prev != *block_value) {
            if (!block_value_prev) {
                block_value_prev = std::make_unique<T>(*block_value); // Allocate memory for block_value_prev
            } else {
                send_event(event_callback); // Send event if value has changed
                *block_value_prev = *block_value; // Update previous value
            }
        }
    }


private:
    const T *block_value;
    std::unique_ptr<T> block_value_prev;
    std::function<void()> pre_function;
};

/// A type-specific version of `Telemetry` for storing telemetry values.
template <typename T>
class TelemetryDataVector : public TelemetryData<T> {
public:
    /// Create a telemetry object based on the type of the definition.
    ///
    /// @param  definition  The telemetry definition.
    /// @param  processor  The processor (algorithm or module) definition
    /// @param  configuration  The configuration to use for the telemetry.
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
    /// @param  pre_function  A function to be called before a meter is sent.
    void assign(DspTelemetryMemory<T[]> &value, std::function<void(int)> pre_function)
    {
        assign(value);
        this->pre_function = pre_function;
    }


    /// Initialize the meter.
    virtual void initialize() override
    {
    }


    /// run the pre_function (if it exists) on the telemetry values
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


    /// Try to calculate the minimum size the meters will take up in memory
    ///
    /// @return  The size of the meters json blob
    virtual size_t get_meters_size() override
    {
        size_t size = 0;
        // add """" and ", " and 2x " " for each value
        if constexpr (std::is_same_v<T, std::string>)
        {
            for (int row = 0; row < this->get_num_rows() - 1; row++)
            {
                size += static_cast<const std::string>(block_value[row]).size() + 6;
            }
            // compensate for extra """" and no ", "
            size += static_cast<const std::string>(block_value[this->get_num_rows()]).size() + 2;
        }
        else if constexpr (std::is_same_v<T, bool>)
        {
            // """" and ", "
            size = (MAX_BOOL_STR_LEN + 6) * (this->get_num_rows() - 1);
            // compensate for extra """" and no ", "
            size += MAX_BOOL_STR_LEN + 2;
        }
        else if constexpr (std::is_same_v<T, int>)
        {
            // """" and ", "
            size = (MAX_INT_STR_LEN + 6) * (this->get_num_rows() - 1);
            // compensate for extra """" and no ", "
            size += MAX_INT_STR_LEN + 2;
        }
        if constexpr (std::is_same_v<T, float>)
        {
            // """" and ", "
            size = (MAX_FLOAT_STR_LEN + 6) * (this->get_num_rows() - 1);
            // compensate for extra """" and no ", "
            size += MAX_FLOAT_STR_LEN + 2;
        }

        // what about dimensions? tack on 2 for now
        size += 2;

        // add block_name, name, type string sizes, and newline
        size += this->get_block_name().size() + 2 +
                this->get_name().size() + 2 +
                this->get_value_type().size() + 1;

        SPDLOG_DEBUG("Here size == {}", size);

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    /// @param  items_remaining  The number of meters left in the block.
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"meter_name\": \"" << this->get_name() << "\",";
        message << " \"value_type\": \"" << this->get_value_type() << "\",";
        message << " \"dimensions\": [" << this->get_num_rows() << "],"; // vector telemetry
        message << " \"value\": [";

        for (int row = 0; row < this->get_num_rows() - 1; row++)
        {
            this->print_value(message, block_value[row]);
            message << ", ";
        }
        this->print_value(message, block_value[this->get_num_rows() - 1]);
        message << "]";

        message << " }\n";

        SPDLOG_DEBUG("Message size: {}", message.str().size());

        cb_data.message = message.str();
        cb_data.rate = this->get_rate();
        cb_data.more_data = items_remaining ? true : false;
        meters_callback(cb_data);
    }


    /// Send the data for this event as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
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


    /// Wrapper for send_event to check for changed value
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event_if_changed(std::function<void(telemetry_cb_data &)> event_callback) override {
        // Initialize block_value_prev if it doesn't exist.
        if (!block_value_prev) {
            block_value_prev = std::make_unique<std::vector<T>>(this->get_num_rows());
        }

        // Check for changes in values.
        if (!std::equal(block_value, block_value + this->get_num_rows(), block_value_prev->begin())) {
            send_event(event_callback);

            // Copy updated values into block_value_prev.
            std::copy(block_value, block_value + this->get_num_rows(), block_value_prev->begin());
        }
    }


private:
    const T *block_value;
    std::unique_ptr<std::vector<T>> block_value_prev;
    std::function<void(int)> pre_function;
};

/// A type-specific version of `Telemetry` for storing meter values.
template <typename T>
class TelemetryDataMatrix : public TelemetryData<T> {
public:
    /// Create a meter object based on the type of the definition.
    ///
    /// @param  definition  The meter definition.
    /// @param  processor  The processor (algorithm or module) definition
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
    /// @param  pre_function  function called before meter is sent
    void assign(DspTelemetryMemory<T*[]> &value, std::function<void(int, int)> pre_function)
    {
        assign(value);
        this->pre_function = pre_function;
    }


    /// Initialize the meter.
    virtual void initialize() override
    {
    }


    /// run the pre_function (if it exists) on the telemetry values
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


    /// Try to calculate the minimum size the meters will take up in memory
    ///
    /// @return  The size of the meters json blob
    virtual size_t get_meters_size() override
    {
        size_t size = 0;
        // add """", ", ", and 2x " " for each value and "[]" for each column
        if constexpr (std::is_same_v<T, std::string>)
        {
            for (int row = 0; row < this->get_num_rows() - 1; row++)
            {
                size += 2; // "[]"
                for (int col = 0; col < this->get_num_columns(); col++)
                {
                    size += static_cast<const std::string>(block_value[row][col]).size() + 6;
                }
            }
            size -= 2; // compensate for already included """"
        }
        else if constexpr (std::is_same_v<T, bool>)
        {
            // """" and ", "
            size = (MAX_BOOL_STR_LEN + 6) * this->get_num_rows() * this->get_num_columns();
            // "[]"
            size += 4 * this->get_num_rows();
            // extra """"
            size -= 2;
        }
        else if constexpr (std::is_same_v<T, int>)
        {
            size = (MAX_INT_STR_LEN + 6) * this->get_num_rows() * this->get_num_columns();
            // "[]"
            size += 4 * this->get_num_rows();
            // extra """"
            size -= 2;
        }
        if constexpr (std::is_same_v<T, float>)
        {
            size = (MAX_FLOAT_STR_LEN + 6) * this->get_num_rows() * this->get_num_columns();
            // "[]"
            size += 4 * this->get_num_rows();
            // extra """"
            size -= 2;
        }

        // what about dimensions? tack on 6 for now
        size += 6;

        // add block_name, name, type string sizes, and newline
        size += this->get_block_name().size() +
                this->get_name().size() +
                this->get_value_type().size() + 1;

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    /// @param  items_remaining  The number of meters left in the block.
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback, int items_remaining) override
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


    /// Wrapper for send_event to check for changed value
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event_if_changed(std::function<void(telemetry_cb_data &)> event_callback) override {
        // Initialize block_value_prev if it doesn't exist.
        if (!block_value_prev) {
            block_value_prev = std::make_unique<std::vector<std::vector<T>>>(this->get_num_rows());
            for (int row = 0; row < this->get_num_rows(); ++row) {
                (*block_value_prev)[row].resize(this->get_num_columns());
            }
        }

        // Check for changes.
        bool changed = false;
        for (int row = 0; row < this->get_num_rows(); ++row) {
            if (!std::equal(block_value[row], block_value[row] + this->get_num_columns(), (*block_value_prev)[row].begin())) {
                changed = true;
                break;
            }
        }

        if (changed) {
            send_event(event_callback);

            // Update block_value_prev with new values.
            for (int row = 0; row < this->get_num_rows(); ++row) {
                std::copy(block_value[row], block_value[row] + this->get_num_columns(), (*block_value_prev)[row].begin());
            }
        }
    }


private:
    const T * const *block_value;
    std::unique_ptr<std::vector<std::vector<T>>> block_value_prev;
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


    /// Get the json blob for the default command with name "name".
    ///
    /// @return  TelemetryMessage of the command node
    TelemetryMessage get_default_command(const std::string name) const
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "message_name", name);
    }


    /// Get the json blob for the default meter update node.
    ///
    /// @return  TelemetryMessage of the meter update node
    TelemetryMessage get_default_meter() const
    {
        return (TelemetryMessage &)list_get_member("telemetry_messages", "meter_name", "");
    }


    /// Get the name of the TelemetryMessage.
    ///
    /// @return  The name of the TelemetryMessage.
    const std::string &get_message_name() const
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
    /// @return  string value of "value"
    const std::string get_value() const
    {
        return get_string("value");
    }


    /// Get the string from "rate" property.
    ///
    /// @return  string value of "rate"
    const std::string get_rate() const
    {
        return get_string("rate");
    }


    /// Get the "block_path" array.
    ///
    /// @return  The block_path array
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
    ///
    /// @return  The block_size array
    std::vector<std::string> get_block_size()
    {
        const std::string block_size_key = "block_size";
        std::vector<std::string> block_size(3, "");

        get_list_value(block_size_key, 0, block_size[0]);
        get_list_value(block_size_key, 1, block_size[1]);
        get_list_value(block_size_key, 2, block_size[2]);

        return block_size;
    }


    /// Set the parameters.value value.
    ///
    /// @param value  The value to set parameters.value.
    template <typename T>
    void set_value(const T &value)
    {
        set_member("value", value);
    }


    /// Set the parameters.type value.
    ///
    /// @param value  The value to set parameters.type.
    template <typename T>
    void set_type(const T &value)
    {
        set_member("type", value);
    }


    /// Set the parameters.rate value.
    ///
    /// @param value  The value to set parameters.rate.
    template <typename T>
    void set_rate(const T &value)
    {
        set_member("rate", value);
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
          timeout(5)
    {
    }


    ~TelemetryMonitor() 
    {
        stop();
    }


    /// Get the singleton instance of TelemetryMonitor.
    static TelemetryMonitor& get_instance() 
    {
        static TelemetryMonitor instance;
        return instance;
    }


    /// Initialize the singleton object. Connect and register with Fusion Telemetry Manager
    ///
    /// @param filename  file to initialize the telemetry_messages
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
                SPDLOG_INFO("Telemetry Manager UDS exists at {}", serverpath);
                break;
            }

            sleep(1);
            if (++n >= timeout)
            {
                SPDLOG_CRITICAL("Telemetry Manager UDS does NOT exist at {}", serverpath);
            }
        }

        if (!register_with_telemetry_manager())
        {
            SPDLOG_CRITICAL("Failed to register with Telemetry Manager");
        }

        setup_callbacks();
    }


    /// Start the threads.
    void start() 
    {
        SPDLOG_INFO("Starting TelemetryMonitor thread...");
        monitor_thread = std::thread(&TelemetryMonitor::monitor_loop, this);
        events_thread = std::thread(&TelemetryMonitor::manage_events_loop, this);
    }


    /// Stop the threads.
    void stop() 
    {
        if (monitor_thread.joinable()) 
        {
            monitor_thread.join();
        }
        if (events_thread.joinable()) 
        {
            events_thread.join();
        }
    }


    /// Register a telemetry item.
    ///
    /// @param telemetry  the unique_ptr to the telemetry item
    void register_telemetry(std::unique_ptr<Telemetry> telemetry) 
    {
        std::string qualified_name = telemetry->get_block_name() + "::" +
                                     telemetry->get_name();

        if (telemetry->get_type() == "meter")
        {
            meters[qualified_name] = std::move(telemetry);
        }
        else if (telemetry->get_type() == "event")
        {
            events[qualified_name] = std::move(telemetry);
        }
        else
        {
            SPDLOG_WARN("Unknown telemetry type '{}'", telemetry->get_type());
        }
    }


    /// Unregister all telemetry items associated with a block.
    /// 
    /// @param block_name  The name of the block to unregister telemetry
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


    /// Check if the telemetry monitor has a telemetry item of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::telemetry_name
    /// @return  True if the telemetry monitor has the telemetry item
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


    /// Check if the telemetry monitor has a meter of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::meter_name
    /// @return  True if the telemetry monitor has the meter
    bool has_meter(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            return false;
        }

        return true;
    }


    /// Check if the telemetry monitor has an event of the
    /// the qualified_name specified
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::event_name
    /// @return  True if the telemetry monitor has the event
    bool has_event(const std::string &qualified_name)
    {
        if (events.count(qualified_name) == 0)
        {
            return false;
        }

        return true;
    }


    /// Get a telemetry item using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::telemetry_name
    /// @return  The Telemetry
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


    /// Get an event using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::meter_name
    /// @return  The meter Telemetry
    Telemetry &get_meter(const std::string &qualified_name)
    {
        if (meters.count(qualified_name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}'", qualified_name);
        }

        return *meters[qualified_name];
    }


    /// Get an event using it's qualified name 
    ///
    /// @param qualified_name  The name matching the pattern
    ///                        block_name::event_name
    /// @return  The event Telemetry
    Telemetry &get_event(const std::string &qualified_name)
    {
        if (events.count(qualified_name) == 0)
        {
            SPDLOG_CRITICAL("Unknown meter '{}'", qualified_name);
        }

        return *events[qualified_name];
    }


    /// Get the size of all meter messages for meters of the 
    /// specified rate managed by the telemetry monitor. 
    ///
    /// @param update_rate  The meters update rate filter
    /// @param default_message_size  The size of the default, empty
    ///                              meters update message
    /// @return  Total size of all meters of specified rate managed
    size_t get_meters_size(const std::string &update_rate, size_t default_message_size)
    {
        size_t size = 0;
        for (auto &m : meters)
        {
            if (m.second->get_rate() == update_rate)
            {
                size += m.second->get_meters_size();
                size += default_message_size;
            }
        }

        return size;
    }


    /// Get the number of meters of the specified rate managed
    /// by the telemetry monitor
    ///
    /// @param update_rate  The meters update rate filter
    /// @return  Number of meters of specified rate managed
    int get_num_meters(const std::string &update_rate)
    {
        int num_items = 0;
        for (auto &m : meters)
        {
            if (m.second->get_rate() == update_rate)
            {
                ++num_items;
            }
        }

        return num_items;
    }


    /// Get the number of events managed by the telemetry monitor
    ///
    /// @return  Number of events managed
    int get_num_events()
    {
        return events.size();
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
    /// Pub initiated command to register with telemetry manager
    bool register_with_telemetry_manager()
    {
        TelemetryMessage message = telemetry_messages->get_default_command("pub_register_req");
        size_t meter_blob_size = telemetry_messages->get_default_meter().serialize_command().size();
        SPDLOG_DEBUG("meter blob \n{}\n size {}",  telemetry_messages->get_default_meter().serialize_command(), meter_blob_size);
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


    /// Pub initiated command to deregister with the telemetry manager
    bool deregister_with_telemetry_manager()
    {
        TelemetryMessage req = telemetry_messages->get_default_command("pub_deregister_req");

        const std::string req_str = req.serialize_command();
        if (sendto(telemetry_fd, req_str.c_str(), req_str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send pub_deregister_req.");
            return false;
        }

        // Wait for a response
        char buf[1024];
        struct sockaddr_un response_addr {};
        socklen_t response_addr_len = sizeof(response_addr);
        ssize_t recv_len = recvfrom(telemetry_fd, buf, sizeof(buf) - 1, 0,
                                    (struct sockaddr *)&response_addr, &response_addr_len);

        if (recv_len < 0)
        {
            SPDLOG_ERROR("Failed to receive response from telemetry manager.");
            return false;
        }

        buf[recv_len] = '\0';

        std::stringstream ss(buf);
        TelemetryMessage response(ss);

        if (response.get_message_name() == "pub_deregister_rsp" && response.get_parameters().get_value() == "OK")
        {
            SPDLOG_INFO("Received valid deregistration response: \n\n{}", response.serialize_command());
        }
        else
        {
            SPDLOG_ERROR("Received NOK response: \n\n{}", response.serialize_command());
            return false;
        }

        // clean up telemetry_manager assets and pause the telemetry monitor
        shm_addr.clear();
        stop();

        return true;
    }


    /// Update all meters with meters_callback when we recieve "update_meters_req"
    /// command from telemetry manager. Send "update_meters_rsp" to confirm
    ///
    /// @param message  The TelemetryMessage from the manager
    void update_meters(TelemetryMessage &message)
    {
        std::string rate = message.get_parameters().get_rate();
        int n = get_num_meters(rate);

        for (auto &m: meters)
        {
            if (m.second->get_rate() == rate)
            {
                m.second->send_meters(meters_callback, --n);
            }
        }

        TelemetryMessage rsp = telemetry_messages->get_default_command("update_meters_rsp");
        rsp.get_parameters().set_value("OK");
        rsp.get_parameters().set_rate(rate);

        const std::string rsp_str = rsp.serialize_command();
        if (sendto(telemetry_fd, rsp_str.c_str(), rsp_str.size(), 0,
                (struct sockaddr *)&telemetry_manager_addr, sizeof(telemetry_manager_addr)) < 0)
        {
            SPDLOG_ERROR("Failed to send update_meters_rsp.");
        }
    }


    /// Process messages from the telemetry manager
    ///
    /// @param message  TelemetryMessage from the telemetry manager
    void process_telemetry_message(TelemetryMessage &message)
    {
        if (message.get_message_name() == "update_meters_req")
        {
            update_meters(message);
        }
    }


    /// Send any events that have changed
    void send_events()
    {
        for (auto &e: events)
        {
            e.second->send_event_if_changed(event_callback);
        }
    }


    /// The main loop for monitoring telemetry data and executing commands.
    void monitor_loop() {
        if (telemetry_fd < 0)
        {
            SPDLOG_CRITICAL("Invalid connection socket.");
        }

        char buf[1024];
        struct sockaddr_un manager_addr;
        socklen_t manager_addr_len = sizeof(manager_addr);

        while (1)
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

            SPDLOG_INFO("Received message from telemetry manager: \n{}", buf);

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
    }


    /// Loop for managing events.
    void manage_events_loop() {
        while (1)
        {
            send_events();

            usleep(100000);
        }
    }


    /// Setup send telemetry callback member funcs
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

    std::unique_ptr<TelemetryMessage> telemetry_messages;

    std::thread monitor_thread;
    std::thread events_thread;

    std::map<std::string, std::unique_ptr<Telemetry>> meters;
    std::map<std::string, std::unique_ptr<Telemetry>> events;
};

} // namespace bosepro
