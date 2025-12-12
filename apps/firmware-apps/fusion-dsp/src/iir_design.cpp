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
    SPDLOG_DEBUG("IIR_COEFF [Disabled] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                 section, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
}

IIR_DESIGN_BAND_REGISTER(disabled, iir_design_disabled);


// Design a peaking EQ using the ControlSpace (analog-style) formula.
static void iir_design_peq_cs(filter::IirFilter *iir, int section,
                              float frequency, float q, float gain_db,
                              float sample_rate)
{
    double k = std::pow(10.0, std::abs(gain_db) / 20.0);
    double tx = std::tan(frequency * M_PI / sample_rate);
    double tx2 = tx * tx;
    double txq = tx / q;

    double b0 = 1.0 + k * txq + tx2;
    double b1 = 2.0 * tx2 - 2.0;
    double b2 = 1.0 - k * txq + tx2;
    double a0 = 1.0 + txq + tx2;
    double a1 = 2.0 * tx2 - 2.0;
    double a2 = 1.0 - txq + tx2;

    if (gain_db > 0.0)
    {
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [PEQ_CS_{}Hz_Q{:.2f}_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, q, gain_db, section, b0, b1, b2, a0, a1, a2);
    }
    else
    {
        iir->set_section_coeffs(section, a0, a1, a2, b0, b1, b2);
        SPDLOG_DEBUG("IIR_COEFF [PEQ_CS_{}Hz_Q{:.2f}_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, q, gain_db, section, a0, a1, a2, b0, b1, b2);
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
    double tx2 = tx * tx;
    double txq = tx / q;

    double b0 = 1.0 + k * txq + tx2;
    double b1 = 2.0 * tx2 - 2.0;
    double b2 = 1.0 - k * txq + tx2;
    double a0 = 1.0 + txq / k + tx2;
    double a1 = 2.0 * tx2 - 2.0;
    double a2 = 1.0 - txq / k + tx2;

    iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    SPDLOG_DEBUG("IIR_COEFF [PEQ_RBJ_{}Hz_Q{:.2f}_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                 (int)frequency, q, gain_db, section, b0, b1, b2, a0, a1, a2);
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
    double tx2 = tx * tx;

    double b0 = k + tx2 + 2.0 * root_k * tx;
    double b1 = 2.0 * (tx2 - k);
    double b2 = k + tx2 - 2.0 * root_k * tx;
    double a0 = 1.0 + tx2 + 2.0 * tx;
    double a1 = 2.0 * (tx2 - 1.0);
    double a2 = 1.0 + tx2 - 2.0 * tx;

    if (gain_db > 0.0)
    {
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [HighShelf_CS_{}Hz_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, gain_db, section, b0, b1, b2, a0, a1, a2);
    }
    else
    {
        iir->set_section_coeffs(section, a0, a1, a2, b0, b1, b2);
        SPDLOG_DEBUG("IIR_COEFF [HighShelf_CS_{}Hz_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, gain_db, section, a0, a1, a2, b0, b1, b2);
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
    double tx2 = tx * tx;

    double b0 = 1.0 + k * tx2 + 2.0 * root_k * tx;
    double b1 = 2.0 * (k * tx2 - 1.0);
    double b2 = 1.0 + k * tx2 - 2.0 * root_k * tx;
    double a0 = 1.0 + tx2 + 2.0 * tx;
    double a1 = 2.0 * (tx2 - 1.0);
    double a2 = 1.0 + tx2 - 2.0 * tx;

    if (gain_db > 0.0)
    {
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [LowShelf_CS_{}Hz_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, gain_db, section, b0, b1, b2, a0, a1, a2);
    }
    else
    {
        iir->set_section_coeffs(section, a0, a1, a2, b0, b1, b2);
        SPDLOG_DEBUG("IIR_COEFF [LowShelf_CS_{}Hz_{}dB] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, gain_db, section, a0, a1, a2, b0, b1, b2);
    }
}

IIR_DESIGN_BAND_REGISTER(low_shelf_cs, iir_design_low_shelf_cs);

// Design a notch filter using the RBJ formula.
static void iir_design_notch_cs(filter::IirFilter *iir, int section,
                             float frequency, float q, float /* gain_db */,
                             float sample_rate)
{
    double w0 = 2.0 * M_PI * frequency / sample_rate;
    double cos_w0 = std::cos(w0);
    double alpha = std::sin(w0) / (2.0 * q);
    
    double b0 = 1.0;
    double b1 = -2.0 * cos_w0;
    double b2 = 1.0;
    double a0 = 1.0 + alpha;
    double a1 = -2.0 * cos_w0;
    double a2 = 1.0 - alpha;
    
    iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    SPDLOG_DEBUG("IIR_COEFF [Notch_CS_{}Hz_Q{:.2f}] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                 (int)frequency, q, section, b0, b1, b2, a0, a1, a2);
}

IIR_DESIGN_BAND_REGISTER(notch_cs, iir_design_notch_cs);

// Design a low-pass filter using ControlSpace Butterworth formula.
static void iir_design_lpf_cs(filter::IirFilter *iir, int section,
                           float frequency, float q, float /* gain_db */,
                           float sample_rate)
{
    double tx = std::tan(frequency * M_PI / sample_rate);
    
    if (q > 0.1) { // 2nd order Butterworth
        double q_butterworth = 0.707107;
        double txq = tx / q_butterworth;
        double tx2 = tx * tx;

        double b0 = tx2;
        double b1 = 2.0 * tx2;
        double b2 = tx2;
        double a0 = 1.0 + txq + tx2;
        double a1 = 2.0 * (tx2 - 1.0);
        double a2 = 1.0 - txq + tx2;

        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [LPF_CS_{}Hz_ord2] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, section, b0, b1, b2, a0, a1, a2);
    }
    else { // 1st order
        double b0 = tx;
        double b1 = tx;
        double b2 = 0.0;
        double a0 = 1.0 + tx;
        double a1 = tx - 1.0;
        double a2 = 0.0;
        
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [LPF_CS_{}Hz_ord1] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, section, b0, b1, b2, a0, a1, a2);
    }
}

IIR_DESIGN_BAND_REGISTER(lpf_cs, iir_design_lpf_cs);

// Design a high-pass filter using ControlSpace Butterworth formula.
static void iir_design_hpf_cs(filter::IirFilter *iir, int section,
                           float frequency, float q, float /* gain_db */,
                           float sample_rate)
{
    double tx = std::tan(frequency * M_PI / sample_rate);
    
    if (q > 0.1) { // 2nd order Butterworth
        double q_butterworth = 0.707107;
        double txq = tx / q_butterworth;
        double tx2 = tx * tx;

        double b0 = 1.0;
        double b1 = -2.0;
        double b2 = 1.0;
        double a0 = 1.0 + txq + tx2;
        double a1 = 2.0 * (tx2 - 1.0);
        double a2 = 1.0 - txq + tx2;


        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [HPF_CS_{}Hz_ord2] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, section, b0, b1, b2, a0, a1, a2);
    }
    else { // 1st order
        double b0 = 1.0;
        double b1 = -1.0;
        double b2 = 0.0;
        double a0 = 1.0 + tx;
        double a1 = tx - 1.0;
        double a2 = 0.0;
        
        iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [HPF_CS_{}Hz_ord1] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     (int)frequency, section, b0, b1, b2, a0, a1, a2);
    }
}

IIR_DESIGN_BAND_REGISTER(hpf_cs, iir_design_hpf_cs);

// Design a low-frequency band-pass filter using the RBJ cookbook formula.
// Fixed at 30Hz with Q=1.0 at 48kHz sample rate.
static void iir_design_lf_bpf(filter::IirFilter *iir, int section,
                               float /* frequency */, float /* q */,
                               float /* gain_db */, float /* sample_rate */)
{
    double b0 = 0.001959643;
    double b1 = 0.0 * b0;          // Un-normalized: 0.0
    double b2 = -1.0 * b0;         // Un-normalized: -0.001959643
    double a0 = 1.0;
    double a1 = -1.996065324;
    double a2 = 0.996080715;

    iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    SPDLOG_DEBUG("IIR_COEFF [LF_BPF_30Hz_Q1.0] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                 section, b0, b1, b2, a0, a1, a2);
}

IIR_DESIGN_BAND_REGISTER(lf_bpf, iir_design_lf_bpf);

// Design a high-frequency band-pass filter using the RBJ cookbook formula.
// Fixed at 3.4kHz with Q=1.1 at 48kHz sample rate.
static void iir_design_hf_bpf(filter::IirFilter *iir, int section,
                               float /* frequency */, float /* q */,
                               float /* gain_db */, float /* sample_rate */)
{
    double b0 = 0.163660628;
    double b1 = 0.0 * b0;          // Un-normalized
    double b2 = -1.0 * b0;         // Un-normalized: -0.163660628
    double a0 = 1.0;
    double a1 = -1.509735221;
    double a2 = 0.672678745;

    iir->set_section_coeffs(section, b0, b1, b2, a0, a1, a2);
    SPDLOG_DEBUG("IIR_COEFF [HF_BPF_3400Hz_Q1.1] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                 section, b0, b1, b2, a0, a1, a2);
}

IIR_DESIGN_BAND_REGISTER(hf_bpf, iir_design_hf_bpf);

} // namespace