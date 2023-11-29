#pragma once
#include <cstdint>

#include "fir.h"

namespace filter {

class _WFirFilter : public FirFilter
{
public:
    /// simple ctors
    /// \param num_taps  number of fir filter taps
    /// \param frame_size  number of samples in a frame to be processed 
    /// \param sample_rate  the sample rate is used to calculate crossfade time 
    _WFirFilter(int num_taps, float lambda, int_fast32_t frame_size, int_fast32_t sample_rate)
    : FirFilter{num_taps, frame_size, sample_rate}, _lambda{lambda} {}

    /// Process one frame of audio through an FIR filter.
    ///
    /// \param out  The array of output samples, of length `frameSize`.
    /// \param in  The array of input samples, of length `frameSize`.
    void process(float *out, const float *in);

private:
    const float _lambda;
};

}

// end of file
