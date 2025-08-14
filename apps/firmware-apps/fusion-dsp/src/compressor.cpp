
#include <bosepro/algorithm.h>

#include <spdlog/spdlog.h>

#include <cmath>
#include <cstdint>


namespace {


class Compressor : public bosepro::Algorithm
{
public:
    Compressor(const bosepro::BlockConfiguration &configuration);
    virtual ~Compressor() = default;

    virtual void process() override;

private:
    int_fast32_t channels;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspSignalMemory<const float *[]> sidechain_in;
    bool sidechain_enabled;
    float threshold;
    float ratio;
    float ratio_scale;
    float attack_time;
    float attack_coeff;
    float release_time;
    float release_coeff;
    float level_attack_coeff;
    float level_release_coeff;
    float current_gain;
    float smoothed_level;

    void update_ratio();
    void update_attack();
    void update_release();

    ALGORITHM_DECLARE(Compressor);
};

ALGORITHM_REGISTER(Compressor, "compressor");


Compressor::Compressor(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);

    assign_terminal("in", in);
    assign_terminal("out", out);
    assign_terminal("sidechain_in", sidechain_in);

    assign_parameter("sidechain_enable", &sidechain_enabled);
    assign_parameter("threshold", &threshold);
    assign_parameter("ratio", &ratio,
                     POST_FUNCTION_SCALAR(update_ratio));
    assign_parameter("attack", &attack_time,
                     POST_FUNCTION_SCALAR(update_attack));
    assign_parameter("release", &release_time,
                     POST_FUNCTION_SCALAR(update_release));

    assign_telemetry("gain_meter", &current_gain, bosepro::linear_to_db);

    level_attack_coeff = 0.41666667f;
    current_gain = 1.0f;
}


void Compressor::process()
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

        float attenuation = threshold * 0.05f - log10f(level);
        attenuation = std::min(attenuation, 0.0f);
        attenuation *= ratio_scale;
        attenuation = powf(10.0f, attenuation);

        if (attenuation < g)
        {
            g += (attenuation - g) * attack_coeff;
        }
        else
        {
            g += (1.0 - g) * release_coeff;
        }


        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            out[channel][sample] = in[channel][sample] * g;
        }
    }

    current_gain = g;
}


void Compressor::update_ratio()
{
    ratio_scale = 1.0f - 1.0f / ratio;
}


void Compressor::update_attack()
{
    attack_coeff = 1.0f - expf(-1.0f / (attack_time / 1000.0f *
                               get_sample_rate()));
}


void Compressor::update_release()
{
    release_coeff = 1.0f - expf(-1.0f / (release_time / 1000.0f *
                                get_sample_rate()));
    level_release_coeff = release_coeff / 0.75f;
}

} // namespace
