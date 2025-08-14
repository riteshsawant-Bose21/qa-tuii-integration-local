
#include <bosepro/algorithm.h>

#include <cmath>


namespace {


class SignalGenerator : public bosepro::Algorithm {
public:
    SignalGenerator(const bosepro::BlockConfiguration &configuration);

    virtual ~SignalGenerator() = default;

    virtual void process() override;

private:
    bosepro::DspSignalMemory<float[]> out;

    std::string signal_type;
    float sine_frequency;
    std::string noise_type;
    std::string sweep_rate;
    bool sweep_run;

    static const int NOISE_LONG_LAG = 100;
    static const int NOISE_SHORT_LAG = 37;
    static const int NOISE_STATE_LENGTH = 128;
    static const int NOISE_STATE_MASK = NOISE_STATE_LENGTH - 1;
    static const int NOISE_SEP = 69;
    static const int_fast32_t NOISE_MODULUS = ((int_fast32_t)1 << 30);
    static const int_fast32_t NOISE_VALUE_MASK = NOISE_MODULUS - 1;
    static const float NOISE_SCALE;
    static const float PINK_SCALE;
    static const float SWEEP_START;
    static const float SWEEP_END;

    static int_fast32_t noise_seed;

    int noise_state_long;
    int noise_state_short;
    int noise_state_write;
    int_fast32_t noise_state[NOISE_STATE_LENGTH];

    float pink_state[3];

    float phase;
    float sine_phase_inc;
    float sweep_frequency_coeff;
    float sweep_current_frequency;
    bool sweep_running;

    inline int_fast32_t noise_mod_diff(int_fast32_t x, int_fast32_t y)
    {
        return (x - y) & NOISE_VALUE_MASK;
    }

    void initialize_noise();
    void process_noise();
    void process_sine();
    void process_sweep();
    void update_sine_frequency();
    void update_sweep_rate();

    ALGORITHM_DECLARE(SignalGenerator);
};

ALGORITHM_REGISTER(SignalGenerator, "signal_generator");


int_fast32_t SignalGenerator::noise_seed = INT32_C(310952);
const float SignalGenerator::NOISE_SCALE = 2.0f / NOISE_VALUE_MASK;
const float SignalGenerator::PINK_SCALE = 0.1995262;
const float SignalGenerator::SWEEP_START = 20.0f;
const float SignalGenerator::SWEEP_END = 20000.0f;


SignalGenerator::SignalGenerator(const bosepro::BlockConfiguration
                                 &configuration)
    : bosepro::Algorithm(configuration)
{
    assign_terminal("out", out);

    assign_parameter("signal_type", &signal_type);
    assign_parameter("sine_frequency", &sine_frequency,
                     POST_FUNCTION_SCALAR(update_sine_frequency));
    assign_parameter("noise_type", &noise_type);
    assign_parameter("sweep_rate", &sweep_rate,
                     POST_FUNCTION_SCALAR(update_sweep_rate));
    assign_parameter("sweep_run", &sweep_run);


    initialize_noise();

    pink_state[0] = 0.0f;
    pink_state[1] = 0.0f;
    pink_state[2] = 0.0f;

    phase = 0.0f;
}


void SignalGenerator::initialize_noise()
{
    int_fast32_t x[2 * NOISE_LONG_LAG - 1];
    int_fast32_t ss = (noise_seed + 2) & (NOISE_MODULUS - 2);

    noise_state_long = 0;
    noise_state_short = NOISE_LONG_LAG - NOISE_SHORT_LAG;
    noise_state_write = NOISE_LONG_LAG;

    for (int i = 0; i < NOISE_LONG_LAG; i++)
    {
        x[i] = ss;
        ss <<= 1;

        if (ss >= NOISE_MODULUS)
        {
            ss -= NOISE_MODULUS - 2;
        }
    }

    x[1]++;

    ss = noise_seed & NOISE_VALUE_MASK;
    int sep = NOISE_SEP;

    while (sep > 0)
    {
        for (int i = NOISE_LONG_LAG - 1; i > 0; i--)
        {
            x[2 * i] = x[i];
            x[2 * i - 1] = 0;
        }

        for (int i = 2 * NOISE_LONG_LAG - 2; i >= NOISE_LONG_LAG; i--)
        {
            x[i - NOISE_LONG_LAG + NOISE_SHORT_LAG] =
                noise_mod_diff(x[i - NOISE_LONG_LAG + NOISE_SHORT_LAG], x[i]);
            x[i - NOISE_LONG_LAG] = noise_mod_diff(x[i - NOISE_LONG_LAG], x[i]);
        }

        if ((ss & 1) != 0)
        {
            for (int i = NOISE_LONG_LAG; i > 0; i--)
            {
                x[i] = x[i - 1];
            }

            x[0] = x[NOISE_LONG_LAG];
            x[NOISE_SHORT_LAG] = noise_mod_diff(x[NOISE_SHORT_LAG],
                                                x[NOISE_LONG_LAG]);
        }

        if (ss > 0)
        {
            ss >>= 1;
        }
        else
        {
            sep--;
        }
    }

    for (int i = 0; i < NOISE_SHORT_LAG; i++)
    {
        noise_state[i + NOISE_LONG_LAG - NOISE_SHORT_LAG] = x[i];
    }

    for (int i = 0; i < NOISE_SHORT_LAG; i++)
    {
        noise_state[i] = x[i + NOISE_SHORT_LAG];
    }

    for (int i = 0; i < 10 * (2 * NOISE_LONG_LAG - 1); i++)
    {
        noise_state[noise_state_write++]
            = noise_mod_diff(noise_state[noise_state_long++],
                             noise_state[noise_state_short++]);

        noise_state_long &= NOISE_STATE_MASK;
        noise_state_short &= NOISE_STATE_MASK;
        noise_state_write &= NOISE_STATE_MASK;
    }

    noise_seed++;
}


void SignalGenerator::process_noise()
{
    for (int sample = 0; sample < get_frame_size(); sample++)
    {
        int_fast32_t x = noise_mod_diff(noise_state[noise_state_long++],
                                        noise_state[noise_state_short++]);

        noise_state[noise_state_write++] = x;

        noise_state_long &= NOISE_STATE_MASK;
        noise_state_short &= NOISE_STATE_MASK;
        noise_state_write &= NOISE_STATE_MASK;

        out[sample] = ((float)x * NOISE_SCALE - 1.0f);
    }

    if (noise_type == "pink")
    {
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            pink_state[0] = 0.9978038f * pink_state[0]
                + out[sample] * (0.0990460f * PINK_SCALE);
            pink_state[1] = 0.065953f * pink_state[1]
                + out[sample] * (0.2965164f * PINK_SCALE);
            pink_state[2] = 0.59452f * pink_state[2]
                + out[sample] * (1.0526913 * PINK_SCALE);
            out[sample] = pink_state[0] + pink_state[1] + pink_state[2]
                + out[sample] * (0.1848f * PINK_SCALE);
        }
    }
}


void SignalGenerator::process_sine()
{
    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        out[sample] = std::sin(phase);
        phase += sine_phase_inc;

        if (phase > 2.0f * 3.14159265f)
        {
            phase -= 2.0f * 3.14159265f;
        }
    }
}


void SignalGenerator::process_sweep()
{
    if (!sweep_running)
    {
        if (sweep_run)
        {
            sweep_running = true;
            sweep_current_frequency = SWEEP_START;
        }
        else
        {
            std::memset(out.get(), 0, sizeof(float) * get_frame_size());
            return;
        }
    }

    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        out[sample] = std::sin(phase);
        sweep_current_frequency
            += sweep_current_frequency * sweep_frequency_coeff;
        phase += sweep_current_frequency * 2.0f * 3.14159265f
            / get_sample_rate();

        if (phase > 2.0f * 3.14159265f)
        {
            phase -= 2.0f * 3.14159265f;
        }
    }

    if (sweep_current_frequency >= SWEEP_END)
    {
        sweep_current_frequency = SWEEP_START;

        if (!sweep_run)
        {
            sweep_running = false;
            phase = 0.0f;
        }
    }
}


void SignalGenerator::process()
{
    if (signal_type == "noise")
    {
        process_noise();
    }
    else if (signal_type == "sine")
    {
        process_sine();
    }
    else if (signal_type == "sweep")
    {
        process_sweep();
    }
}


void SignalGenerator::update_sine_frequency()
{
    sine_phase_inc = sine_frequency * 2.0f * 3.14159265f / get_sample_rate();
}


void SignalGenerator::update_sweep_rate()
{
    sweep_frequency_coeff = (sweep_rate == "fast") ? 0.00012f : 0.00003f;
}

} // namespace
