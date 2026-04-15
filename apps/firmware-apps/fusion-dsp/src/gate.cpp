
#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>

#include <cmath>
#include <cstdint>


namespace {


class Gate : public bosepro::Algorithm
{
public:
    Gate(const bosepro::BlockConfiguration &configuration);
    virtual ~Gate() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspSignalMemory<const float *[]> sidechain_in;
    bool sidechain_enabled;
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
    bool is_open;
    float smoothed_level;

    void update_hold();
    void update_attack();
    void update_decay();

    ALGORITHM_DECLARE(Gate);
};

ALGORITHM_REGISTER(Gate, "gate");


Gate::Gate(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);
    assign_terminal("sidechain_in", sidechain_in);

    assign_parameter("sidechain_enable", &sidechain_enabled);
    assign_parameter("threshold", &threshold, bosepro::db_to_linear);
    assign_parameter("range", &range, bosepro::db_to_linear);
    assign_parameter("attack", &attack_time,
                     POST_FUNCTION_SCALAR(update_attack));
    assign_parameter("hold", &hold_time,
                     POST_FUNCTION_SCALAR(update_hold));
    assign_parameter("decay", &decay_time,
                     POST_FUNCTION_SCALAR(update_decay));

    assign_telemetry("open", &is_open);

    level_attack_coeff = 0.341f;
    current_gain = 1.0f;
}


void Gate::process()
{
    float g = current_gain;

    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        float level = 0.0f;

        if (!sidechain_enabled)
        {
            for (int_fast32_t channel = 0; channel < channels; channel++)
            {
                level = std::max(level, std::fabs(in[channel][sample]));
            }
        }
        else
        {
            level = std::fabs(sidechain_in[0][sample]);
        }

        smoothed_level += (level - smoothed_level) *
            ((level > smoothed_level) ? level_attack_coeff
                                      : level_release_coeff);

        if (smoothed_level >= threshold)
        {
            hold_counter = hold_count;
        }
        else if (hold_counter > 0)
        {
            hold_counter--;
        }

        if (hold_counter > 0)
        {
            g += (1.0 - g) * attack_coeff;
        }
        else
        {
            g += (range - g) * decay_coeff;
        }

        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            out[channel][sample] = in[channel][sample] * g;
        }
    }

    is_open = hold_counter > 0;

    current_gain = g;
}


void Gate::update_hold()
{
    hold_count = hold_time * get_sample_rate() / 1000.0f;
}


void Gate::update_attack()
{
    attack_coeff = 1.0f - expf(-1.0f / (attack_time / 1000.0f *
                               get_sample_rate()));
}


void Gate::update_decay()
{
    decay_coeff = 1.0f - expf(-1.0f / (decay_time / 1000.0f *
                              get_sample_rate()));
    level_release_coeff = decay_coeff / 0.75f;
}

} // namespace
