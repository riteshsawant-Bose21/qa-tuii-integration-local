
#include <bosepro/algorithm.h>

#include <cstdint>


namespace {


class Delay : public bosepro::Algorithm
{
public:
    Delay(const bosepro::BlockConfiguration &configuration);
    virtual ~Delay() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    int_fast32_t max_delay;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspCoeffMemory<int_fast32_t[]> delay;
    bosepro::DspCoeffMemory<bool[]> channel_bypass;
    bosepro::DspStateMemory<float *[]> buffer;
    int_fast32_t buffer_size;
    int_fast32_t write_index;

    ALGORITHM_DECLARE(Delay);
};

ALGORITHM_REGISTER(Delay, "delay");


Delay::Delay(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);
    get_property("max_delay", max_delay);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("delay", delay);
    assign_parameter("channel_bypass", channel_bypass);

    buffer_size = max_delay + 2 * get_frame_size() - 1;
    buffer_size /= get_frame_size();
    buffer_size *= get_frame_size();

    buffer.resize(channels, buffer_size);

    write_index = 0;
}


void Delay::process()
{
    for (int_fast32_t channel = 0; channel < channels; channel++)
    {
        std::memcpy(&buffer[channel][write_index], in[channel],
                    get_frame_size() * sizeof(float));

        int_fast32_t read_index = write_index - delay[channel];

        if (read_index < 0)
        {
            read_index += buffer_size;
        }

        if (channel_bypass[channel])
        {
            read_index = write_index;
        }

        int_fast32_t first_read = get_frame_size();
        int_fast32_t second_read = 0;

        if (read_index + first_read > buffer_size)
        {
            first_read = buffer_size - read_index;
            second_read = get_frame_size() - first_read;
        }

        std::memcpy(out[channel], &buffer[channel][read_index],
                    first_read * sizeof(float));

        if (second_read > 0)
        {
            std::memcpy(&out[channel][first_read], buffer[channel],
                        second_read * sizeof(float));
        }
    }

    write_index += get_frame_size();

    if (write_index >= buffer_size)
    {
        write_index = 0;
    }
}


} // namespace
