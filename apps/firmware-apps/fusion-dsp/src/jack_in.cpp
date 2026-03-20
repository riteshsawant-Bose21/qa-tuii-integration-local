
#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>
#include <bosepro/jack.h>

#include <cstring>
#include <string>
#include <cmath>


namespace {


class JackIn : public bosepro::Jack {
public:
    JackIn(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<float *[]> out;

    bosepro::DspTelemetryMemory<float[]> in_meter;

    bosepro::DspCoeffMemory<bool[]> polarity;

    ALGORITHM_DECLARE(JackIn);
};

ALGORITHM_REGISTER(JackIn, "jack_in");


JackIn::JackIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, true)
{
    assign_terminal("out", out);

    assign_telemetry("in_meter", in_meter, bosepro::linear_to_db);

    assign_parameter("invert_polarity", polarity);
}


void JackIn::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        float *in = ports[channel].get_buffer(get_frame_size());

        in_meter[channel] = 0.0;

        for (int i = 0; i < get_frame_size(); ++i)
        {
            float a = std::fabs(in[i]);
            in_meter[channel] = std::max(in_meter[channel], a);
        }

        std::memcpy(out[channel], in, get_frame_size() * sizeof(float));

        if (polarity[channel]) {
            for (int i = 0; i < get_frame_size(); ++i) {
                out[channel][i] = -out[channel][i];
            }
        }
    }
}


} // namespace
