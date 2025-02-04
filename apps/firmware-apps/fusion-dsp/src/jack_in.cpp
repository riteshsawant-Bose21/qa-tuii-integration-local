
#include <bosepro/algorithm.h>
#include <bosepro/jack.h>

#include <cstring>
#include <string>


namespace {


class JackIn : public bosepro::Jack {
public:
    JackIn(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspTelemetryMemory<float[]> out_meter;

    ALGORITHM_DECLARE(JackIn);
};

ALGORITHM_REGISTER(JackIn, "jack_in");


JackIn::JackIn(const bosepro::BlockConfiguration &configuration)
    : bosepro::Jack(configuration, true)
{
    assign_terminal("out", out);

    assign_telemetry("out_meter", out_meter);
}


void JackIn::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        float *in = ports[channel].get_buffer(get_frame_size());
        out_meter[channel] = *in;

        std::memcpy(out[channel], in, get_frame_size() * sizeof(float));
    }
}


} // namespace
