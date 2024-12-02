
#include <bosepro/algorithm.h>

#include <cmath>
#include <cstdint>


namespace {


class Agc : public bosepro::Algorithm
{
public:
    Agc(const bosepro::BlockConfiguration &configuration);
    virtual ~Agc() = default;

    virtual void process() override;

private:
    int_fast32_t channels;

    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;

    bosepro::DspCoeffMemory<float[]> activity_threshold;
    bosepro::DspCoeffMemory<float[]> target_minimum;
    bosepro::DspCoeffMemory<float[]> target_maximum;
    bosepro::DspParamMemory<float[]> cut_rate;
    bosepro::DspParamMemory<float[]> boost_rate;
    bosepro::DspCoeffMemory<float[]> cut_range;
    bosepro::DspCoeffMemory<float[]> boost_range;
    bosepro::DspParamMemory<float[]> cut_hold_time;
    bosepro::DspParamMemory<float[]> boost_hold_time;
    bosepro::DspCoeffMemory<bool[]> channel_bypass;
    float max_total_boost;

    bosepro::DspMeterMemory<float[]> current_gain;
    bosepro::DspMeterMemory<bool[]> hold_meter;
    float current_total_boost;

    bosepro::DspStateMemory<float[]> smoothed_level;
    bosepro::DspStateMemory<float[]> fast_level;
    bosepro::DspStateMemory<float[]> cut_step;
    bosepro::DspStateMemory<float[]> boost_step;
    bosepro::DspStateMemory<float[]> target_gain;
    bosepro::DspStateMemory<int_fast32_t[]> cut_hold_count;
    bosepro::DspStateMemory<int_fast32_t[]> boost_hold_count;
    bosepro::DspStateMemory<int_fast32_t[]> hold_counter;

    float level_attack_coeff;
    float level_release_coeff;
    float fast_release_coeff;

    void update_cut_rate(int row);
    void update_boost_rate(int row);
    void update_cut_hold(int row);
    void update_boost_hold(int row);

    ALGORITHM_DECLARE(Agc);
};

ALGORITHM_REGISTER(Agc, "agc");


Agc::Agc(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("activity_threshold", activity_threshold);
    assign_parameter("target_minimum", target_minimum);
    assign_parameter("target_maximum", target_maximum);
    assign_parameter("cut_rate", cut_rate,
                     POST_FUNCTION_VECTOR(update_cut_rate));
    assign_parameter("boost_rate", boost_rate,
                     POST_FUNCTION_VECTOR(update_boost_rate));
    assign_parameter("cut_range", cut_range);
    assign_parameter("boost_range", boost_range);
    assign_parameter("cut_hold", cut_hold_time,
                     POST_FUNCTION_VECTOR(update_cut_hold));
    assign_parameter("boost_hold", boost_hold_time,
                     POST_FUNCTION_VECTOR(update_boost_hold));
    assign_parameter("channel_bypass", channel_bypass);
    assign_parameter("max_total_boost", &max_total_boost);

    assign_meter("gain_meter", current_gain);
    assign_meter("hold_meter", hold_meter);

    smoothed_level.resize(channels);
    fast_level.resize(channels);
    cut_step.resize(channels);
    boost_step.resize(channels);
    target_gain.resize(channels);
    cut_hold_count.resize(channels);
    boost_hold_count.resize(channels);
    hold_counter.resize(channels);

    level_attack_coeff = 1.0f - exp(-1.0f / (get_sample_rate() * 0.0005f));
    level_release_coeff = 1.0f - exp(-1.0f / (get_sample_rate() * 0.1f));
    fast_release_coeff = 1.0f - exp(-1.0f / (get_sample_rate() * 0.005f));
}


void Agc::process()
{
    float total_boost = 0.0f;

    for (int_fast32_t channel = 0; channel < channels; channel++)
    {
        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            float energy = in[channel][sample] * in[channel][sample];
            smoothed_level[channel] += (energy - smoothed_level[channel]) *
                ((energy > smoothed_level[channel])
                 ? level_attack_coeff : level_release_coeff);
            fast_level[channel] += (energy - fast_level[channel]) *
                ((energy > fast_level[channel])
                 ? level_attack_coeff : fast_release_coeff);
        }

        float log_level = 10.0f * log10(smoothed_level[channel]) + 20.0f;
        float log_fast_level = 10.0f * log10(fast_level[channel]) + 20.0f;

        if ((log_fast_level > activity_threshold[channel]) 
            || (hold_counter[channel] <= 0))
        {
            if (log_level > target_maximum[channel])
            {
                target_gain[channel] =
                    std::max(target_maximum[channel] - log_level,
                             -cut_range[channel]);
                hold_counter[channel] = cut_hold_count[channel];
            }
            else if (log_level < target_minimum[channel])
            {
                target_gain[channel] =
                    std::min(target_minimum[channel] - log_level,
                             boost_range[channel]);
                hold_counter[channel] = boost_hold_count[channel];
            }
            else
            {
                target_gain[channel] = 0.0f;
                hold_counter[channel] = 0;
            }

            hold_meter[channel] = false;
        }
        else
        {
            hold_counter[channel]--;
            hold_meter[channel] = true;
        }

        if ((target_gain[channel] > 0.0f) && !channel_bypass[channel])
        {
            total_boost += target_gain[channel];
        }
    }

    float boost_limit_adjustment = 1.0f;

    if (total_boost > max_total_boost)
    {
        boost_limit_adjustment = max_total_boost / total_boost;
    }

    current_total_boost = std::min(total_boost, max_total_boost);

    for (int_fast32_t channel = 0; channel < channels; channel++)
    {
        float target = target_gain[channel];

        if (target > 0.0f)
        {
            target *= boost_limit_adjustment;
        }

        if (channel_bypass[channel])
        {
            target = 0.0f;
        }

        float g = current_gain[channel];
        float g_step = (target > 0.0f) ? boost_step[channel] : cut_step[channel];

        if (target < g)
        {
            g_step *= -1.0f;
        }

        if (std::abs(target - g) < (g_step / get_frame_size()))
        {
            g = target;
            g_step = 0.0f;
        }

        g = powf(10.0f, g / 20.0f);
        g_step = powf(10.0f, g_step / 20.0f);

        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            out[channel][sample] = in[channel][sample] * g;
            g *= g_step;
        }

        current_gain[channel] = 20.0f * log10f(g);
    }

}


void Agc::update_cut_rate(int row)
{
    cut_step[row] = cut_rate[row] * get_frame_size() / get_sample_rate();
}


void Agc::update_boost_rate(int row)
{
    boost_step[row] = boost_rate[row] * get_frame_size() / get_sample_rate();
}


void Agc::update_cut_hold(int row)
{
    cut_hold_count[row] = cut_hold_time[row] * get_sample_rate() /
        get_frame_size();
}


void Agc::update_boost_hold(int row)
{
    boost_hold_count[row] = boost_hold_time[row] * get_sample_rate() /
        get_frame_size();
}

} // namespace
