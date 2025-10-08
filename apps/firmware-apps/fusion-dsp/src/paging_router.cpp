
#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>

#include <cmath>
#include <cstdint>


namespace {


class PagingRouter : public bosepro::Algorithm
{
public:
    PagingRouter(const bosepro::BlockConfiguration &configuration);
    virtual ~PagingRouter() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    int paging_channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspSignalMemory<const float *[]> paging_in;
    float threshold;
    float range;
    float attack_time;
    float attack_coeff;
    float decay_time;
    float decay_coeff;
    float hold_time;
    int_fast32_t hold_count;
    float level_attack_coeff;
    float level_release_coeff;

    bosepro::DspStateMemory<float []> smoothed_level;
    bosepro::DspStateMemory<int_fast32_t []> hold_counter;
    bosepro::DspStateMemory<float []> current_gain;
    int_fast32_t active_input;

    void update_hold();
    void update_attack();
    void update_decay();

    ALGORITHM_DECLARE(PagingRouter);
};

ALGORITHM_REGISTER(PagingRouter, "paging_router");


PagingRouter::PagingRouter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);
    get_terminal_num_channels("paging_in", paging_channels);

    assign_terminal("in", in);
    assign_terminal("out", out);
    assign_terminal("paging_in", paging_in);

    assign_parameter("threshold", &threshold, bosepro::db_to_linear);
    assign_parameter("range", &range, bosepro::db_to_linear);
    assign_parameter("attack", &attack_time,
                     POST_FUNCTION_SCALAR(update_attack));
    assign_parameter("hold", &hold_time,
                     POST_FUNCTION_SCALAR(update_hold));
    assign_parameter("decay", &decay_time,
                     POST_FUNCTION_SCALAR(update_decay));

    assign_telemetry("active_input", &active_input);

    smoothed_level.resize(paging_channels);
    hold_counter.resize(paging_channels);
    current_gain.resize(paging_channels);

    for (int p_ch = 0; p_ch < paging_channels; p_ch++)
    {
        current_gain[p_ch] = 1.0f;
    }

    level_attack_coeff = 0.341f;
}


void PagingRouter::process()
{

    active_input = 0;

    for (int p_ch = 0; p_ch < paging_channels; p_ch++)
    {
        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            float level = std::fabs(paging_in[p_ch][sample]);

            smoothed_level[p_ch] += (level - smoothed_level[p_ch]) *
                ((level > smoothed_level[p_ch]) ? level_attack_coeff
                 : level_release_coeff);

            if (smoothed_level[p_ch] >= threshold)
            {
                hold_counter[p_ch] = hold_count;
                active_input = p_ch + 1;
            }
            else if (hold_counter[p_ch] > 0)
            {
                hold_counter[p_ch]--;
                active_input = p_ch + 1;
            }
        }
    }

    float g = current_gain[0];

    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        if (active_input > 0)
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

    current_gain[0] = g;

    for (int p_ch = 0; p_ch < paging_channels - 1; p_ch++)
    {
        g = current_gain[p_ch + 1];

        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            if (active_input > p_ch + 1)
            {
                g += (range - g) * attack_coeff;
            }
            else
            {
                g += (1.0f - g) * decay_coeff;
            }

            float x = paging_in[p_ch][sample] * g;

            for (int_fast32_t channel = 0; channel < channels; channel++)
            {
                out[channel][sample] += x;
            }
        }

        current_gain[p_ch + 1] = g;
    }

    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            out[channel][sample] += paging_in[paging_channels - 1][sample];
        }
    }
}


void PagingRouter::update_hold()
{
    hold_count = hold_time * get_sample_rate() / 1000.0f;
}


void PagingRouter::update_attack()
{
    attack_coeff = 1.0f - expf(-1.0f / (attack_time / 1000.0f *
                               get_sample_rate()));
}


void PagingRouter::update_decay()
{
    decay_coeff = 1.0f - expf(-1.0f / (decay_time / 1000.0f *
                              get_sample_rate()));
    level_release_coeff = decay_coeff / 0.75f;
}

} // namespace
