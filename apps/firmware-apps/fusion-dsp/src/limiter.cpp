// A peak/RMS Limiter

#include <bosepro/algorithm.h>

#include <cstdint>
#include <vector>


namespace {


class Limiter : public bosepro::Algorithm
{
public:
    Limiter(const bosepro::BlockConfiguration &configuration);
    virtual ~Limiter() = default;

    virtual void process() override;

private:
    // constants and terminals
    int_fast32_t channels;
    int_fast32_t maxDelay;
    std::vector<const float *> in;
    std::vector<const float *> peakIn;
    std::vector<float *> out;
    // user controls
    float peakThresh;
    float peakAttack;
    float peakRelease;
    float rmsThresh;
    float rmsAttack;
    float rmsRelease;
    int_fast32_t delay;
    bool brickWall;                     // if instant attack
    // processing variables
    std::unique_ptr<float[]> buffer;    // for look-ahead delay
    float peakLevel;
    float peakGain;
    float rmsLevel;
    float rmsGain;
    float rmsCoeff;
    int_fast32_t readIndex; 
    int_fast32_t writeIndex;
    int_fast32_t bufferSize;
    // user control parameters processing functions
    void update_peakThresh();
    void update_peakAttack();
    void update_peakRelease();
    void update_rmsThresh();
    void update_rmsAttack();
    void update_rmsRelease();
    void update_delay();

    ALGORITHM_DECLARE(Limiter);
};

ALGORITHM_REGISTER(Limiter, "limiter");


Limiter::Limiter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);
    get_constant("maxDelay", maxDelay);

    assign_terminal("in", &in);
    assign_terminal("peakIn", &peakIn);
    assign_terminal("out", &out);

    assign_control("peakThresh", &peakThresh, POST_FUNCTION_SCALAR(update_peakThresh));
    assign_control("peakAttack", &peakAttack, POST_FUNCTION_SCALAR(update_peakAttack));
    assign_control("peakRelease", &peakRelease, POST_FUNCTION_SCALAR(update_peakRelease));
    assign_control("rmsThresh", &rmsThresh, POST_FUNCTION_SCALAR(update_rmsThresh));
    assign_control("rmsAttack", &rmsAttack, POST_FUNCTION_SCALAR(update_rmsAttack));
    assign_control("rmsRelease", &rmsRelease, POST_FUNCTION_SCALAR(update_rmsRelease));
    assign_control("delay", &delay, POST_FUNCTION_SCALAR(update_delay));
    assign_control("brickWall", &brickWall);

    bufferSize = (maxDelay + get_frame_size() - 1)/get_frame_size();
    bufferSize *= get_frame_size();
    writeIndex = 0;
    buffer = std::unique_ptr<float[]>(new float[channels * bufferSize]());
    peakLevel = 0.0f;
    peakGain = 0.0f;
    rmsLevel = 0.0f;
    rmsGain = 0.0f;
}


void Limiter::process()
{
    int_fast32_t readIndex = writeIndex - delay;
    if (readIndex < 0)
    {
        readIndex += bufferSize;
    }

    for (int_fast32_t i = 0; i < get_frame_size(); i++)
    {
        float peakEnergy;
        float rmsEnergy;

        // find the highest energy (amplitude^2) across channels
        peakEnergy = 0.0f;
        rmsEnergy = 0.0f;
        for (int_fast32_t j = 0; j < channels; j++)
        {
            float square;

            square = peakIn[j][i] * peakIn[j][i];
            peakEnergy = (square > peakEnergy) ? square : peakEnergy;
            square = in[j][i] * in[j][i];
            rmsEnergy = (square > rmsEnergy) ? square : rmsEnergy;

            buffer[j * bufferSize + writeIndex + i] = in[j][i];
        }

        // peakLevel is energy based (amplitude^2)
        // peakAdjust is amplitude based
        if (brickWall)
        {
            // instant attack, slower release
            peakLevel = (peakEnergy > peakLevel) ? peakEnergy : peakLevel + (peakEnergy - peakLevel) * peakRelease;
            // apply threshold
            float peakAdjust = peakThresh - 0.5f * log10f(peakLevel);  // 0.5 is a square-root to convert from energy to amplitude
            // limit gain range between 0 and -100 dB
            peakAdjust = (peakAdjust > 0.0f) ? 0.0f : ((peakAdjust < -5.0f) ? -5.0f : peakAdjust);
            peakGain = peakGain + (peakAdjust - peakGain) * peakAttack;
        }
        else
        {
            // fast attack, slower release
            peakLevel = peakLevel + (peakEnergy - peakLevel) * ((peakEnergy < peakLevel) ? peakRelease : peakAttack);
            // apply threshold
            float peakAdjust = peakThresh - 0.5f * log10f(peakLevel);  // - log10(peakLevel^1/2), 0.5 is a square-root to convert from energy to amplitude
            // limit gain range between 0 and -100 dB
            peakAdjust = (peakAdjust > 0.0f) ? 0.0f : ((peakAdjust < -5.0f) ? -5.0f : peakAdjust);
            peakGain = peakAdjust;
        }
        
        // RMS filter on squared signal (the M in RMS)
        rmsLevel = rmsLevel + (rmsEnergy - rmsLevel) * rmsCoeff;
        // apply threshold
        float rmsAdjust = rmsThresh - 0.5f * log10f(rmsLevel);
        // limit gain range between 0 and -100 dB
        rmsAdjust = (rmsAdjust > 0.0f) ? 0.0f : ((rmsAdjust < -5.0f) ? -5.0f : rmsAdjust);
        // apply attack and release filter
        rmsGain = rmsGain + (rmsAdjust - rmsGain) * ((rmsAdjust > rmsGain) ? rmsRelease : rmsAttack);

        // get the linear gain
        float g = powf(10.0f, (rmsGain < peakGain) ? rmsGain : peakGain);
        
        // apply gain
        for (int j = 0; j < channels; j++)
        {
            out[j][i] = g * buffer[j * bufferSize + readIndex];
        }

        readIndex++;
        if (readIndex >= bufferSize)
        {
            readIndex = 0;
        }
    }

    writeIndex += get_frame_size();
    if (writeIndex >= bufferSize)
    {
        writeIndex = 0;
    }
}

void Limiter::update_peakThresh()
{
    peakThresh = 0.05 * peakThresh;  // convert peak threshold from dB to log10
}

void Limiter::update_peakAttack()
{
    peakAttack = 1.0f - exp(-1.0/(get_sample_rate() * peakAttack));  // convert attack time constant to integrator coefficient
}

void Limiter::update_peakRelease()
{
    peakRelease = 1.0f - exp(-1.0/(get_sample_rate() * peakRelease));  // convert release time constant to integrator coefficient
}

void Limiter::update_rmsThresh()
{
    rmsThresh = 0.05 * rmsThresh;  // convert RMS threshold from dB to log10
}

void Limiter::update_rmsAttack()
{
    rmsAttack = 1.0f - exp(-1.0/(get_sample_rate() * rmsAttack));  // convert attack time constant to integrator coefficient
    rmsCoeff = 4.0f * ((rmsAttack > rmsRelease) ? rmsAttack : rmsRelease);  // RMS is 4 times faster than attack & release.
}

void Limiter::update_rmsRelease()
{
    rmsRelease = 1.0f - exp(-1.0/(get_sample_rate() * rmsRelease));  // convert release time constant to integrator coefficient
    rmsCoeff = 4.0f * ((rmsAttack > rmsRelease) ? rmsAttack : rmsRelease);  // RMS is 4 times faster than attack & release.
}

void Limiter::update_delay()
{
    delay = ((delay > 0.0) ? ((delay < maxDelay) ? delay : maxDelay) : 0); // limit delay to the proper range
}

} // namespace