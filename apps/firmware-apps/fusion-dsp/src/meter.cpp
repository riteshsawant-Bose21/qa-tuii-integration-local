#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>

#include <cstdint>

namespace {


class Meter : public bosepro::Algorithm
{
public:
    Meter(const bosepro::BlockConfiguration &configuration);
    virtual ~Meter() = default;

    virtual void process() override;

private:
    int32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspTelemetryMemory<float []> level;

    ALGORITHM_DECLARE(Meter);
};

ALGORITHM_REGISTER(Meter, "meter");


Meter::Meter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("in", channels);
    assign_terminal("in", in);
    assign_telemetry("level", level, bosepro::linear_to_db);

}

void Meter::process()
{
    // Get the peak level meter for all channels and update the telemetry
    for (int_fast32_t channel = 0; channel < channels; channel++)
    {
        level[channel] = 0.0f;
        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            float abs_sample = std::fabs(in[channel][sample]);
            if (abs_sample > level[channel])
            {
                level[channel] = abs_sample;
            }

        }
    }

}


} // namespace