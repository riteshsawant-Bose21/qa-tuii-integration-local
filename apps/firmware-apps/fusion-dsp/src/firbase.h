//
// firbase.h
//
// abstract class for managing and processing fir filters
// with functions for setting up an arbitrary band
// (raised cosine filter)
// 

#pragma once

#include <memory>
#include <map>

#include "filter.h"

namespace filter {

// Filter type enum for raised cosine filters
enum class CosineFilterType {
    HIGH_SHELF,
    LOW_SHELF,
    PEAK,
    MESA
};

// Description of a band for ArbitraryEQ.
class ArbitraryBand {
public:
    void set_enable(bool enable)
    {
        _enable = enable;
    }
    void set_type(CosineFilterType type);
    void set_gain(const float gain);
    void set_frequency(const float freq, int bandnum = 1);
    void set_bandwidth(const float bw, int bandnum = 1);
    void add_band_to_response(std::shared_ptr<float[]> &target_mag, 
        const std::shared_ptr<float[]> &freq, int resp_size);

    bool is_enabled(void) const
    {
        return _enable;
    }
    CosineFilterType show_type(void) const
    {
        return _type;
    }
    float show_gain(void) const
    {
        return _gain;
    }
    float show_frequency(int bandnum = 1) const
    {
        if (1 == bandnum)
        {
            return _freq1;
        }
        else
        {
            return _freq2;
        }
    }
    float show_bandwidth(int bandnum = 1) const
    {
        if (1 == bandnum)
        {
            return _bw1;
        }
        else
        {
            return _bw2;
        }
    }
private:
    static const std::map<std::string, filter::CosineFilterType> _type_map;
    filter::CosineFilterType _type{filter::CosineFilterType::HIGH_SHELF};
    float _gain{0};
    float _freq1{1000.0};
    float _bw1{1.0};
    float _freq2{1000.0};
    float _bw2{1.0};
    bool _enable{false};

    void add_high_shelf_to_response(std::shared_ptr<float[]> &target_mag, 
        const std::shared_ptr<float[]> &freq, int resp_size);
    void add_low_shelf_to_response(std::shared_ptr<float[]> &target_mag, 
        const std::shared_ptr<float[]> &freq, int resp_size);
    void add_peak_to_response(std::shared_ptr<float[]> &target_mag, 
        const std::shared_ptr<float[]> &freq, int resp_size);
    void add_mesa_to_response(std::shared_ptr<float[]> &target_mag, 
        const std::shared_ptr<float[]> &freq, int resp_size);
};

/// abstract class for managing and processing fir filters
class FirFilterBase : public FilterBase
{
public:
    /// simple ctors 
    /// \param num_sections  number of second order sections (sos)
    /// \param frame_size  number of samples in a frame to be processed 
    /// \param sample_rate signal sample rate in samples per second 
    FirFilterBase(int num_taps, int_fast32_t frame_size, int_fast32_t sample_rate)
    : FilterBase{frame_size, sample_rate}, _num_taps{num_taps} {}

    /// a vector of num_taps fir coefficients
    /// \param coeffs  the filter coefficients of length num_taps
    virtual FirFilterBase *with_coefficients(const float *coeffs) = 0;

    int show_num_taps(void) const
    {
        return _num_taps;
    }
private:
    int _num_taps;
};


}