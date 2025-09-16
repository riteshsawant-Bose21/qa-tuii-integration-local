
#include "iir_design.h"
#include "iir.h"

#include <spdlog/spdlog.h>

#include <cmath>

namespace {


// Disable a filter section.
static void iir_design_disabled(filter::IirFilter *iir, int section, float,
                                float, float, float)
{
    iir->set_section_coeffs(section, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
}

IIR_DESIGN_BAND_REGISTER(disabled, iir_design_disabled);


// Design a peaking EQ using the ControlSpace (analog-style) formula.
static void iir_design_peq_cs(filter::IirFilter *iir, int section,
                              float frequency, float q, float gain_db,
                              float sample_rate)
{
    double k = std::pow(10.0, std::abs(gain_db) / 20.0);
    double tx = std::tan(frequency * M_PI / sample_rate);
    double a = tx * tx;
    double l = tx / q;

    double b0 = 1.0 + k * l + a;
    double b1 = 2.0 * a - 2.0;
    double b2 = 1.0 - k * l + a;
    double a0 = 1.0 + l + a;
    double a1 = 2.0 * a - 2.0;
    double a2 = 1.0 - l + a;

    if (gain_db > 0.0f)
    {
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
    else
    {
        iir->set_section_coeffs(section, a0, a1, a2, b0, b1, b2);
    }
}

IIR_DESIGN_BAND_REGISTER(peq_cs, iir_design_peq_cs);


// Design a peaking EQ using the RBJ cookbook formula.
static void iir_design_peq_rbj(filter::IirFilter *iir, int section,
                               float frequency, float q, float gain_db,
                               float sample_rate)
{
    double k = std::pow(10.0, gain_db / 40.0);
    double tx = std::tan(frequency * M_PI / sample_rate);
    double a = tx * tx;
    double l = tx / q;

    double b0 = 1.0 + k * l + a;
    double b1 = 2.0 * a - 2.0;
    double b2 = 1.0 - k * l + a;
    double a0 = 1.0 + l / k + a;
    double a1 = 2.0 * a - 2.0;
    double a2 = 1.0 - l / k + a;

    iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
}

IIR_DESIGN_BAND_REGISTER(peq_rbj, iir_design_peq_rbj);


// Design a high-shelf EQ using the ControlSpace formula.
static void iir_design_high_shelf_cs(filter::IirFilter *iir, int section,
                                     float frequency, float /* unused */,
                                     float gain_db, float sample_rate)
{
    double k = std::pow(10.0, std::abs(gain_db) / 20.0);
    double root_k = std::sqrt(k);
    double tx = std::tan(frequency * M_PI / sample_rate);
    double a = tx * tx;

    double b0 = k + a + 2.0 * root_k * tx;
    double b1 = 2.0 * (a - k);
    double b2 = k + a - 2.0 * root_k * tx;
    double a0 = 1.0 + a + 2.0 * tx;
    double a1 = 2.0 * (a - 1.0);
    double a2 = 1.0 + a - 2.0 * tx;

    if (gain_db > 0.0f)
    {
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
    else
    {
        iir->set_section_coeffs(section, a0, a1, a2, b0, b1, b2);
    }
}

IIR_DESIGN_BAND_REGISTER(high_shelf_cs, iir_design_high_shelf_cs);


// Design a low-shelf EQ using the ControlSpace formula.
static void iir_design_low_shelf_cs(filter::IirFilter *iir, int section,
                                    float frequency, float /* unused */,
                                    float gain_db, float sample_rate)
{
    double k = std::pow(10.0, std::abs(gain_db) / 20.0);
    double root_k = std::sqrt(k);
    double tx = std::tan(frequency * M_PI / sample_rate);
    double a = tx * tx;

    double b0 = 1.0 + k * a + 2.0 * root_k * tx;
    double b1 = 2.0 * (k * a - 1.0);
    double b2 = 1.0 + k * a - 2.0 * root_k * tx;
    double a0 = 1.0 + a + 2.0 * tx;
    double a1 = 2.0 * (a - 1.0);
    double a2 = 1.0 + a - 2.0 * tx;

    if (gain_db > 0.0f)
    {
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
    else
    {
        iir->set_section_coeffs(section, a0, a1, a2, b0, b1, b2);
    }
}

IIR_DESIGN_BAND_REGISTER(low_shelf_cs, iir_design_low_shelf_cs);

// Design a notch filter using the ControlSpace formula.
static void iir_design_notch_cs(filter::IirFilter *iir, int section,
                             float frequency, float q, float /* gain_db */,
                             float sample_rate)
{
    double r = 1.0f / (2.0f * q);
    double o = 2.0f * std::sin(frequency * M_PI / sample_rate);
    double oo = o * o;
    double ro = r * o;
    double tmp1 = 2.0f - oo;
    double tmp2 = 1.0f / (1.0f + ro);

    double b0 = tmp2;                    // B0'
    double b1 = -tmp1;                   // B1
    double b2 = 1.0f;                    // B2
    double a0 = 1.0f;                    // Normalized 
    double a1 = tmp1 * tmp2;             // A1
    double a2 = (ro - 1.0f) * tmp2;      // A2

    iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
}
IIR_DESIGN_BAND_REGISTER(notch_cs, iir_design_notch_cs);

// Design a low-pass filter using the ControlSpace formula.
static void iir_design_lpf_cs(filter::IirFilter *iir, int section,
                           float frequency, float q, float /* gain_db */,
                           float sample_rate)
{
    double tx = std::tan(frequency * M_PI / sample_rate);

    if (q > 0.1f) { // 2nd order case: -12dB/oct
        double q = 0.707107f; 
        double l = tx / q;
        double a = tx * tx;
        double tmp1 = 1.0f + a;
        double tmp2 = 1.0f / (tmp1 + l);

        double b0 = a * tmp2;                      // B0'
        double b1 = 2.0f;                            // B1
        double b2 = 1.0f;                            // B2
        double a0 = 1.0f;                            // Normalized
        double a1 = 2.0f * (1.0f - a) * tmp2;     // A1
        double a2 = (l - tmp1) * tmp2;             // A2

        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
    else { // 1st order case: 6dB/octave
        double tmp = 1.0f / (1.0f + tx);

        double b0 = tx * tmp;        // B0'
        double b1 = 1.0f;            // B1
        double b2 = 0.0f;            // B2
        double a0 = 1.0f;            // Normalized
        double a1 = (1.0f - tx) * tmp; // A1
        double a2 = 0.0f;            // A2
        
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
}
    IIR_DESIGN_BAND_REGISTER(lpf_cs, iir_design_lpf_cs);

// Design a high-pass filter using the ControlSpace formula.
static void iir_design_hpf_cs(filter::IirFilter *iir, int section,
                           float frequency, float q, float /* gain_db */,
                           float sample_rate)
{
    double tx = std::tan(frequency * M_PI / sample_rate);
    
    if (q > 0.1f) {// 2nd order case: -12dB/oct
        double q = 0.707107f;
        double l = tx / q;
        double a = tx * tx;
        double tmp1 = 1.0f + a;
        double tmp2 = 1.0f / (tmp1 + l);
        
        double b0 = tmp2;                            // B0'
        double b1 = -2.0f;                           // B1
        double b2 = 1.0f;                            // B2
        double a0 = 1.0f;                            // Normalized
        double a1 = 2.0f * (1.0f - a) * tmp2;     // A1
        double a2 = (l - tmp1) * tmp2;             // A2

        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
    else { // 1st order case: 6dB/octave
        double tmp = 1.0f / (1.0f + tx);

        double b0 = tmp;             // B0'
        double b1 = -1.0f;           // B1
        double b2 = 0.0f;            // B2
        double a0 = 1.0f;            // Normalized
        double a1 = (1.0f - tx) * tmp; // A1
        double a2 = 0.0f;            // A2
        
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    }
}
    IIR_DESIGN_BAND_REGISTER(hpf_cs, iir_design_hpf_cs);

} // namespace
