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
    double alpha;
    double q;
    bool is_first_order;
    FilterSection(double a = 0.0, double q_val = 0.0, bool first_order = false)
        : alpha(a), q(q_val), is_first_order(first_order) {}
};

using FilterConfig = std::array<FilterSection, 4>;

struct FilterOrderConfig {
    int order;
    FilterConfig config;
};

static const FilterOrderConfig butterworth_configs[] = {
    //6dB
    {1, {{ {1.0, 0.0, true}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //12dB
    {2, {{ {1.0, 0.707107, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    {3, {{ {1.0, 0.0, true}, {1.0, 1.0, false}, {0,0,false}, {0,0,false} }}},
    {4, {{ {1.0, 0.541196, false}, {1.0, 1.306563, false}, {0,0,false}, {0,0,false} }}},
    //36dB
    {6, {{ {1.0, 0.517638, false}, {1.0, 0.707107, false}, {1.0, 1.931852, false}, {0,0,false} }}},
    //48dB
    {8, {{ {1.0, 0.509796, false}, {1.0, 0.601345, false}, {1.0, 0.899976, false}, {1.0, 2.562915, false} }}}
};

static const FilterOrderConfig bessel_configs[] = {
    //12dB:
    {2, {{ {1.0, 0.5773502692, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //18dB:
    {3, {{ {0.9375044628, 0.0, true}, {1.023621594, 0.6907282598, false}, {0,0,false}, {0,0,false} }}},
    //24dB:
    {4, {{ {0.932877433, 0.522208208, false}, {1.046118213, 0.8051365672, false}, {0,0,false}, {0,0,false} }}},
    //36dB:
    {6,{{ {0.907955101, 0.510317315, false}, {0.956210131, 0.61119594, false}, {1.078227361, 1.023313015, false}, {0,0,false} }}},
    //48dB:
    {8,{{ {0.8941314387, 0.505991070, false}, {0.921092487,  0.5596091625, false}, {0.9819776223, 0.7108520759, false},
        {1.100391590,  1.225669430, false}
    }}}
};

static const FilterOrderConfig linkwitz_riley_configs[] = {
    //12dB
    {2, {{ {1.0, 0.5, false}, {0,0,false}, {0,0,false}, {0,0,false} }}},
    //24dB
    {4, {{ {1.0, 0.707107, false}, {1.0, 0.707107, false}, {0,0,false}, {0,0,false} }}},
    //36dB
    {6, {{ {1.0, 0.5, false}, {1.0, 1.0, false}, {1.0, 1.0, false}, {0,0,false} }}},
    //48dB
    {8, {{ {1.0, 0.541196, false}, {1.0, 1.306563, false}, {1.0, 0.541196, false}, {1.0, 1.306563, false} }}}
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
                                    const FilterOrderConfig* config, bool is_highpass,
                                    const char* filter_type) {
    int used_sections = (order + 1) / 2;
    if (used_sections > max_sections) {
        SPDLOG_WARN("Requested {} sections, max {}. Clamping.", used_sections, max_sections);
        used_sections = max_sections;
    }
    
    const double PI = 3.14159265;
    double freq_d = frequency;
    double fs_d = sample_rate;
    
    for (int s = 0; s < used_sections; ++s) {
        const FilterSection& section = config->config[s];
        
        if (section.alpha == 0.0 && section.q == 0.0) {
            iir->set_section_coeffs(start_section + s, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
            SPDLOG_DEBUG("IIR_COEFF [{}_{}_{}Hz_ord{}] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                         filter_type, is_highpass ? "HPF" : "LPF", (int)frequency, order,
                         start_section + s, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
            continue;
        }
        
        // t based on filter type
        double t;
        if (is_highpass) {
            t = std::tan(freq_d * PI / fs_d) / section.alpha;
        } else {
            t = std::tan(freq_d * PI / fs_d) * section.alpha;
        }
        
        double b0, b1, b2, a0, a1, a2;
        
        if (section.is_first_order) {
            // First-order section
            if (is_highpass) {
                b0 = 1.0;
                b1 = -1.0;
                b2 = 0.0;
            } else {
                b0 = t;
                b1 = t;
                b2 = 0.0;
            }
            a0 = 1.0 + t;
            a1 = t - 1.0;
            a2 = 0.0;
        } else {
            // Second-order section
            double t2 = t * t;
            double t_q = t / section.q;
            
            if (is_highpass) {
                b0 = 1.0;
                b1 = -2.0;
                b2 = 1.0;
            } else {
                b0 = t2;
                b1 = 2.0 * t2;
                b2 = t2;
            }
            a0 = 1.0 + t_q + t2;
            a1 = 2.0 * (t2 - 1.0);
            a2 = 1.0 - t_q + t2;
        }
        
        iir->set_section_coeffs(start_section + s, b0, b1, b2, a0, a1, a2);
        SPDLOG_DEBUG("IIR_COEFF [{}_{}_{}Hz_ord{}] sec{}: b0={:.17g} b1={:.17g} b2={:.17g} a0={:.17g} a1={:.17g} a2={:.17g}",
                     filter_type, is_highpass ? "HPF" : "LPF", (int)frequency, order,
                     start_section + s, b0, b1, b2, a0, a1, a2);
    }
    
    for (int s = used_sections; s < max_sections; ++s) {
        iir->set_section_coeffs(start_section + s, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    }
}

static void butterworth_lpf(IirFilter *iir, int start_section, float frequency,
                                  int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, butterworth_configs, 
                                                  sizeof(butterworth_configs)/sizeof(butterworth_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, false, "Butterworth");
}

static void butterworth_hpf(IirFilter *iir, int start_section, float frequency,
                                  int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, butterworth_configs, 
                                                  sizeof(butterworth_configs)/sizeof(butterworth_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, true, "Butterworth");
}

static void bessel_lpf(IirFilter *iir, int start_section, float frequency,
                             int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, bessel_configs, 
                                                  sizeof(bessel_configs)/sizeof(bessel_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, false, "Bessel");
}

static void bessel_hpf(IirFilter *iir, int start_section, float frequency,
                             int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, bessel_configs, 
                                                  sizeof(bessel_configs)/sizeof(bessel_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, true, "Bessel");
}

static void lr_lpf(IirFilter *iir, int start_section, float frequency,
                          int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, linkwitz_riley_configs, 
                                                  sizeof(linkwitz_riley_configs)/sizeof(linkwitz_riley_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, false, "LinkwitzRiley");
}

static void lr_hpf(IirFilter *iir, int start_section, float frequency,
                          int order, float sample_rate, int max_sections) {
    const FilterOrderConfig* config = find_config(order, linkwitz_riley_configs, 
                                                  sizeof(linkwitz_riley_configs)/sizeof(linkwitz_riley_configs[0]));
    design_crossover_filter(iir, start_section, frequency, order, sample_rate, 
                           max_sections, config, true, "LinkwitzRiley");
}

IIR_DESIGN_REGISTER(iir_crossover_butterworth_lpf, butterworth_lpf);
IIR_DESIGN_REGISTER(iir_crossover_butterworth_hpf, butterworth_hpf);
IIR_DESIGN_REGISTER(iir_crossover_bessel_lpf, bessel_lpf);
IIR_DESIGN_REGISTER(iir_crossover_bessel_hpf, bessel_hpf);
IIR_DESIGN_REGISTER(iir_crossover_linkwitz_riley_lpf, lr_lpf);
IIR_DESIGN_REGISTER(iir_crossover_linkwitz_riley_hpf, lr_hpf);