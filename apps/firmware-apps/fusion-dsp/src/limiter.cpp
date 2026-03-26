// A peak/RMS Limiter

#include <bosepro/algorithm.h>
#include <bosepro/conversion.h>

#include <cstdint>


namespace {


class Limiter : public bosepro::Algorithm
{
public:
    Limiter(const bosepro::BlockConfiguration &configuration);
    virtual ~Limiter() = default;

    virtual void process() override;

private:
    // --- properties and terminals ---
    int_fast32_t channels;
    int_fast32_t max_delay;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<const float *[]> peak_in;
    bosepro::DspSignalMemory<float *[]> out;
    // --- user parameters ---
    float peak_threshold_db;
    float peak_attack_time;
    float peak_release_time;
    float rms_threshold_db;
    float rms_attack_time;
    float rms_release_time;
    float peak_threshold;
    float peak_attack_coeff;
    float peak_release_coeff;
    float rms_threshold;
    float rms_attack_coeff;
    float rms_release_coeff;
    int_fast32_t delay;
    // if instant attack
    bool brick_wall;                     
    // --- processing variables ---
    // for look-ahead delay
    bosepro::DspStateMemory<float[]> buffer;
    float peak_level;
    float peak_gain;
    float peak_gain_telemetry;
    float total_gain;
    float rms_level;
    float rms_gain;
    float rms_gain_telemetry;
    float rms_coeff;
    int_fast32_t write_index;
    int_fast32_t buffer_size;
    // --- user parameter processing functions ---
    void update_peak_threshold();
    void update_peak_attack();
    void update_peak_release();
    void update_rms_threshold();
    void update_rms_attack();
    void update_rms_release();

    ALGORITHM_DECLARE(Limiter);
};

ALGORITHM_REGISTER(Limiter, "limiter");


Limiter::Limiter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration), peak_level(0.0f), peak_gain(0.0f),
      rms_level(0.0f), rms_gain(0.0f), write_index(0)
{
    get_property("channels", channels);
    get_property("max_delay", max_delay);

    assign_terminal("in", in);
    assign_terminal("peak_in", peak_in);
    assign_terminal("out", out);

    assign_parameter("peak_threshold", &peak_threshold_db,
                     POST_FUNCTION_SCALAR(update_peak_threshold));
    assign_parameter("peak_attack", &peak_attack_time,
                     POST_FUNCTION_SCALAR(update_peak_attack));
    assign_parameter("peak_release", &peak_release_time,
                     POST_FUNCTION_SCALAR(update_peak_release));
    assign_parameter("rms_threshold", &rms_threshold_db,
                     POST_FUNCTION_SCALAR(update_rms_threshold));
    assign_parameter("rms_attack", &rms_attack_time,
                     POST_FUNCTION_SCALAR(update_rms_attack));
    assign_parameter("rms_release", &rms_release_time,
                     POST_FUNCTION_SCALAR(update_rms_release));
    assign_parameter("delay", &delay);
    assign_parameter("brick_wall", &brick_wall);

    assign_telemetry("peak_gain", &peak_gain_telemetry);
    assign_telemetry("rms_gain", &rms_gain_telemetry);
    assign_telemetry("total_gain", &total_gain, bosepro::linear_to_db);

    buffer_size = (max_delay + get_frame_size() - 1)/get_frame_size();
    buffer_size *= get_frame_size();
    buffer.resize(channels * buffer_size);
    memset(buffer.get(), 0, channels * buffer_size * sizeof(float));
}


void Limiter::process()
{
    int_fast32_t read_index = write_index - delay;
    if (read_index < 0)
    {
        read_index += buffer_size;
    }

    for (int_fast32_t i = 0; i < get_frame_size(); i++)
    {
        float peak_energy;
        float rms_energy;

        // find the highest energy (amplitude^2) across channels
        peak_energy = 0.0f;
        rms_energy = 0.0f;
        for (int_fast32_t j = 0; j < channels; j++)
        {
            float square;

            square = peak_in[j][i] * peak_in[j][i];
            peak_energy = (square > peak_energy) ? square : peak_energy;
            square = in[j][i] * in[j][i];
            rms_energy = (square > rms_energy) ? square : rms_energy;

            buffer[j * buffer_size + write_index + i] = in[j][i];
        }

        // peak_level is energy based (amplitude^2)
        // peak_adjust is amplitude based
        if (brick_wall)
        {
            // instant attack, slower release
            peak_level = (peak_energy > peak_level) ? peak_energy
                : peak_level + (peak_energy - peak_level) * peak_release_coeff;
            // apply threshold
            // - log10(peak_level^1/2), 0.5 is a square-root to convert 
            // from energy to amplitude
            float peak_adjust = peak_threshold - 0.5f * log10f(peak_level);
            // limit gain range between 0 and -100 dB
            peak_adjust = (peak_adjust > 0.0f) ?
                0.0f : ((peak_adjust < -5.0f) ? -5.0f : peak_adjust);
            peak_gain = peak_gain
                + (peak_adjust - peak_gain) * peak_attack_coeff;
        }
        else
        {
            // fast attack, slower release
            peak_level = peak_level + (peak_energy - peak_level) *
                ((peak_energy < peak_level) ? peak_release_coeff
                 : peak_attack_coeff);
            // apply threshold
            // - log10(peak_level^1/2), 0.5 is a square-root to convert 
            // from energy to amplitude
            float peak_adjust = peak_threshold - 0.5f * log10f(peak_level);
            // limit gain range between 0 and -100 dB
            peak_adjust = (peak_adjust > 0.0f) ? 
                0.0f : ((peak_adjust < -5.0f) ? -5.0f : peak_adjust);
            peak_gain = peak_adjust;
        }

        // RMS filter on squared signal (the M in RMS)
        rms_level = rms_level + (rms_energy - rms_level) * rms_coeff;
        // apply threshold
        float rms_adjust = rms_threshold - 0.5f * log10f(rms_level);
        // limit gain range between 0 and -100 dB
        rms_adjust = (rms_adjust > 0.0f) ? 
            0.0f : ((rms_adjust < -5.0f) ? -5.0f : rms_adjust);
        // apply attack and release filter
        rms_gain = rms_gain + (rms_adjust - rms_gain)
            * ((rms_adjust > rms_gain) ? rms_release_coeff : rms_attack_coeff);

        // get the linear gain
        float g = powf(10.0f, (rms_gain < peak_gain) ? rms_gain : peak_gain);
        peak_gain_telemetry = peak_gain * 20.0f;
        rms_gain_telemetry = rms_gain * 20.0f;
        total_gain = g;

        // apply gain
        for (int j = 0; j < channels; j++)
        {
            out[j][i] = g * buffer[j * buffer_size + read_index];
        }

        read_index++;
        if (read_index >= buffer_size)
        {
            read_index = 0;
        }
    }

    write_index += get_frame_size();
    if (write_index >= buffer_size)
    {
        write_index = 0;
    }
}

// convert peak threshold from dB to log10
void Limiter::update_peak_threshold()
{
    peak_threshold = 0.05 * peak_threshold_db;
}

// convert attack time constant to integrator coefficient
void Limiter::update_peak_attack()
{
    peak_attack_coeff = 1.0f
        - exp(-1.0/(get_sample_rate() * peak_attack_time * 0.001f));
}

// convert release time constant to integrator coefficient
void Limiter::update_peak_release()
{
    peak_release_coeff = 1.0f
        - exp(-1.0/(get_sample_rate() * peak_release_time * 0.001f));
}

// convert RMS threshold from dB to log10
void Limiter::update_rms_threshold()
{
    rms_threshold = 0.05 * rms_threshold_db;
}

// convert attack time constant to integrator coefficient
void Limiter::update_rms_attack()
{
    rms_attack_coeff = 1.0f
        - exp(-1.0/(get_sample_rate() * rms_attack_time * 0.001f));
    // RMS is 4 times faster than attack & release.
    rms_coeff = 4.0f * ((rms_attack_coeff > rms_release_coeff)
                        ? rms_attack_coeff : rms_release_coeff);
}

// convert release time constant to integrator coefficient
void Limiter::update_rms_release()
{
    rms_release_coeff = 1.0f
        - exp(-1.0/(get_sample_rate() * rms_release_time * 0.001f));
    // RMS is 4 times faster than attack & release.
    rms_coeff = 4.0f * ((rms_attack_coeff > rms_release_coeff)
                        ? rms_attack_coeff : rms_release_coeff);
}

} // namespace
