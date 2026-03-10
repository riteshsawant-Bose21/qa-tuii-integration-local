#pragma once

#include <samplerate.h>

namespace asrc {

class Asrc {
public:
    /// Constructor for the ASRC.
    ///
    /// For input ASRCs, the input is asynchronous, having a variable number
    /// of samples, and the output is synchronous, always having `frame_size`
    /// samples.  For output ASRCs, the input is synchronous, always having
    /// `frame_size` samples, and the output is asynchronous, having a variable
    /// number of samples.
    ///
    /// @param  channels  The number of channels in the audio stream.
    /// @param  frame_size  The number of samples in each synchronized frame.
    /// @param  is_input  True for an input ASRC, false for an output ASRC.
    Asrc(int channels, int frame_size, bool is_input);

    ~Asrc();


    /// Process one frame of audio through the ASRC.
    ///
    /// If this is an input ASRC, exactly `frame_size` samples will be written
    /// to `out`, and a variable number of samples will be read from `in`
    /// (depending on the `ratio` and the state of the ASRC).  At most,
    /// `buffer_size` samples will be read from `in`.  `buffer_size` should be
    /// greater than `frame_size` (by at least large enough to cover the
    /// maximum value of `ratio`).
    ///
    /// Likewise, for an output ASRC, exactly `frame_size` samples will be read
    /// from `in`, and up to `buffer_size` samples will be written to `out`.
    ///
    /// The input and output buffers should have the number of channels
    /// specified in the constructor, interleaved.
    ///
    /// @param  out  Pointer to the output buffer.
    /// @param  in   Pointer to the input buffer.
    /// @param  buffer_size  The size of the asynchronous buffer in samples.
    /// @param  ratio  The ratio of the output/input sample rates.
    /// @return  The number of asynchronous samples read or written.
    int process(float *out, const float *in, int buffer_size, double ratio);


private:
    // All of the SINC converters in libsamplerate have the same SNR of 97 dB,
    // but different bandwidths:
    // - SRC_SINC_BEST_QUALITY:   97% bandwidth (23.28 kHz at 48 kHz)
    // - SRC_SINC_MEDIUM_QUALITY: 90% bandwidth (21.6 kHz at 48 kHz)
    // - SRC_SINC_FASTEST:        80% bandwidth (19.2 kHz at 48 kHz)
    // trading off bandwidth for speed.
    static const int converter_type = SRC_SINC_FASTEST;
    SRC_STATE * state;
    int frame_size;
    bool is_input;
};

} // namespace asrc

