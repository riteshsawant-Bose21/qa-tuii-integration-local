
#include <bosepro/algorithm.h>

#include <cstdint>
#include <cstring>


namespace {


class SourceSelector : public bosepro::Algorithm {
public:
    SourceSelector(const bosepro::BlockConfiguration &configuration);
    virtual ~SourceSelector() = default;

    virtual void process() override;

private:
    int_fast32_t source_channels;
    int num_inputs;
    int_fast32_t selected_input = 1;
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

    assign_parameter("input", &selected_input);
}


void SourceSelector::process()
{
    int start_channel = (selected_input - 1) * source_channels;

    for (int_fast32_t channel = 0; channel < source_channels; channel++)
    {
        std::memcpy(out[channel], in[start_channel + channel],
                    get_frame_size() * sizeof(float));
    }   
}


} // namespace
