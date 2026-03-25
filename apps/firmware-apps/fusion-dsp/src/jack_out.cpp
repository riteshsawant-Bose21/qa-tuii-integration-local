
#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>
#include <bosepro/jack.h>

#include <cstring>
#include <string>


namespace {


class JackOut : public bosepro::Jack {
public:
    JackOut(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspTelemetryMemory<float[]> in_meter;
    bosepro::DspCoeffMemory<bool[]> polarity;
    bosepro::DspCoeffMemory<bool[]> mute;
    bosepro::DspCoeffMemory<float[]> gain;
    bosepro::DspStateMemory<float[]> smoothed_gain;
    static const float smooth_coeff;

    ALGORITHM_DECLARE(JackOut);
};

ALGORITHM_REGISTER(JackOut, "jack_out");


JackOut::JackOut(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, false)
{
    assign_terminal("in", in);
    assign_telemetry("in_meter", in_meter, bosepro::linear_to_db);
    assign_parameter("invert_polarity", polarity);
    assign_parameter("mute", mute);
    assign_parameter("gain", gain, bosepro::db_to_linear);

    smoothed_gain.resize(channels);
    for (int c = 0; c < channels; ++c) {
        smoothed_gain[c] = 1.0f;
    }
}


void JackOut::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        int fs = get_frame_size();
        float *out = ports[channel].get_buffer(fs);

        float target_gain = 1.0f;
        if (mute.get() && mute[channel]) {
            target_gain = 0.0f;
        } else if (gain.get()) {
            target_gain = gain[channel];
        }

        float g = smoothed_gain[channel];

        for (int i = 0; i < fs; ++i) {
            out[i] = in[channel][i] * g;
            g = smooth_coeff * g + (1.0f - smooth_coeff) * target_gain;
        }

        smoothed_gain[channel] = g;

        if (polarity[channel]) {
            for (int i = 0; i < fs; ++i) {
                out[i] = -out[i];
            }
        }

        in_meter[channel] = 0.0;

        for (int sample = 0; sample < fs; sample++)
        {
            float a = std::fabs(out[sample]);
            in_meter[channel] = std::max(in_meter[channel], a);
        }

    }
}


} // namespace

const float JackOut::smooth_coeff = 0.999f;
