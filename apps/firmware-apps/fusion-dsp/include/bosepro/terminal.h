#pragma once

#include <bosepro/configuration.h>
#include <bosepro/dspmemory.h>
#include <bosepro/parameters.h>

#include <spdlog/spdlog.h>

#include <cstdint>
#include <memory>
#include <vector>


namespace bosepro {


/// A class to manage a terminal for a block.
class Terminal {
public:
    /// Create a terminal.
    ///
    /// @param  parameter  The terminal parameter definition.
    /// @param  configuration  The configuration to use for the terminal.
    /// @param  frame_size  The number of elements in the signal per frame.
    Terminal(const TerminalParameter &parameter,
             const TerminalConfiguration *configuration,
             int_fast32_t frame_size)
        : buffer(nullptr), single_buffer(nullptr), multi_buffer(nullptr),
          data_size(0), frame_size(frame_size),
          is_output_terminal(parameter.is_output()), bypass(false),
          bypass_source(nullptr)
    {
        if (configuration != nullptr)
        {
            num_channels = configuration->get_num_channels();
        }
        else
        {
            num_channels = parameter.get_default_channels();
        }

        if (is_output_terminal)
        {
            smoothed_gain = std::unique_ptr<float[]>(new float[num_channels]);

            for (int i = 0; i < num_channels; i++)
            {
                smoothed_gain[i] = 1.0f;
            }
        }

        SPDLOG_TRACE("Created {} terminal '{}' with {} channels.",
                     is_output_terminal ? "output" : "input",
                     parameter.get_name(), num_channels);
    }


    virtual ~Terminal() = default;


    /// Assign a single channel input terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(const T **buffer)
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

        single_buffer = reinterpret_cast<void **>(const_cast<T **>(buffer));
        *single_buffer = nullptr;
        multi_buffer = nullptr;
        data_size = sizeof(T);
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


    /// Assign a multi-channel input terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(std::vector<const T *> *buffer)
    {
        if (is_output_terminal)
        {
            SPDLOG_CRITICAL("Cannot assign input buffer to output terminal.");
            return;
        }

        multi_buffer = reinterpret_cast<std::vector<void *> *>(buffer);
        multi_buffer->reserve(num_channels);

        for (auto &channel : *multi_buffer)
        {
            channel = nullptr;
        }

        single_buffer = nullptr;
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


    /// Assign a single channel output terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(T **buffer)
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

        single_buffer = (void **)buffer;
        *single_buffer = nullptr;
        multi_buffer = nullptr;
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


    /// Assign a multi-channel output terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(std::vector<T *> *buffer)
    {
        if (!is_output_terminal)
        {
            SPDLOG_CRITICAL("Cannot assign output buffer to input terminal.");
            return;
        }

        multi_buffer = reinterpret_cast<std::vector<void *> *>(buffer);
        multi_buffer->reserve(num_channels);

        for (auto  &channel : *multi_buffer)
        {
            channel = nullptr;
        }

        single_buffer = nullptr;
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
        if (buffer == nullptr && single_buffer == nullptr
            && multi_buffer == nullptr)
        {
            SPDLOG_CRITICAL("No buffer assigned to terminal.");
        }

        if (!is_output_terminal)
        {
            return;
        }

        out_buffer = std::unique_ptr<char[]>(new char[frame_size * num_channels
                                             * data_size]);

        if (single_buffer != nullptr)
        {
            *single_buffer = out_buffer.get();
        }
        else
        {
            for (int i = 0; i < num_channels; i++)
            {
                (*multi_buffer)[i] = &out_buffer[i * frame_size * data_size];
            }
        }
    }


    /// Get the number of channels for the terminal.
    ///
    /// @return  The number of channels.
    int get_num_channels() const
    {
        return num_channels;
    }


    /// Get a pointer to the buffer for one channel of a terminal.
    ///
    /// @param  channel  The channel to get the buffer for.
    /// @return  A pointer to the buffer.
    void *get_buffer(int channel)
    {
        if (buffer != nullptr)
        {
            return buffer[channel];
        }
        else if (single_buffer != nullptr)
        {
            return *single_buffer;
        }
        else
        {
            return (*multi_buffer)[channel];
        }
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
            SPDLOG_CRITICAL("Input channel index out of range.");
            return;
        }

        if (output_channel < 0 || output_channel >= output_terminal.num_channels)
        {
            SPDLOG_CRITICAL("Output channel index out of range.");
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

        if (buffer != nullptr)
        {
            buffer[channel] = output_terminal.get_buffer(output_channel);
        }
        else if (single_buffer != nullptr)
        {
            *single_buffer = output_terminal.get_buffer(output_channel);
        }
        else
        {
            (*multi_buffer)[channel] =
                output_terminal.get_buffer(output_channel);
        }
    }


    /// Returns true if this terminal has a bypass source and can implement
    /// default bypass behavior.
    bool has_bypass() const
    {
        return bypass_source != nullptr;
    }


    /// Returns true if this terminal has a level meter and can implement
    /// default output metering behavior.
    bool has_meter() const
    {
        return meter.size() != 0;
    }


    /// Returns true if this terminal has a gain control and can implement
    /// default output gain behavior.
    bool has_gain() const
    {
        return gain.size() != 0;
    }


    /// Set the bypass source for the terminal.
    void set_bypass_source(Terminal *source)
    {
        bypass_source = source;
    }


    /// Process the output signals of an output terminal to implement default
    /// bypass, gain, and metering behavior.
    void process_output()
    {
        // Bypass by copying inputs to outputs.
        if (has_bypass() && bypass)
        {
            if (buffer != nullptr)
            {
                for (int channel = 0; channel < num_channels; channel++)
                {
                    memcpy(buffer[channel], bypass_source->get_buffer(channel),
                           frame_size * data_size);
                }
            }
            else if (single_buffer != nullptr)
            {
                memcpy(*single_buffer, bypass_source->get_buffer(0),
                       frame_size * data_size);
            }
            else
            {
                for (int i = 0; i < num_channels; i++)
                {
                    memcpy((*multi_buffer)[i], bypass_source->get_buffer(i),
                           frame_size * data_size);
                }
            }
        }

        // Apply gain and mute.
        if (has_gain())
        {
            if (single_buffer != nullptr)
            {
                float target_gain = mute[0] ? 0.0f : gain[0];
                float g = smoothed_gain[0];

                for (int i = 0; i < frame_size; i++)
                {
                    float *pbuf = (float *)*single_buffer;
                    pbuf[i] *= g;
                    g = smooth_coeff * g + (1.0f - smooth_coeff) * target_gain;
                }

                smoothed_gain[0] = g;
            }
            else
            {
                for (int i = 0; i < num_channels; i++)
                {
                    float target_gain = mute[i] ? 0.0f : gain[i];
                    float g = smoothed_gain[i];
                    float *pbuf;

                    if (buffer != nullptr)
                    {
                        pbuf = (float *)buffer[i];
                    }
                    else
                    {
                        pbuf = (float *)(*multi_buffer)[i];
                    }

                    for (int j = 0; j < frame_size; j++)
                    {
                        pbuf[j] *= g;
                        g = smooth_coeff * g + (1.0f - smooth_coeff) * target_gain;
                    }

                    smoothed_gain[i] = g;
                }
            }
        }

        // Calculate output peak meters.
        if (has_meter())
        {
            if (single_buffer != nullptr)
            {
                for (int i = 0; i < frame_size; i++)
                {
                    const float *pbuf = (const float *)*single_buffer;
                    float a = std::fabs(pbuf[i]);
                    meter[0] = std::max(meter[0], a);
                }
            }
            else
            {
                for (int i = 0; i < num_channels; i++)
                {
                    const float *pbuf;

                    if (buffer != nullptr)
                    {
                        pbuf = (const float *)buffer[i];
                    }
                    else
                    {
                        pbuf = (const float *)(*multi_buffer)[i];
                    }

                    for (int j = 0; j < frame_size; j++)
                    {
                        float a = std::fabs(pbuf[j]);
                        meter[i] = std::max(meter[i], a);
                    }
                }
            }
        }
    }


    /// Return true if this is an output terminal.
    bool is_output() const
    {
        return is_output_terminal;
    }


    /// Get a pointer to the gain values for implementing default output
    /// gain control.
    std::vector<float> *get_gain()
    {
        return &gain;
    }


    /// Get a pointer to the mute values for implementing default output
    /// mute control.
    std::vector<bool> *get_mute()
    {
        return &mute;
    }


    /// Get a pointer to the meter values for implementing default output
    /// meters.
    std::vector<float> *get_meter()
    {
        return &meter;
    }


    /// Get a pointer to the bypass flag for implementing default bypass
    /// control.
    bool *get_bypass()
    {
        return &bypass;
    }


private:
    void **buffer;
    void **single_buffer;
    std::vector<void *> *multi_buffer;
    std::unique_ptr<char[]> out_buffer;
    size_t data_size;
    int_fast32_t frame_size;
    int num_channels;
    bool is_output_terminal;

    std::vector<float> gain;
    std::unique_ptr<float[]> smoothed_gain;
    std::vector<bool> mute;
    std::vector<float> meter;
    bool bypass;
    Terminal *bypass_source;

    static const float smooth_coeff;
};


} // namespace bosepro
