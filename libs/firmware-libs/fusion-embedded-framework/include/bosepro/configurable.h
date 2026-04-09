#pragma once

#include <bosepro/configuration.h>
#include <bosepro/definition.h>

#include <cstdint>
#include <string>


namespace bosepro {


/// A base configurable object that can retrieve its settings from a
/// configuration object.
class Configurable {
public:
    /// Set the configuration for this object.  It initializes its frame size
    /// and sample rate based on the configuration.
    ///
    /// @param  configuration  The configuration for this object.
    Configurable(const Configuration &configuration);


    virtual ~Configurable() = default;


    virtual void process() = 0;


protected:
    /// Set the algorithm definitions for the entire system.
    ///
    /// @param  definition  The algorithm definitions.
    void set_definitions(const Definition &definitions);


    /// Get the definition for the named algorithm.
    ///
    /// @param  name  The name of the algorithm or module.
    /// @return  The definition for the algorithm.
    const ProcessorDefinition *get_definition(const std::string &name) const;


    /// Get the frame size for this object;
    ///
    /// @return  The frame size in samples.
    inline int_fast32_t get_frame_size() const
    {
        return frame_size;
    }


    /// Get the sample rate for this object.
    ///
    /// @return  The sample rate in Hz.
    inline int_fast32_t get_sample_rate() const
    {
        return sample_rate;
    }


private:
    static const Definition *definitions;
    int_fast32_t frame_size;
    int_fast32_t sample_rate;
};


} // namespace bosepro
