
#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>

#include <cmath>
#include <cstdint>


namespace {


class Ducker : public bosepro::Algorithm
{
public:
    Ducker(const bosepro::BlockConfiguration &configuration);
    virtual ~Ducker() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspSignalMemory<const float *[]> sidechain_in;
    float threshold;
    float range;
    float attack_time;
    float attack_coeff;
    float decay_time;
    float decay_coeff;
    float hold_time;
    int_fast32_t hold_count;
    int_fast32_t hold_counter;
    float level_attack_coeff;
    float level_release_coeff;
    float current_gain;
    bool is_active;
    float smoothed_level;

    void update_hold();
    void update_attack();
    void update_decay();

    ALGORITHM_DECLARE(Ducker);
};

ALGORITHM_REGISTER(Ducker, "ducker");


Ducker::Ducker(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);
    assign_terminal("sidechain_in", sidechain_in);

    assign_parameter("threshold", &threshold, bosepro::db_to_linear);
    assign_parameter("range", &range, bosepro::db_to_linear);
    assign_parameter("attack", &attack_time,
                     POST_FUNCTION_SCALAR(update_attack));
    assign_parameter("hold", &hold_time,
                     POST_FUNCTION_SCALAR(update_hold));
    assign_parameter("decay", &decay_time,
                     POST_FUNCTION_SCALAR(update_decay));

    assign_telemetry("gain_meter", &current_gain);

    level_attack_coeff = 0.341f;
    current_gain = 1.0f;
    hold_counter = 0;
    smoothed_level = 0.0f;
}


void Ducker::process()
{
    float g = current_gain;

    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        float level = std::fabs(sidechain_in[0][sample]);

        smoothed_level += (level - smoothed_level) *
            ((level > smoothed_level) ? level_attack_coeff
                                      : level_release_coeff);

        is_active = smoothed_level >= threshold;

        if (is_active)
        {
            hold_counter = hold_count;
        }
        else if (hold_counter > 0)
        {
            hold_counter--;
        }

        if (is_active || hold_counter > 0)
        {
            g += (range - g) * attack_coeff;
        }
        else
        {
            g += (1.0f - g) * decay_coeff;
        }

        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            out[channel][sample] = in[channel][sample] * g;
        }
    }

    current_gain = g;
}


void Ducker::update_hold()
{
    hold_count = hold_time * get_sample_rate() / 1000.0f;
}


void Ducker::update_attack()
{
    attack_coeff = 1.0f - expf(-1.0f / (attack_time / 1000.0f *
                               get_sample_rate()));
}


void Ducker::update_decay()
{
    decay_coeff = 1.0f - expf(-1.0f / (decay_time / 1000.0f *
                              get_sample_rate()));
    level_release_coeff = decay_coeff / 0.75f;
}

} // namespace
