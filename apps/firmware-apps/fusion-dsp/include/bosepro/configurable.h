#pragma once

#include <bosepro/configuration.h>
#include <bosepro/definition.h>

#include <spdlog/spdlog.h>

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
    Configurable(const Configuration &configuration)
    {
        if (configuration.has_property("frame_size"))
        {
            configuration.get_property("frame_size").get_value(frame_size);
        }
        else
        {
            frame_size = 32;
        }

        if (configuration.has_property("sample_rate"))
        {
            configuration.get_property("sample_rate").get_value(sample_rate);
        }
        else
        {
            sample_rate = 48000;
        }
    }


    virtual ~Configurable() = default;


    virtual void process() = 0;


protected:
    /// Set the algorithm definitions for the entire system.
    ///
    /// @param  definition  The algorithm definitions.
    void set_definitions(const Definition &definitions)
    {
        this->definitions = &definitions;
    }


    /// Get the definition for the named algorithm.
    ///
    /// @param  algorithm_name  The name of the algorithm.
    /// @return  The definition for the algorithm.
    const AlgorithmDefinition *get_definition(const std::string &algorithm_name) const
    {
        if (!definitions->has_algorithm(algorithm_name))
        {
            SPDLOG_CRITICAL("No definition available for algorithm '{}'.",
                            algorithm_name);
        }

        return &definitions->get_algorithm(algorithm_name);
    }


    /// Get the frame size for this object;
    ///
    /// @return  The frame size in samples.
    int_fast32_t get_frame_size() const
    {
        return frame_size;
    }


    /// Get the sample rate for this object.
    ///
    /// @return  The sample rate in Hz.
    int_fast32_t get_sample_rate() const
    {
        return sample_rate;
    }


private:
    static const Definition *definitions;
    int_fast32_t frame_size;
    int_fast32_t sample_rate;
};


} // namespace bosepro
