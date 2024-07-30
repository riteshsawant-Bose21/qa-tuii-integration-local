#pragma once

#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/parameters.h>

#include <string>


namespace bosepro {


/// A class for managing the data of a meter.
class Meter {
public:
    /// Create a meter object based on the type of the parameter.
    ///
    /// @param  parameter  The parameter that defines the meter.
    /// @param  configuration  The configuration to use for the meter.
    Meter(const MeterParameter &parameter,
          const MeterConfiguration *configuration)
    {
        value_type = parameter.get_value_type();

        if (configuration != nullptr)
        {
            configuration->get_dimensions(num_rows, num_columns);
        }
    }

    virtual ~Meter() = default;


    /// Initialize the meter by resizing its storage to the configured
    /// dimensions.
    virtual void initialize() = 0;


    /// Assign a pointer to store the value of a scalar meter.
    ///
    /// @param  value  The pointer to store the value of the meter.
    template <typename T>
    void assign(const T *value);


    /// Assign meter memory to store the values of a vector meter.
    /// The memory will be re-sized to the length of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    template <typename T>
    void assign(DspMeterMemory<T[]> &value);


    /// Assign meter memory to store the values of a matrix meter.
    /// The memory will be re-sized to the dimensions of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    template <typename T>
    void assign(DspMeterMemory<T*[]> &value);


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


    /// Create a meter object based on the type of the parameter.
    ///
    /// @param  parameter  The parameter that defines the meter.
    /// @param  configuration  The configuration to use for the meter.
    /// @return  A pointer to the meter object.
    static Meter *create(const MeterParameter &parameter,
                         const MeterConfiguration *configuration);

private:
    std::string value_type;
    int num_rows;
    int num_columns;
};


/// A type-specific version of `Meter` for storing meter values.
template <typename T>
class MeterData : public Meter {
public:
    /// Create a meter object based on the type of the parameter.
    ///
    /// @param  parameter  The parameter that defines the meter.
    /// @param  configuration  The configuration to use for the meter.
    MeterData(const MeterParameter &parameter,
              const MeterConfiguration *configuration)
        : Meter(parameter, configuration), block_scalar_value(nullptr),
          block_vector_value(nullptr), block_matrix_value(nullptr)
    {
    }


    /// Assign a pointer to store the value of a scalar meter.
    ///
    /// @param  value  The pointer to store the value of the meter.
    void assign(const T *value)
    {
        block_scalar_value = value;
    }


    /// Assign meter memory to store the values of a vector meter.
    /// The memory will be re-sized to the length of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    void assign(DspMeterMemory<T[]> &value)
    {
        value.resize(get_num_rows());
        block_vector_value = value.get();
    }


    /// Assign meter memory to store the values of a matrix meter.
    /// The memory will be re-sized to the dimensions of the meter.
    ///
    /// @param  value  The memory to store the values of the meter.
    void assign(DspMeterMemory<T*[]> &value)
    {
        value.resize(get_num_rows(), get_num_columns());
        block_matrix_value = value.get();
    }


    /// Initialize the meter.
    virtual void initialize() override
    {
    }


private:
    const T *block_scalar_value;
    const T *block_vector_value;
    const T * const *block_matrix_value;
};


} // namespace bosepro
