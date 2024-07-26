
#include <bosepro/algorithm.h>

#include <cstdint>
#include <cstring>


namespace {


class Mixer : public bosepro::Algorithm {
public:
    Mixer(const bosepro::BlockConfiguration &configuration);
    virtual ~Mixer() = default;

    virtual void process() override;

private:
    int num_inputs;
    int num_outputs;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;

    bosepro::DspCoeffMemory<float *[]> gain;
    bosepro::DspCoeffMemory<bool *[]> mute;

    ALGORITHM_DECLARE(Mixer);
};

ALGORITHM_REGISTER(Mixer, "mixer");


Mixer::Mixer(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("in", num_inputs);
    get_terminal_num_channels("out", num_outputs);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_control("gain", gain);
    assign_control("mute", mute);
}


void Mixer::process()
{
    for (int output = 0; output < num_outputs; output++)
    {
        std::memset(out[output], 0, get_frame_size() * sizeof(float));

        for (int input = 0; input < num_inputs; input++)
        {
            float g = mute[input][output] ? 0.0f : gain[input][output];

            for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
            {
                out[output][sample] += g * in[input][sample];
            }
        }
    }
}


} // namespace
