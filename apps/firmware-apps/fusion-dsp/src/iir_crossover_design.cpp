#include "iir_design.h"
#include "iir.h"
#include <spdlog/spdlog.h>

#include <cmath>
#include <array>
#include <functional>

using namespace filter;

struct FilterSection {
    float alpha;
    float q;
    bool is_first_order;
    FilterSection(float a = 0.0f, float q_val = 0.0f, bool first_order = false)
        : alpha(a), q(q_val), is_first_order(first_order) {}
};


using FilterConfig = std::array<FilterSection, 4>;

struct FilterOrderConfig {
    int order;
    FilterConfig config;
    FilterOrderConfig(int ord, const FilterConfig& cfg) : order(ord), config(cfg) {}
};

using CoeffCalcFunc = std::function<void(float tx, float q, float cumulative_b0,
                                        float& b0, float& b1, float& b2,
                                        float& a1, float& a2)>;

static void generic_filter_design(IirFilter *iir, int start_section, float frequency,
                                int order, float sample_rate, int max_sections,
                                const FilterOrderConfig& config,
                                CoeffCalcFunc calc_first_order,
                                CoeffCalcFunc calc_second_order)
{
    int used_sections = (order + 1) / 2;
    if (used_sections > max_sections) {
        SPDLOG_WARN("filter_design: requested {} sections, max {}. Clamping.", used_sections, max_sections);
        used_sections = max_sections;
    }

    const float PI = 3.14159265f;
    float cumulative_b0 = 1.0f;

    for (int s = 0; s < used_sections; ++s) {
        const FilterSection& section = config.config[s];

        if (section.alpha == 0.0f && section.q == 0.0f) {
            iir->set_section_coeffs(start_section + s, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);
            continue;
        }

        float tx = tanf(frequency * (PI / sample_rate));
        float b0, b1, b2, a1, a2;

        if (section.is_first_order) {
            calc_first_order(tx * section.alpha, section.q, cumulative_b0, b0, b1, b2, a1, a2);
        } else {
            calc_second_order(tx * section.alpha, section.q, cumulative_b0, b0, b1, b2, a1, a2);
        }

        cumulative_b0 = b0;
        iir->set_section_coeffs(start_section + s, b0, b1, b2, 1.0f, a1, a2);
    }

    for (int s = used_sections; s < max_sections; ++s) {
        iir->set_section_coeffs(start_section + s, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);
    }
}

static const FilterOrderConfig butterworth_configs[] = {
    //6dB
    {1, {{ {1.0f, 0.0f, true}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //12dB
    {2, {{ {1.0f, 0.707107f, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //18dB
    {3, {{ {1.0f, 0.0f, true}, {1.0f, 1.000000f, false}, {0,0,false}, {0,0,false} }}},
    //24dB
    {4, {{ {1.0f, 0.541196f, false}, {1.0f, 1.306563f, false}, {0,0,false}, {0,0,false} }}},
    //36dB
    {6, {{ {1.0f, 0.517638f, false}, {1.0f, 0.707107f, false}, {1.0f, 1.931852f, false}, {0,0,false} }}},
    //48dB
    {8, {{ {1.0f, 0.509796f, false}, {1.0f, 0.601345f, false}, {1.0f, 0.899976f, false}, {1.0f, 2.562915f, false} }}}
};

static const FilterOrderConfig bessel_configs[] = {
    //12dB:
    {2, {{ {1.0f, 0.5773502692f, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //18dB:
    {3, {{ {0.9375044628f, 0.0f, true}, {1.023621594f, 0.6907282598f, false}, {0,0,false}, {0,0,false} }}},
    //24dB:
    {4, {{ {0.932877433f, 0.522208208f, false}, {1.046118213f, 0.8051365672f, false}, {0,0,false}, {0,0,false} }}},
    //36dB:
    {6,{{ {0.907955101f, 0.510317315f, false}, {0.956210131f, 0.61119594f, false}, {1.078227361f, 1.023313015f, false}, {0,0,false} }}},
    //48dB:
    {8,{{ {0.8941314387f, 0.505991070f, false}, {0.921092487f,  0.5596091625f, false}, {0.9819776223f, 0.7108520759f, false},
        {1.100391590f,  1.225669430f, false}
    }}}
};

static const FilterOrderConfig linkwitz_riley_configs[] = {
    //12dB
    {2, {{ {1.0f, 0.5f, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //24dB
    {4, {{ {1.0f, 0.707107f, false}, {1.0f, 0.707107f, false}, {0,0,false}, {0,0,false} }}},
    //36dB
    {6, {{ {1.0f, 0.5f, false}, {1.0f, 1.0f, false}, {1.0f, 1.0f, false}, {0,0,false} }}},
    //48dB
    {8, {{ {1.0f, 0.541196f, false}, {1.0f, 1.306563f, false}, {1.0f, 0.541196f, false}, {1.0f, 1.306563f, false} }}}
};

// Butterworth coefficients
static CoeffCalcFunc butterworth_lpf_first = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    (void)q;
    float tmp = 1.0f + tx;
    b0 = cum_b0 * tx / tmp;
    b1 = 1.0f;
    b2 = 0.0f;
    a1 = (1.0f - tx) / tmp;
    a2 = 0.0f;
};

static CoeffCalcFunc butterworth_lpf_second = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    float tx2 = tx * tx;
    float txq = tx / q;
    float tmp = 1.0f + txq + tx2;
    b0 = cum_b0 * tx2 / tmp;
    b1 = 2.0f;
    b2 = 1.0f;
    a1 = 2.0f * (1.0f - tx2) / tmp;
    a2 = -((1.0f - txq + tx2) / tmp);
};

static CoeffCalcFunc butterworth_hpf_first = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    (void)q;
    float tmp = 1.0f + tx;
    b0 = cum_b0 / tmp;
    b1 = -1.0f; 
    b2 = 0.0f;
    a1 = (1.0f - tx) / tmp;
    a2 = 0.0f;
};

static CoeffCalcFunc butterworth_hpf_second = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    float tx2 = tx * tx;
    float txq = tx / q;
    float tmp = 1.0f + txq + tx2;
    b0 = cum_b0 / tmp;
    b1 = -2.0f; 
    b2 = 1.0f;
    a1 = 2.0f * (1.0f - tx2) / tmp;
    a2 = -(1.0f - txq + tx2) / tmp;
};

// Bessel coefficients
static CoeffCalcFunc bessel_lpf_first = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    (void)q;
    float tmp = 1.0f + tx;
    b0 = cum_b0 * tx / tmp;
    b1 = 1.0f;
    b2 = 0.0f;
    a1 = (1.0f - tx) / tmp;
    a2 = 0.0f;
};

static CoeffCalcFunc bessel_lpf_second = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    float tx2 = tx * tx;
    float txq = tx / q;
    float tmp = 1.0f + txq + tx2;
    b0 = cum_b0 * tx2 / tmp;
    b1 = 2.0f;
    b2 = 1.0f;
    a1 = 2.0f * (1.0f - tx2) / tmp;
    a2 = -((1.0f - txq + tx2) / tmp);
};

static CoeffCalcFunc bessel_hpf_first = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    (void)q;
    float tmp = 1.0f + tx;
    b0 = cum_b0 / tmp;
    b1 = -1.0f;
    b2 = 0.0f;
    a1 = (1.0f - tx) / tmp;
    a2 = 0.0f;
};

static CoeffCalcFunc bessel_hpf_second = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    float tx2 = tx * tx;
    float txq = tx / q;
    float tmp = 1.0f + txq + tx2;
    b0 = cum_b0 / tmp;
    b1 = -2.0f;
    b2 = 1.0f;
    a1 = 2.0f * (1.0f - tx2) / tmp;
    a2 = -(1.0f - txq + tx2) / tmp;
};

// Linkwitz-Riley coefficient functions (only 2nd order)
static CoeffCalcFunc lr_lpf_second = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    float tx2 = tx * tx;
    float txq = tx / q;
    float tmp = 1.0f + txq + tx2;
    b0 = cum_b0 * tx2 / tmp;
    b1 = 2.0f;
    b2 = 1.0f;
    a1 = 2.0f * (1.0f - tx2) / tmp;
    a2 = -(1.0f - txq + tx2) / tmp;
};

static CoeffCalcFunc lr_hpf_second = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
    float tx2 = tx * tx;
    float txq = tx / q;
    float tmp = 1.0f + txq + tx2;
    b0 = cum_b0 / tmp;
    b1 = -2.0f;
    b2 = 1.0f;
    a1 = 2.0f * (1.0f - tx2) / tmp;
    a2 = -(1.0f - txq + tx2) / tmp;
};

static CoeffCalcFunc lr_error_first = [](float tx, float q, float cum_b0, float& b0, float& b1, float& b2, float& a1, float& a2) {
   SPDLOG_ERROR("Linkwitz-Riley first order filter is not supported."); 
   (void)tx;
   (void)q;
   b0 = cum_b0;
   b1 = b2 = a1 = a2 = 0.0f;
};

static const FilterOrderConfig* find_config(int order, const FilterOrderConfig* configs, int num_configs) {
    for (int i = 0; i < num_configs; ++i) {
        if (configs[i].order == order) {
            return &configs[i];
        }
    }
    
    // fallback logic - we support only 2,3,4,6,8 orders and if user requests 5 or 7 we're falling back to 2. This may be unexpected (confirm?)
    int fallback_index = (num_configs > 1) ? 1 : 0;
    int actual_order = configs[fallback_index].order;
    
    SPDLOG_WARN("filter_design: Order {} not supported, falling back to order {} ({} dB/octave)", 
               order, actual_order, actual_order * 6);
    
    return &configs[fallback_index];
}

static void butterworth_common_lpf(IirFilter *iir, int start_section, float frequency,
                                  int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, butterworth_configs, sizeof(butterworth_configs)/sizeof(butterworth_configs[0]));
    generic_filter_design(iir, start_section, frequency, order, sample_rate, max_sections,
                          *config, butterworth_lpf_first, butterworth_lpf_second);
}

static void butterworth_common_hpf(IirFilter *iir, int start_section, float frequency,
                                  int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, butterworth_configs, sizeof(butterworth_configs)/sizeof(butterworth_configs[0]));
    generic_filter_design(iir, start_section, frequency, order, sample_rate, max_sections,
                          *config, butterworth_hpf_first, butterworth_hpf_second);
}

static void bessel_common_lpf(IirFilter *iir, int start_section, float frequency,
                             int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, bessel_configs, sizeof(bessel_configs)/sizeof(bessel_configs[0]));
    generic_filter_design(iir, start_section, frequency, order, sample_rate, max_sections,
                          *config, bessel_lpf_first, bessel_lpf_second);
}

static void bessel_common_hpf(IirFilter *iir, int start_section, float frequency,
                             int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, bessel_configs, sizeof(bessel_configs)/sizeof(bessel_configs[0]));
    generic_filter_design(iir, start_section, frequency, order, sample_rate, max_sections,
                          *config, bessel_hpf_first, bessel_hpf_second);
}

static void lr_common_lpf(IirFilter *iir, int start_section, float frequency,
                          int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, linkwitz_riley_configs, sizeof(linkwitz_riley_configs)/sizeof(linkwitz_riley_configs[0]));
    generic_filter_design(iir, start_section, frequency, order, sample_rate, max_sections,
                          *config, lr_error_first, lr_lpf_second);
}

static void lr_common_hpf(IirFilter *iir, int start_section, float frequency,
                          int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, linkwitz_riley_configs, sizeof(linkwitz_riley_configs)/sizeof(linkwitz_riley_configs[0]));
    generic_filter_design(iir, start_section, frequency, order, sample_rate, max_sections,
                          *config, lr_error_first, lr_hpf_second);
}

IIR_DESIGN_REGISTER(iir_crossover_butterworth_lpf, butterworth_common_lpf);
IIR_DESIGN_REGISTER(iir_crossover_butterworth_hpf, butterworth_common_hpf);
IIR_DESIGN_REGISTER(iir_crossover_bessel_lpf, bessel_common_lpf);
IIR_DESIGN_REGISTER(iir_crossover_bessel_hpf, bessel_common_hpf);
IIR_DESIGN_REGISTER(iir_crossover_linkwitz_riley_lpf, lr_common_lpf);
IIR_DESIGN_REGISTER(iir_crossover_linkwitz_riley_hpf, lr_common_hpf);
