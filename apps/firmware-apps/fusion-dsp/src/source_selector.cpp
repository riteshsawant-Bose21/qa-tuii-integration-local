
#include <bosepro/algorithm.h>

#include <atomic>
#include <cstdint>
#include <cstring>


namespace {


class SourceSelector : public bosepro::Algorithm {
public:
    SourceSelector(const bosepro::BlockConfiguration &configuration);
    virtual ~SourceSelector() = default;

    virtual void process() override;

private:
    void update_selected_input();

    int_fast32_t source_channels;
    int num_inputs;
    int_fast32_t requested_input = 1;
    std::atomic<int_fast32_t> active_input{1};
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;

    ALGORITHM_DECLARE(SourceSelector);
};

ALGORITHM_REGISTER(SourceSelector, "source_selector");


SourceSelector::SourceSelector(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("source_channels", source_channels);
    get_terminal_num_channels("in", num_inputs);

    if (num_inputs % source_channels != 0)
    {
        SPDLOG_ERROR("Number of inputs ({}) is not a multiple of channels ({}) in source_selector", 
                        num_inputs, source_channels);
    }

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("input", &requested_input, POST_FUNCTION_SCALAR(update_selected_input));
    update_selected_input();
}


void SourceSelector::update_selected_input()
{
    const int max_inputs = (source_channels > 0) ? (num_inputs / source_channels) : 0;
    int_fast32_t clamped_input = requested_input;

    if (max_inputs <= 0)
    {
        clamped_input = 1;
    }
    else if (clamped_input < 1)
    {
        clamped_input = 1;
    }
    else if (clamped_input > max_inputs)
    {
        clamped_input = max_inputs;
    }

    active_input.store(clamped_input, std::memory_order_release);
}


void SourceSelector::process()
{
    const int selected_input = static_cast<int>(active_input.load(std::memory_order_acquire));
    const int max_inputs = (source_channels > 0) ? (num_inputs / source_channels) : 0;

    if (selected_input < 1 || selected_input > max_inputs)
    {
        for (int_fast32_t channel = 0; channel < source_channels; channel++)
        {
            std::memset(out[channel], 0, get_frame_size() * sizeof(float));
        }
        return;
    }

    const int start_channel = (selected_input - 1) * source_channels;

    for (int_fast32_t channel = 0; channel < source_channels; channel++)
    {
        std::memcpy(out[channel], in[start_channel + channel],
                    get_frame_size() * sizeof(float));
    }
}


} // namespace
