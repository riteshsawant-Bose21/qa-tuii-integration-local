#pragma once

#include <bosepro/constants.h>
#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>
#include <bosepro/telemetry_message.h>

#include <string>
#include <functional>
#include <unistd.h>
#include <fcntl.h>
#include <iostream>


namespace bosepro {


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

        num_dimensions = definition.get_num_dimensions();
        if (num_dimensions != 0)
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


    /// Create a telemetry object based on the type of the definition.
    ///
    /// @param  definition  The telemetry definition.
    /// @param  definition  The processor definition.
    /// @param  configuration  The configuration to use for the telemetry.
    /// @return  A pointer to the telemetry object.
    static Telemetry *create(const TelemetryDefinition &definition,
                             const ProcessorDefinition &processor,
                             const BlockConfiguration *configuration);


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


    /// Get the name of this telemetry.
    ///
    /// @return  The name of the telemetry.
    const std::string get_block_name()
    {
        return block_name;
    }


    /// Get the name of this telemetry.
    ///
    /// @return  The name of the telemetry.
    const std::string get_name()
    {
        return name;
    }


    /// Get the name of the type of the telemetry's value.
    ///
    /// @return  The name of the type of the telemetry's value.
    const std::string get_dimensions() const
    {
        std::string dim = "[";
        switch(num_dimensions) 
        {
            case 0:
                dim.append("0");
                break;
            case 1:
                dim.append(std::to_string(num_rows));
                break;
            case 2:
                dim.append(std::to_string(num_rows) + ", " + std::to_string(num_columns));
                break;
            case 3:
                SPDLOG_ERROR("Bad 'num_dimensions' {}", num_dimensions);
        }
        dim.append("]");

        return dim;
    }


    /// Get the name of the type of the telemetry's value.
    ///
    /// @return  The name of the type of the telemetry's value.
    const std::string get_value_type() const
    {
        return value_type;
    }


    /// Get the telemetry type.
    ///
    /// @return  The block name.
    const std::string get_period_type() const
    {
        return period_type;
    }


    /// Get the telemetry type.
    ///
    /// @return  The block name.
    const std::string get_telemetry_type() const
    {
        return telemetry_type;
    }


    /// Set the name of the block that owns this telemetry.
    ///
    /// @param  name  The block name.
    void set_block_name(const std::string &name)
    {
        block_name = name;
    }


    /// Try to calculate the minimum size the meters will take up in memory
    ///
    /// @return  The size of the meters json blob
    virtual size_t get_meter_size() = 0;


    /// Pre-process the telemetry
    virtual void pre_process() = 0;


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  meters_callback   The callback function used to send the
    ///     meter data.
    /// @param  meter_message     A TelemetryMessage with the meter data
    /// @param  meters_remaining  The number of meters left in the block.
    virtual void send_meter(std::function<void(TelemetryMessage, std::string, size_t)> meters_callback, 
                                               TelemetryMessage meter_msg, 
                                               size_t meters_remaining) = 0;


    /// Send a JSON-formatted event string using the provided callback.
    ///
    /// @param  event_callback  The callback function used to send the event data.
    virtual void send_event(std::function<void(TelemetryMessage)> event_callback, 
                            TelemetryMessage event_msg) = 0;


    /// Wrapper for send_event that checks for changed values
    ///
    /// @param  event_callback  The callback function used to send the event data.
    virtual void send_event_if_changed(std::function<void(TelemetryMessage)> event_callback, 
                                       TelemetryMessage event_msg) = 0;


private:
    std::string name;
    std::string block_name;
    std::string value_type;
    std::string telemetry_type;
    std::string period_type;
    int num_dimensions;
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
    virtual size_t get_meter_size() override
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
    /// @param  meters_callback   The callback function used to send the
    ///     meter data.
    /// @param  meter_message     A TelemetryMessage with the meter data
    /// @param  meters_remaining  The number of meters left in the block.
    virtual void send_meter(std::function<void(TelemetryMessage, std::string, size_t)> meters_callback, 
                                               TelemetryMessage meter_msg, 
                                               size_t meters_remaining) override
    {
        if (!block_value) {
            SPDLOG_ERROR("block_value is null in send_meter for {}::{}!", this->get_block_name(), this->get_name());
            return; // or throw
        }

        meter_msg.set_block_name(this->get_block_name());
        meter_msg.set_meter_name(this->get_name());
        meter_msg.set_value_type(this->get_value_type());
        meter_msg.set_dimensions(this->get_dimensions());
        meter_msg.set_value(*block_value);

        SPDLOG_TRACE("Writing meter: \n\n{}", meter_msg.serialize_message());

        meters_callback(meter_msg, this->get_period_type(), meters_remaining);
    }


    /// Send the data for this event as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event(std::function<void(TelemetryMessage)> event_callback, TelemetryMessage event_msg) override
    {
        event_msg.set_packet_id();
        TelemetryMessage &params(event_msg.get_parameters());
        params.set_block_name(this->get_block_name());
        params.set_event_name(this->get_name());
        params.set_value_type(this->get_value_type());
        params.set_dimensions(this->get_dimensions());
        params.set_value(*block_value);

        SPDLOG_TRACE("Sending event: \n\n{}", event_msg.serialize_message());

        event_callback(event_msg);
    }


    /// Wrapper for send_event to check for changed value
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event_if_changed(std::function<void(TelemetryMessage)> event_callback, TelemetryMessage event_msg) override
    {
        if (!block_value_prev || *block_value_prev != *block_value) {
            if (!block_value_prev) {
                block_value_prev = std::make_unique<T>(*block_value); // Allocate memory for block_value_prev
            } else {
                send_event(event_callback, event_msg); // Send event if value has changed
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
    virtual size_t get_meter_size() override
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
            size += static_cast<const std::string>(block_value[this->get_num_rows() - 1]).size() + 2;
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
    /// @param  meters_callback   The callback function used to send the
    ///     meter data.
    /// @param  meter_message     A TelemetryMessage with the meter data
    /// @param  meters_remaining  The number of meters left in the block.
    virtual void send_meter(std::function<void(TelemetryMessage, std::string, size_t)> meters_callback, 
                                               TelemetryMessage meter_msg, 
                                               size_t meters_remaining) override
    {
        if (!block_value) {
            SPDLOG_ERROR("block_value is null in send_meter for {}::{}!", this->get_block_name(), this->get_name());
            return; // or throw
        }

        meter_msg.set_block_name(this->get_block_name());
        meter_msg.set_meter_name(this->get_name());
        meter_msg.set_value_type(this->get_value_type());
        meter_msg.set_dimensions(this->get_dimensions());
        std::vector<T> tmp(block_value, block_value + this->get_num_rows());
        meter_msg.set_value(tmp);

        SPDLOG_TRACE("Writing meter: \n\n{}", meter_msg.serialize_message());

        meters_callback(meter_msg, this->get_period_type(), meters_remaining);
    }


    /// Send the data for this event as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event(std::function<void(TelemetryMessage)> event_callback, TelemetryMessage event_msg) override
    {
        std::vector<T> tmp(block_value, block_value + this->get_num_rows());
        
        event_msg.set_packet_id();
        TelemetryMessage &params(event_msg.get_parameters());
        params.set_block_name(this->get_block_name());
        params.set_event_name(this->get_name());
        params.set_value_type(this->get_value_type());
        params.set_dimensions(this->get_dimensions());
        params.set_value(tmp);

        SPDLOG_TRACE("Sending event: \n\n{}", event_msg.serialize_message());

        event_callback(event_msg);
    }


    /// Wrapper for send_event to check for changed value
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event_if_changed(std::function<void(TelemetryMessage)> event_callback, TelemetryMessage event_msg) override 
    {
        // Initialize block_value_prev if it doesn't exist.
        if (!block_value_prev) {
            block_value_prev = std::make_unique<std::vector<T>>(this->get_num_rows());
        }

        // Check for changes in values.
        if (!std::equal(block_value, block_value + this->get_num_rows(), block_value_prev->begin())) {
            send_event(event_callback, event_msg);

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
    virtual size_t get_meter_size() override
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
    /// @param  meters_callback   The callback function used to send the
    ///     meter data.
    /// @param  meter_message     A TelemetryMessage with the meter data
    /// @param  meters_remaining  The number of meters left in the block.
    virtual void send_meter(std::function<void(TelemetryMessage, std::string, size_t)> meters_callback, 
                                               TelemetryMessage meter_msg, 
                                               size_t meters_remaining) override
    {
        if (!block_value) {
            SPDLOG_ERROR("block_value is null in send_meter for {}::{}!", this->get_block_name(), this->get_name());
            return; // or throw
        }

        meter_msg.set_block_name(this->get_block_name());
        meter_msg.set_meter_name(this->get_name());
        meter_msg.set_value_type(this->get_value_type());
        meter_msg.set_dimensions(this->get_dimensions());
        std::vector<std::vector<T>> tmp(this->get_num_rows());
        for (int r = 0; r < this->get_num_rows(); r++) {
            tmp[r].assign(block_value[r], block_value[r] + this->get_num_columns());
        }
        meter_msg.set_value(tmp);

        SPDLOG_TRACE("Writing meter: \n\n{}", meter_msg.serialize_message());

        meters_callback(meter_msg, this->get_period_type(), meters_remaining);
    }


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  event_callback  The callback function used to send the
    ///     meter data.
    virtual void send_event(std::function<void(TelemetryMessage)> event_callback, TelemetryMessage event_msg) override
    {
        std::vector<std::vector<T>> tmp(this->get_num_rows());
        for (int r = 0; r < this->get_num_rows(); r++) {
            tmp[r].assign(block_value[r], block_value[r] + this->get_num_columns());
        }

        event_msg.set_packet_id();
        TelemetryMessage &params(event_msg.get_parameters());
        params.set_block_name(this->get_block_name());
        params.set_event_name(this->get_name());
        params.set_value_type(this->get_value_type());
        params.set_dimensions(this->get_dimensions());
        params.set_value(tmp);

        SPDLOG_TRACE("Sending event: \n\n{}", event_msg.serialize_message());

        event_callback(event_msg);
    }


    /// Wrapper for send_event to check for changed value
    ///
    /// @param  event_callback  The callback function used to send the
    ///     event data.
    virtual void send_event_if_changed(std::function<void(TelemetryMessage)> event_callback, TelemetryMessage event_msg) override 
    {
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

            send_event(event_callback, event_msg);

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
