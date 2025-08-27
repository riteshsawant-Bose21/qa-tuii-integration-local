
#include <bosepro/algorithm.h>
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
    bool polarity;

    ALGORITHM_DECLARE(JackOut);
};

ALGORITHM_REGISTER(JackOut, "jack_out");


JackOut::JackOut(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, false)
{
    assign_terminal("in", in);
    assign_telemetry("in_meter", in_meter, bosepro::linear_to_db);
    assign_parameter("invert_polarity", &polarity);
}


void JackOut::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        int fs = get_frame_size();
        float *out = ports[channel].get_buffer(fs);

        std::memcpy(out, in[channel], fs * sizeof(float));

    if (polarity) {
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
