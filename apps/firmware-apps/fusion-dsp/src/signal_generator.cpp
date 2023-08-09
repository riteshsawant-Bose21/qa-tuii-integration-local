
#include <bosepro/algorithm.h>

#include <cmath>


namespace {


class SignalGenerator : public bosepro::Algorithm {
public:
    SignalGenerator(const bosepro::BlockConfiguration &configuration);

    virtual ~SignalGenerator() = default;

    virtual void process() override;

private:
    float *out;
    float phase;
    float phase_inc;

    ALGORITHM_DECLARE(SignalGenerator);
};

ALGORITHM_REGISTER(SignalGenerator, "signal_generator");


SignalGenerator::SignalGenerator(const bosepro::BlockConfiguration
                                 &configuration)
    : bosepro::Algorithm(configuration)
{
    assign_terminal("out", &out);
    phase = 0.0f;
    phase_inc = 1000.0f * 2.0f * 3.14159265f / get_sample_rate();
}


void SignalGenerator::process()
{
    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        out[sample] = std::sin(phase);
        phase += phase_inc;

        if (phase > 2.0f * 3.14159265f)
        {
            phase -= 2.0f * 3.14159265f;
        }
    }
}


} // namespace
