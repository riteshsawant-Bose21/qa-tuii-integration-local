//
// filter.h
// abstract base class for all filters
//

#pragma once
#include <cstdint>

namespace filter {

/// abstract class for managing and processing filters
class FilterBase
{
public:
    /// simple ctors 
    /// \param frame_size  number of samples in a frame to be processed 
    /// \param sample_rate signal sample rate in samples per second 
    FilterBase(int_fast32_t frame_size, int_fast32_t sample_rate)
    : _frame_size(frame_size), _extra_gain(1.0f), _sample_rate(sample_rate), _enable(true) {}

    /// set the extra gain prior to setting coefficients (usually to 1.0)
    /// \param gain  the gain to apply to the filter
    FilterBase *with_extra_gain(const float &gain)
    {
        _extra_gain = gain;
        return this;
    }

    int_fast32_t sample_rate(void) const
    {
        return _sample_rate;
    }

    int_fast32_t get_frame_size(void) const
    {
        return _frame_size;
    }

    float get_extra_gain(void) const
    {
        return _extra_gain;
    }

    void set_enable(bool enable)
    {
        _enable = enable;
    }

    bool is_enabled(void) const
    {
        return _enable;
    }

private:
    /// number of samples in a frame to be processed
    const int_fast32_t _frame_size;
    /// extra gain to apply to filter 
    float _extra_gain;

    const int_fast32_t _sample_rate;

    bool _enable;
};

}

// end of file