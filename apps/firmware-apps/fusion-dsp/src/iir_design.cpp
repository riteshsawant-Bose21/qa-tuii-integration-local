
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

} // namespace
