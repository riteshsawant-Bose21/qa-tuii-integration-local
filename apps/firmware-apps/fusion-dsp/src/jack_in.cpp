
#include <bosepro/algorithm.h>
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

    bosepro::DspTelemetryMemory<float[]> out_meter;
    bosepro::DspTelemetryMemory<float[]> in_meter;

    bool polarity;

    ALGORITHM_DECLARE(JackIn);
};

ALGORITHM_REGISTER(JackIn, "jack_in");


JackIn::JackIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, true)
{
    assign_terminal("out", out);

    assign_telemetry("out_meter", out_meter);
    assign_telemetry("in_meter", in_meter, bosepro::linear_to_db);

    assign_parameter("invert_polarity", &polarity);
}


void JackIn::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        int fs = get_frame_size();
        float *in = ports[channel].get_buffer(fs);

    if (polarity) {
            for (int i = 0; i < fs; ++i) {
                in[i] = -in[i]; 
            }
        }

        in_meter[channel] = 0.0;

        for (int i = 0; i < fs; ++i)
        {
            float a = std::fabs(in[i]);
            in_meter[channel] = std::max(in_meter[channel], a);
        }

        out_meter[channel] = *in; 

        std::memcpy(out[channel], in, fs * sizeof(float));
    }
}


} // namespace
