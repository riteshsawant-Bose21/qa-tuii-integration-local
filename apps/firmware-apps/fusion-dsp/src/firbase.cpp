//
// firbase.cpp
//
// abstract class for managing and processing fir filters
// with functions for setting up an arbitrary band
// (raised cosine filter)
//

#include "firbase.h"
#include <spdlog/spdlog.h>

namespace filter {

void ArbitraryBand::set_type(filter::CosineFilterType type)
{
    if (type < filter::CosineFilterType::HIGH_SHELF || type > filter::CosineFilterType::MESA)
    {
        SPDLOG_ERROR("invalid eq type");
    }
    _type = type;
}

void ArbitraryBand::set_gain(float gain)
{
    _gain = gain;
}

void ArbitraryBand::set_frequency(float freq, int bandnum)
{
    if (1 == bandnum)
    {
        _freq1 = freq;
    }
    else if (2 == bandnum)
    {
        _freq2 = freq;
    }
    else
    {
        SPDLOG_ERROR("invalid eq band");
    }
}

void ArbitraryBand::set_bandwidth(float bw, int bandnum)
{
    if (1 == bandnum)
    {
        _bw1 = bw;
    }
    else if (2 == bandnum)
    {
        _bw2 = bw;
    }
    else
    {
        SPDLOG_ERROR("invalid eq band");
    }
}

// add in the given arbitrary band's gain curve to the target gain 
// curve. the 4 kinds of arbitrary bands are from the raised cosine 
// equalization (mc_grath et al. 2004) paper
void ArbitraryBand::add_band_to_response(std::shared_ptr<float[]> &target_mag, 
    const std::shared_ptr<float[]> &freq, int resp_size)
{
    switch (_type)
    {
    case filter::CosineFilterType::HIGH_SHELF:
        add_high_shelf_to_response(target_mag, freq, resp_size);
        break;
    case filter::CosineFilterType::LOW_SHELF:
        add_low_shelf_to_response(target_mag, freq, resp_size);
        break;
    case filter::CosineFilterType::PEAK:
        add_peak_to_response(target_mag, freq, resp_size);
        break;
    case filter::CosineFilterType::MESA:
        add_mesa_to_response(target_mag, freq, resp_size);
        break;
    }
}

void ArbitraryBand::add_high_shelf_to_response(std::shared_ptr<float[]> &target_mag, 
    const std::shared_ptr<float[]> &freq, int resp_size)
{
    double log_fc{log2(_freq1)};
    double half_width{_bw1 / 2.0};
    double width{_bw1};
    // in decibel
    double gain = _gain;

    for (int index{0}; index < resp_size; ++index)
    {
        double log_f{log10(freq[index]) / log10(2.0)};
        if (log_f > (log_fc - half_width))
        {
            if (log_f < (log_fc + half_width))
            {
                target_mag[index] += gain * (0.5 + 0.5 * cos(M_PI * (log_f - log_fc - 
                    half_width) / width));
            }
            else
            {
                target_mag[index] += gain;
            }
        }
    }
}

void ArbitraryBand::add_low_shelf_to_response(std::shared_ptr<float[]> &target_mag, 
    const std::shared_ptr<float[]> &freq, int resp_size)
{
    double log_fc{log2(_freq1)};
    double half_width{_bw1 / 2.0};
    double width{_bw1};
    // in decibel
    double gain = _gain;

    for (int index{0}; index < resp_size; ++index)
    {
        double log_f{log10(freq[index]) / log10(2.0)};
        if (log_f < (log_fc - half_width))
        {
            target_mag[index] += gain;
        }
        else if (log_f < (log_fc + half_width))
        {
            target_mag[index] += gain * (0.5 + 0.5 * cos(M_PI * (log_f - log_fc + 
                half_width) / width));
        }
    }
}

void ArbitraryBand::add_peak_to_response(std::shared_ptr<float[]> &target_mag, 
    const std::shared_ptr<float[]> &freq, int resp_size)
{
    double log_fc{log2(_freq1)};
    double width{_bw1};
    // in decibel
    double gain = _gain;

    for (int index{0}; index < resp_size; ++index)
    {
        double log_f{log10(freq[index]) / log10(2.0)};
        if (log_f > (log_fc - width) && log_f < (log_fc + width))
        {
            target_mag[index] += gain * (0.5 + 0.5 * cos(M_PI * (log_f - log_fc) / width));
        }
    }
}

void ArbitraryBand::add_mesa_to_response(std::shared_ptr<float[]> &target_mag, 
    const std::shared_ptr<float[]> &freq, int resp_size)
{
    double log_fc_lo{log2(_freq1)};
    double log_fc_hi{log2(_freq2)};
    double half_width_lo{_bw1 / 2.0};
    double half_width_hi{_bw2 / 2.0};
    double width_lo{_bw1};
    double width_hi{_bw2};
    double gain = _gain;

    if (log_fc_lo >= log_fc_hi)
    {
        SPDLOG_ERROR("low frequency is higher than high frequency");
    }

    for (int index{0}; index < resp_size; ++index)
    {
        double log_f{log10(freq[index]) / log10(2.0)};
        if (log_f > (log_fc_lo - half_width_lo))
        {
            if (log_f < (log_fc_lo + half_width_lo))
            {
                target_mag[index] += gain * (0.5 + 0.5 * cos(M_PI * (log_f - 
                    log_fc_lo - half_width_lo) / width_lo));
            }
            else if (log_f < (log_fc_hi - half_width_hi))
            {
                target_mag[index] += gain;
            }
            else if (log_f < (log_fc_hi + half_width_hi))
            {
                target_mag[index] += gain * (0.5 + 0.5 * cos(M_PI * (log_f - 
                    log_fc_hi + half_width_hi) / width_hi));
            }
        }
    }
}

}