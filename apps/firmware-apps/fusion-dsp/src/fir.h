//
// fir.h
// Computationally efficient implementation of FIR filtering
//
// Ben Overzat, May 2022
// 
//

#pragma once

#include "firbase.h"

#include <memory>

namespace filter {

class FirFilter : public FirFilterBase
{
public:
    /// Simple Ctors
    /// \param num_taps  number of fir filter taps
    /// \param frame_size  number of samples in a frame to be processed 
    /// \param sample_rate  the sample rate is used to calculate crossfade time 
    FirFilter(int num_taps, int_fast32_t frame_size, int_fast32_t sample_rate);

    /// a vector of num_taps fir coefficients
    /// \param coeffs  the filter coefficients of length numTaps
    FirFilterBase *with_coefficients(const float *coeffs) override;

    /// process one frame of audio through an fir filter.
    ///
    /// \param out  the array of output samples, of length `frame_size`.
    /// \param in  the array of input samples, of length `frameSize`.
    virtual void process(float *out, const float *in);

protected:
    std::unique_ptr<float[]> _coeffs;
    // we need (num_channels*num_bands) state arrays
    std::unique_ptr<float[]> _states;
    int _num_taps_optimize;
};

}

// end of file