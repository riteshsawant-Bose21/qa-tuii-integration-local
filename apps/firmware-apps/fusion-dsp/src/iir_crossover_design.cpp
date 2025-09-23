//
// iir_crossover_design.cpp
// IIR filter coefficient calculations for crossovers.
// Implements Butterworth, Bessel, and Linkwitz-Riley filter designs from CSD.
//

#include "iir_design.h"
#include "iir.h"
#include <spdlog/spdlog.h>

#include <cmath>
#include <array>

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
};

static const FilterOrderConfig butterworth_configs[] = {
    //6dB
    {1, {{ {1.0f, 0.0f, true}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //12dB
    {2, {{ {1.0f, 0.707107f, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    {3, {{ {1.0f, 0.0f, true}, {1.0f, 1.0f, false}, {0,0,false}, {0,0,false} }}},
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

static const FilterOrderConfig* find_config(int order, const FilterOrderConfig* configs, int num_configs) {
    for (int i = 0; i < num_configs; ++i) {
        if (configs[i].order == order) {
            return &configs[i];
        }
    }

    // Find nearest supported order
    int best_idx = 0;
    int best_diff = std::abs(configs[0].order - order);
    for (int i = 1; i < num_configs; ++i) {
        int diff = std::abs(configs[i].order - order);
        if (diff < best_diff || (diff == best_diff && configs[i].order > configs[best_idx].order)) {
            best_idx = i;
            best_diff = diff;
        }
    }

    SPDLOG_WARN("Order {} not supported, using nearest supported order {}", 
                order, configs[best_idx].order);
    return &configs[best_idx];
}

static void design_crossover_filter(IirFilter *iir, int start_section, float frequency,
                                    int order, float sample_rate, int max_sections,
                                    const FilterOrderConfig* config, bool is_highpass) {
    int used_sections = (order + 1) / 2;
    if (used_sections > max_sections) {
        SPDLOG_WARN("Requested {} sections, max {}. Clamping.", used_sections, max_sections);
        used_sections = max_sections;
    }
    
    const float PI = 3.14159265f;
    
    for (int s = 0; s < used_sections; ++s) {
        const FilterSection& section = config->config[s];
        
        if (section.alpha == 0.0f && section.q == 0.0f) {
            iir->set_section_coeffs(start_section + s, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);
            continue;
        }
        
        // t based on filter type
        float t;
        if (is_highpass) {
            t = tanf(frequency * PI / sample_rate) / section.alpha;
        } else {
            t = tanf(frequency * PI / sample_rate) * section.alpha;
        }
        
        float b0, b1, b2, a0, a1, a2;
        
        if (section.is_first_order) {
            // First-order section
            if (is_highpass) {
                b0 = 1.0f;
                b1 = -1.0f;
                b2 = 0.0f;
            } else {
                b0 = t;
                b1 = t;
                b2 = 0.0f;
            }
            a0 = 1.0f + t;
            a1 = t - 1.0f;
            a2 = 0.0f;
        } else {
            // Second-order section
            float t2 = t * t;
            float t_q = t / section.q;
            
            if (is_highpass) {
                b0 = 1.0f;
                b1 = -2.0f;
                b2 = 1.0f;
            } else {
                b0 = t2;
                b1 = 2.0f * t2;
                b2 = t2;
            }
            a0 = 1.0f + t_q + t2;
            a1 = 2.0f * (t2 - 1.0f);
            a2 = 1.0f - t_q + t2;
        }
        
        iir->set_section_coeffs(start_section + s, b0, b1, b2, a0, a1, a2);
    }
    
    for (int s = used_sections; s < max_sections; ++s) {
        iir->set_section_coeffs(start_section + s, 1.0f, 0.0f, 0.0f, 1.0f, 0.0f, 0.0f);
    }
}

static void butterworth_lpf(IirFilter *iir, int start_section, float frequency,
                                  int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, butterworth_configs, 
                                                  sizeof(butterworth_configs)/sizeof(butterworth_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, false);
}

static void butterworth_hpf(IirFilter *iir, int start_section, float frequency,
                                  int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, butterworth_configs, 
                                                  sizeof(butterworth_configs)/sizeof(butterworth_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, true);
}

static void bessel_lpf(IirFilter *iir, int start_section, float frequency,
                             int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, bessel_configs, 
                                                  sizeof(bessel_configs)/sizeof(bessel_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, false);
}

static void bessel_hpf(IirFilter *iir, int start_section, float frequency,
                             int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, bessel_configs, 
                                                  sizeof(bessel_configs)/sizeof(bessel_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, true);
}

static void lr_lpf(IirFilter *iir, int start_section, float frequency,
                          int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, linkwitz_riley_configs, 
                                                  sizeof(linkwitz_riley_configs)/sizeof(linkwitz_riley_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, false);
}

static void lr_hpf(IirFilter *iir, int start_section, float frequency,
                          int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, linkwitz_riley_configs, 
                                                  sizeof(linkwitz_riley_configs)/sizeof(linkwitz_riley_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, true);
}

IIR_DESIGN_REGISTER(iir_crossover_butterworth_lpf, butterworth_lpf);
IIR_DESIGN_REGISTER(iir_crossover_butterworth_hpf, butterworth_hpf);
IIR_DESIGN_REGISTER(iir_crossover_bessel_lpf, bessel_lpf);
IIR_DESIGN_REGISTER(iir_crossover_bessel_hpf, bessel_hpf);
IIR_DESIGN_REGISTER(iir_crossover_linkwitz_riley_lpf, lr_lpf);
IIR_DESIGN_REGISTER(iir_crossover_linkwitz_riley_hpf, lr_hpf);