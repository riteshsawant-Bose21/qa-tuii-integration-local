
#include "iir.h"

#include <bosepro/algorithm.h>

#include <cmath>
#include <cstdint>
#include <memory>
#include <vector>

namespace {


class Peq : public bosepro::Algorithm
{
public:
    Peq(const bosepro::BlockConfiguration &configuration);
    virtual ~Peq() = default;

    virtual void process() override;


private:
    int_fast32_t channels;
    int_fast32_t bands;
    std::vector<const float *> in;
    std::vector<float *> out;

    bool bypass;
    std::vector<bool> band_enable;
    std::vector<float> gain;
    std::vector<float> frequency;
    std::vector<float> bandwidth;
    int state_size;
    std::unique_ptr<float[]> coeff;  // May need to be aligned
    std::unique_ptr<float[]> state;  // May need to be aligned
    std::vector<float> b0;
    float total_gain;

    void update_band(int band);

    ALGORITHM_DECLARE(Peq);
};

ALGORITHM_REGISTER(Peq, "peq");


Peq::Peq(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);
    get_constant("bands", bands);

    assign_terminal("in", &in);
    assign_terminal("out", &out);

    assign_control("bypass", &bypass);
    assign_control("band_enable", &band_enable,
                   POST_FUNCTION_VECTOR(update_band));
    assign_control("gain", &gain, POST_FUNCTION_VECTOR(update_band));
    assign_control("frequency", &frequency, POST_FUNCTION_VECTOR(update_band));
    assign_control("bandwidth", &bandwidth, POST_FUNCTION_VECTOR(update_band));

    state_size = filter::iir_state_size(bands);

    state = std::unique_ptr<float[]>(new (std::align_val_t(filter::IIR_ALIGN)) float[channels * state_size]());
    coeff = std::unique_ptr<float[]>(new (std::align_val_t(filter::IIR_ALIGN)) float[4 * bands]());
    b0.resize(bands);
}


void Peq::process()
{
    if (bypass)
    {
        for (int_fast32_t channel = 0; channel < channels; channel++)
        {
            for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
            {
                out[channel][sample] = in[channel][sample];
            }
        }

        return;
    }

    for (int channel = 0; channel < channels; channel++)
    {
        filter::iir_process(out[channel], in[channel],
                            &state[channel * state_size], total_gain,
                            coeff.get(), bands, get_frame_size());
    }
}


void Peq::update_band(int band)
{
    int band_start = filter::coeff_index_start(band, bands);
    int band_stride = filter::coeff_index_stride(band, bands);

    if (band_enable[band])
    {
        double q = pow(2.0, bandwidth[band]);
        q = sqrt(q) / (q - 1.0);
        double k = pow(10.0, gain[band] / 20.0);
        double tx = tan(frequency[band] * M_PI / get_sample_rate());
        double a = tx * tx;
        double l = tx / q;


        if (gain[band] < 0.0)
        {
            double den = 1.0 + k * l + a;
            coeff[band_start + filter::A1_INDEX * band_stride] =
                (2.0 * a - 2.0) / den;
            coeff[band_start + filter::A2_INDEX * band_stride] =
                (1.0 - k * l + a) / den;
            coeff[band_start + filter::B1_INDEX * band_stride] =
                (2.0 * a - 2.0) / den;
            coeff[band_start + filter::B2_INDEX * band_stride] =
                (1.0 - l + a) / den;
            b0[band] = (1.0 + l + a) / den;
        }
        else
        {
            double den = 1.0 + l + a;
            coeff[band_start + filter::A1_INDEX * band_stride] =
                (2.0 * a - 2.0) / den;
            coeff[band_start + filter::A2_INDEX * band_stride] =
                (1.0 - l + a) / den;
            coeff[band_start + filter::B1_INDEX * band_stride] =
                (2.0 * a - 2.0) / den;
            coeff[band_start + filter::B2_INDEX * band_stride] =
                (1.0 - k * l + a) / den;
            b0[band] = (1.0 + k * l + a) / den;
        }
    }
    else
    {
        coeff[band_start + filter::A1_INDEX * band_stride] = 0.0;
        coeff[band_start + filter::A2_INDEX * band_stride] = 0.0;
        coeff[band_start + filter::B1_INDEX * band_stride] = 0.0;
        coeff[band_start + filter::B2_INDEX * band_stride] = 0.0;
        b0[band] = 1.0;
    }

    double g = 1.0;

    for (int i = 0; i < bands; i++)
    {
        g *= b0[i];
    }

    total_gain = g;
}


} // namespace
