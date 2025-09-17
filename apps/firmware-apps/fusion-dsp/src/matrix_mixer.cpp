
#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>

#include <cstdint>
#include <cstring>


namespace {


class MatrixMixer : public bosepro::Algorithm {
public:
    MatrixMixer(const bosepro::BlockConfiguration &configuration);
    virtual ~MatrixMixer() = default;

    virtual void process() override;

private:
    int num_inputs;
    int num_outputs;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;

    bosepro::DspCoeffMemory<float *[]> gain;
    bosepro::DspCoeffMemory<bool *[]> mute;
    bosepro::DspCoeffMemory<bool []> input_mute;

    bosepro::DspTelemetryMemory<bool []> input_presence;

    ALGORITHM_DECLARE(MatrixMixer);
};

ALGORITHM_REGISTER(MatrixMixer, "matrix_mixer");


MatrixMixer::MatrixMixer(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("in", num_inputs);
    get_terminal_num_channels("out", num_outputs);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("gain", gain, bosepro::db_to_linear);
    assign_parameter("mute", mute);
    assign_parameter("input_mute", input_mute);

    assign_telemetry("input_presence", input_presence);
}


void MatrixMixer::process()
{
    for (int input = 0; input < num_inputs; input++)
    {
        input_presence[input] = false;

        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            if (std::fabs(in[input][sample]) > 0.01f)
            {
                input_presence[input] = true;
            }
        }
    }


    for (int output = 0; output < num_outputs; output++)
    {
        std::memset(out[output], 0, get_frame_size() * sizeof(float));

        for (int input = 0; input < num_inputs; input++)
        {
            if (input_mute[input]) {
                continue;
            }

            float g = mute[input][output] ? 0.0f : gain[input][output];

            for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
            {
                out[output][sample] += g * in[input][sample];
            }
        }
    }
}


} // namespace
