
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
    int num_inputs;
    int_fast32_t selected_input = 1;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float []> out;

    ALGORITHM_DECLARE(SourceSelector);
};

ALGORITHM_REGISTER(SourceSelector, "source_selector");


SourceSelector::SourceSelector(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("in", num_inputs);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("input", &selected_input);
}


void SourceSelector::process()
{
    std::memcpy(out.get(), in[selected_input - 1],
                get_frame_size() * sizeof(float));
}


} // namespace
