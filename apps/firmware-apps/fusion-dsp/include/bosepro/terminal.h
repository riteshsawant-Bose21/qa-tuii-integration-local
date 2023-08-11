#pragma once

#include <bosepro/configuration.h>
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
        : frame_size(frame_size)
    {
        is_output = parameter.is_output();

        if (configuration != nullptr)
        {
            num_channels = configuration->get_num_channels();
        }
        else
        {
            num_channels = parameter.get_default_channels();
        }

        SPDLOG_TRACE("Created {} terminal '{}' with {} channels.",
                     is_output ? "output" : "input", parameter.get_name(),
                     num_channels);
    }


    virtual ~Terminal() = default;


    /// Assign a single channel input terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(const T **buffer)
    {
        if (is_output)
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


    /// Assign a multi-channel input terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(std::vector<const T *> *buffer)
    {
        if (is_output)
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


    /// Assign a single channel output terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(T **buffer)
    {
        if (!is_output)
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


    /// Assign a multi-channel output terminal to a buffer.
    ///
    /// @param  buffer  A pointer to the buffer to assign.
    template <typename T>
    void assign(std::vector<T *> *buffer)
    {
        if (!is_output)
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


    /// Initialize the terminal.  This allocates memory for output buffers.
    void initialize()
    {
        if (single_buffer == nullptr && multi_buffer == nullptr)
        {
            SPDLOG_CRITICAL("No buffer assigned to terminal.");
        }

        if (!is_output)
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
        if (single_buffer != nullptr)
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
        if (is_output || !output_terminal.is_output)
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

        if (single_buffer != nullptr)
        {
            *single_buffer = output_terminal.get_buffer(output_channel);
        }
        else
        {
            (*multi_buffer)[channel] =
                output_terminal.get_buffer(output_channel);
        }
    }


private:
    bool is_output;
    int num_channels;
    int_fast32_t frame_size;
    size_t data_size;
    void **single_buffer;
    std::vector<void *> *multi_buffer;
    std::unique_ptr<char[]> out_buffer;
};


} // namespace bosepro
