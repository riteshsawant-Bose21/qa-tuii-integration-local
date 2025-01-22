#pragma once

#include <bosepro/constants.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>

#include <string>
#include <functional>
#include <unistd.h>
#include <fcntl.h>
#include <iostream>


namespace bosepro {


/// struct to hold data for meters/event callbacks
struct telemetry_cb_data {
    std::string message;
    std::string period_type;
    std::string value_type;
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
        telemetry_type = definition.get_telemetry_type(); // telemetry type is unsed internally--meter or event
        period_type = definition.get_period_type(); // period_type is HI, MED, or LO
        
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


    /// Get the number of rows in the telemetry, or 1 if the telemetry is a scalar.
    ///
    /// @return  The number of rows in the telemetry.
    int get_num_rows() const
    {
        return num_rows;
    }


    /// Get the number of columns in the telemetry, or 1 if the telemetry is a
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
    const std::string &get_period_type() const
    {
        return period_type;
    }


    /// Get the telemetry type.
    ///
    /// @return  The block name.
    const std::string &get_telemetry_type() const
    {
        return telemetry_type;
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
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback) = 0;


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
    std::string telemetry_type;
    std::string period_type;
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
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback) override
    {
        telemetry_cb_data cb_data = {};

        std::ostringstream message;

        message << "{ \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"meter_name\": \"" << this->get_name() << "\",";
        message << " \"value_type\": \"" << this->get_value_type() << "\",";
        message << " \"dimensions\": [0],"; // Scalar telemetry
        message << " \"value\": ";

        std::ostringstream val; 
        this->print_value(val, *block_value);
        message << val.str();

        SPDLOG_DEBUG("Writing meter {}:{} = {}", this->get_block_name(), this->get_name(), val.str());

        message << " }\n";

        cb_data.message = message.str();
        cb_data.period_type = this->get_period_type();
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

        auto now = std::chrono::steady_clock::now();
        auto now_us = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();

        message << "{ \"message_name\": \"event\",";
        message << " \"packet_id\": \"" << static_cast<uint64_t>(now_us) << "\",";
        message << " \"parameters\": {";
        message << " \"name\": \"" << "fusion_system_monitor" << "\",";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"event_name\": \"" << this->get_name() << "\",";
        message << " \"value_type\": \"" << this->get_value_type() << "\",";
        message << " \"dimensions\": [0],"; // Scalar telemetry
        message << " \"value\": ";

        // Append scalar value
        this->print_value(message, *block_value);

        message << " } }\n";

        cb_data.message = message.str();
        cb_data.period_type = this->get_period_type();
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

        return size;
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback  The callback function used to send the
    ///     meter data.
    /// @param  items_remaining  The number of meters left in the block.
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback) override
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
            std::ostringstream val; 
            this->print_value(val, block_value[row]);
            message << val.str() << ", ";

            SPDLOG_DEBUG("Writing meter {}:{} = {}", this->get_block_name(), this->get_name(), val.str());
        }
        this->print_value(message, block_value[this->get_num_rows() - 1]);
        message << "]";

        message << " }\n";

        cb_data.message = message.str();
        cb_data.period_type = this->get_period_type();
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

        auto now = std::chrono::steady_clock::now();
        auto now_us = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();

        message << "{ \"message_name\": \"event\",";
        message << " \"packet_id\": \"" << static_cast<uint64_t>(now_us) << "\",";
        message << " \"parameters\": {";
        message << " \"name\": \"" << "fusion_system_monitor" << "\",";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"event_name\": \"" << this->get_name() << "\",";
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
        cb_data.period_type = this->get_period_type();
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
    virtual void send_meters(std::function<void(telemetry_cb_data &)> meters_callback) override
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
                std::ostringstream val;
                this->print_value(val, block_value[row][col]);
                message << val.str();

                SPDLOG_DEBUG("Writing meter {}:{} = {}", this->get_block_name(), this->get_name(), val.str());
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
        cb_data.period_type = this->get_period_type();
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

        auto now = std::chrono::steady_clock::now();
        auto now_us = std::chrono::duration_cast<std::chrono::nanoseconds>(now.time_since_epoch()).count();

        message << "{ \"message_name\": \"event\",";
        message << " \"packet_id\": \"" << static_cast<uint64_t>(now_us) << "\",";
        message << " \"parameters\": {";
        message << " \"name\": \"" << "fusion_system_monitor" << "\",";
        message << " \"block_name\": \"" << this->get_block_name() << "\",";
        message << " \"event_name\": \"" << this->get_name() << "\",";
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
        cb_data.period_type = this->get_period_type();
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


} // namespace bosepro
