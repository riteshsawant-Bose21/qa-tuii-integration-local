#pragma once

#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/definition.h>

#include <spdlog/spdlog.h>

#include <cstdint>
#include <memory>
#include <vector>


namespace bosepro {


/// A class to manage universal algorithm parameters (gain, mute, bypass, and
/// level meter) for output terminals.
class TerminalOutputProcessor {
public:
    TerminalOutputProcessor()
        : smoothed_gain(), gain(), mute(), meter(), output_buffer(nullptr), bypass_buffer(nullptr),
          frame_size(0), num_channels(0)
    { }

    void initialize(int_fast32_t frame_size, int num_channels, void **buffer)
    {
        this->frame_size = frame_size;
        this->num_channels = num_channels;
        output_buffer = (float **)buffer;
        smoothed_gain.resize(num_channels);
    }

    /// Process the output signals of an output terminal to implement default
    /// bypass, gain, and metering behavior.
    void process()
    {
        // Bypass by copying inputs to outputs.
        if (has_bypass() && bypass)
        {
            for (int channel = 0; channel < num_channels; channel++)
            {
                memcpy(output_buffer[channel], bypass_buffer[channel],
                       frame_size * sizeof(float));
            }
        }

        // Apply gain and mute.
        if (has_gain() || has_mute())
        {
            for (int channel = 0; channel < num_channels; channel++)
            {
                float target_gain = (has_mute() && mute[channel]) ?
                    0.0f : (has_gain() ? gain[channel] : 1.0);
                float g = smoothed_gain[channel];
                float *pbuf = (float *)output_buffer[channel];

                for (int sample = 0; sample < frame_size; sample++)
                {
                    pbuf[sample] *= g;
                    g = smooth_coeff * g + (1.0f - smooth_coeff) * target_gain;
                }

                smoothed_gain[channel] = g;
            }
        }

        // Calculate output peak meters.
        if (has_meter())
        {
            for (int channel = 0; channel < num_channels; channel++)
            {
                const float *pbuf = (const float *)output_buffer[channel];
                meter[channel] = 0.0;

                for (int sample = 0; sample < frame_size; sample++)
                {
                    float a = std::fabs(pbuf[sample]);
                    meter[channel] = std::max(meter[channel], a);
                }
            }
        }
    }

    DspCoeffMemory<float[]> &get_gain()
    {
        return gain;
    }

    DspCoeffMemory<bool[]> &get_mute()
    {
        return mute;
    }

    DspMeterMemory<float[]> &get_meter()
    {
        return meter;
    }

    bool *get_bypass()
    {
        return &bypass;
    }

    void set_bypass_source(void **buffer)
    {
        bypass_buffer = (const float **)buffer;
    }


private:
    static const float smooth_coeff;

    bool has_bypass() const
    {
        return bypass_buffer != nullptr;
    }

    bool has_gain() const
    {
        return gain.get() != nullptr;
    }

    bool has_mute() const
    {
        return mute.get() != nullptr;
    }

    bool has_meter() const
    {
        return meter.get() != nullptr;
    }

    DspStateMemory<float[]> smoothed_gain;
    DspCoeffMemory<float[]> gain;
    DspCoeffMemory<bool[]> mute;
    DspMeterMemory<float[]> meter;
    float **output_buffer;
    const float **bypass_buffer;
    int_fast32_t frame_size;
    int num_channels;
    bool bypass;
};


/// A class to manage a terminal for a block.
class Terminal {
public:
    /// Create a terminal.
    ///
    /// @param  definition  The terminal definition.
    /// @param  configuration  The configuration to use for the terminal.
    /// @param  frame_size  The number of elements in the signal per frame.
    Terminal(const TerminalDefinition &definition,
             const BlockConfiguration *configuration,
             int_fast32_t frame_size)
        : buffer(nullptr), top(nullptr), data_size(0), frame_size(frame_size),
          is_output_terminal(definition.is_output())
    {
        if (definition.has_channels())
        {
            std::string property_name;
            int channels;
            channels = definition.get_channels(property_name);

            if (!property_name.empty())
            {
                if (configuration->has_property(property_name))
                {
                    const PropertyConfiguration &pc =
                        configuration->get_property(property_name);
                    pc.get_value(channels);
                }
                else
                {
                    const PropertyDefinition &pd =
                        definition.get_property(property_name);
                    pd.get_default_value(channels);
                }
            }

            num_channels = channels;
        }
        else if (configuration->has_terminal(definition.get_name()))
        {
            const TerminalConfiguration &tc =
                configuration->get_terminal(definition.get_name());
            num_channels = tc.get_num_channels();
        }
        else
        {
            definition.get_minimum_channels();
        }

        SPDLOG_TRACE("Created {} terminal '{}' with {} channels.",
                     is_output_terminal ? "output" : "input",
                     definition.get_name(), num_channels);
    }


    /// Assign a single channel input terminal to its memory.
    ///
    /// @param  signal_memory  A pointer to the signal memory to assign.
    template <typename T>
    void assign(DspSignalMemory<const T[]> &signal_memory)
    {
        if (is_output_terminal)
        {
            SPDLOG_CRITICAL("Cannot assign input buffer to output terminal.");
            return;
        }

        if (num_channels != 1)
        {
            SPDLOG_CRITICAL("Cannot assign single channel input buffer to "
                            "multi-channel terminal.");
            return;
        }

        signal_memory.resize(0);
        buffer = reinterpret_cast<void **>(&signal_memory);
        data_size = sizeof(T);
    }


    /// Assign a multi-channel input terminal to its memory.
    ///
    /// @param  signal_memory  A pointer to the signal memory to assign.
    template <typename T>
    void assign(DspSignalMemory<const T*[]> &signal_memory)
    {
        if (is_output_terminal)
        {
            SPDLOG_CRITICAL("Cannot assign input buffer to output terminal.");
            return;
        }

        signal_memory.resize(num_channels, 0);
        buffer = (void **)signal_memory.get();

        for (int i = 0; i < num_channels; i++)
        {
            buffer[i] = nullptr;
        }

        data_size = sizeof(T);
    }


    /// Assign a single channel output terminal to its memory.
    ///
    /// @param  signal_memory  A pointer to the signal memory to assign.
    template <typename T>
    void assign(DspSignalMemory<T[]> &signal_memory)
    {
        if (!is_output_terminal)
        {
            SPDLOG_CRITICAL("Cannot assign output buffer to input terminal.");
            return;
        }

        if (num_channels != 1)
        {
            SPDLOG_CRITICAL("Cannot assign single channel output buffer to "
                            "multi-channel terminal.");
            return;
        }

        signal_memory.resize(frame_size/*, RegionManager::CACHE_LINE_SIZE*/);
        buffer = (void **)&signal_memory;
        data_size = sizeof(T);
    }


    /// Assign a multi-channel output terminal to its memory.
    ///
    /// @param  signal_memory  A pointer to the signal memory to assign.
    template <typename T>
    void assign(DspSignalMemory<T*[]> &signal_memory)
    {
        if (!is_output_terminal)
        {
            SPDLOG_CRITICAL("Cannot assign output buffer to input terminal.");
            return;
        }

        signal_memory.resize(num_channels, frame_size /*,
                             RegionManager::CACHE_LINE_SIZE*/);
        buffer = (void **)signal_memory.get();
        data_size = sizeof(T);
    }


    /// Initialize the terminal.  This allocates memory for output buffers.
    void initialize()
    {
        if (buffer == nullptr)
        {
            SPDLOG_CRITICAL("No buffer assigned to terminal.");
        }

        if (top != nullptr)
        {
            top->initialize(frame_size, num_channels, buffer);
        }
    }


    /// Get the number of channels for the terminal.
    ///
    /// @return  The number of channels.
    int get_num_channels() const
    {
        return num_channels;
    }


    /// Get the frame size for the terminal.
    ///
    /// @return  The frame size.
    int get_frame_size() const
    {
        return frame_size;
    }


    /// Get a pointer to the buffer for one channel of a terminal.
    ///
    /// @return  A pointer to the buffer.
    const void **get_buffers() const
    {
        return (const void **)buffer;
    }


    /// Get a pointer to the buffer for one channel of a terminal.
    ///
    /// @return  A pointer to the buffer.
    void **get_buffers()
    {
        return buffer;
    }



    /// Get a pointer to the buffer for one channel of a terminal.
    ///
    /// @param  channel  The channel to get the buffer for.
    /// @return  A pointer to the buffer.
    void *get_buffer(int channel)
    {
        return buffer[channel];
    }


    /// Connect the terminal to an output terminal.
    ///
    /// @param  channel  The index of the input channel to connect.
    /// @param  output_terminal  The output terminal to connect to.
    /// @param  output_channel  The index of the output channel to connect to.
    void connect(int channel, Terminal &output_terminal, int output_channel)
    {
        if (is_output_terminal || !output_terminal.is_output())
        {
            SPDLOG_CRITICAL("A connection must be made from an input terminal "
                            "to an output terminal.");
            return;
        }

        if (channel < 0 || channel >= num_channels)
        {
            SPDLOG_CRITICAL("Input channel index ({}) out of range ({}).",
                            channel, num_channels);
            return;
        }

        if (output_channel < 0 || output_channel >= output_terminal.num_channels)
        {
            SPDLOG_CRITICAL("Output channel index ({}) out of range ({}).",
                            output_channel, output_terminal.num_channels);
            return;
        }

        if (frame_size != output_terminal.frame_size)
        {
            SPDLOG_CRITICAL("Cannot connect terminals with different frame "
                            "sizes.");
            return;
        }

        if (data_size != output_terminal.data_size)
        {
            SPDLOG_CRITICAL("Cannot connect terminals with different data "
                            "types.");
            return;
        }

        buffer[channel] = output_terminal.get_buffer(output_channel);
    }


    /// Return true if this is an output terminal.
    bool is_output() const
    {
        return is_output_terminal;
    }


    /// Assign a terminal output processor object to this terminal.
    void set_output_processor(TerminalOutputProcessor *top)
    {
        this->top = top;
    }


    /// Return a pointer to the output processor for this terminal, if it has
    /// one, or `nullptr` if it doesn't.
    TerminalOutputProcessor *get_output_processor()
    {
        return top;
    }


private:
    void **buffer;
    TerminalOutputProcessor *top;
    size_t data_size;
    int_fast32_t frame_size;
    int num_channels;
    bool is_output_terminal;
};


} // namespace bosepro
