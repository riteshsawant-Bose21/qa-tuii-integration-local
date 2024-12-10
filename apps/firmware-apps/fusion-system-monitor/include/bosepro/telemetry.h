#pragma once

#include <bosepro/configuration.h>
#include <bosepro/definition.h>
#include <bosepro/dspmemory.h>

#include <string>
#include <functional>


namespace bosepro {


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
        value_type = definition.get_value_type();
        name = definition.get_name();
        num_rows = 1;
        num_columns = 1;
        int dimensions = definition.get_num_dimensions();
        telemetry_type = definition.get_telemetry_type();

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
    const std::string &get_telemetry_type()
    {
        return telemetry_type;
    }


    /// Pre-process the meters
    ///
    virtual void pre_process(void) = 0;


    /// Send a JSON-formatted meter string using the provided callback.
    ///
    /// @param  telemetry_callback  The callback function used to send the
    ///     meter data.
    virtual void send(void (*telemetry_callback)(const std::string &)) = 0;

private:
    std::string name;
    std::string block_name;
    std::string value_type;
    std::string telemetry_type;
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


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  telemetry_callback  The callback function used to send the
    ///     meter data.
    virtual void send(void (*telemetry_callback)(const std::string &)) override
    {
        std::ostringstream message;

        message << "{ \"source\": \"" << this->get_block_name() << "\"";
        message << ", \"name\": \"" << this->get_name() << "\"";
        message << ", \"type\": \"" << this->get_telemetry_type() << "\"";
        message << ", \"value\": ";

        this->print_value(message, *block_value);

        message << " }\n";
        telemetry_callback(message.str());
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


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  telemetry_callback  The callback function used to send the
    ///     meter data.
    virtual void send(void (*telemetry_callback)(const std::string &)) override
    {
        std::ostringstream message;

        message << "{ \"source\": \"" << this->get_block_name() << "\"";
        message << ", \"name\": \"" << this->get_name() << "\"";
        message << ", \"type\": \"" << this->get_telemetry_type() << "\"";
        message << ", \"value\": ";

        message << "[";
        for (int row = 0; row < this->get_num_rows() - 1; row++)
        {
            this->print_value(message, block_value[row]);
            message << ", ";
        }
        this->print_value(message, block_value[this->get_num_rows() - 1]);
        message << "]";

        message << " }\n";
        telemetry_callback(message.str());
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


    /// Send the data for this meter as a JSON-formatted string using the
    /// provided callback.
    ///
    /// @param  telemetry_callback  The callback function used to send the
    ///     meter data.
    virtual void send(void (*telemetry_callback)(const std::string &)) override
    {
        std::ostringstream message;
        
        message << "{ \"source\": \"" << this->get_block_name() << "\"";
        message << ", \"name\": \"" << this->get_name() << "\"";
        message << ", \"type\": \"" << this->get_telemetry_type() << "\"";
        message << ", \"value\": ";

        message << "[[";
        for (int row = 0; row < this->get_num_rows(); row++)
        {
            for (int col = 0; col < this->get_num_columns() - 1; col++)
            {
                this->print_value(message, block_value[row][col]);
                message << ", ";
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
        telemetry_callback(message.str());
    }


private:
    const T * const *block_value;
    std::function<void(int, int)> pre_function;
};


} // namespace bosepro
