#pragma once

#include "pffft.h"

#include <spdlog/spdlog.h>

#include <cstdint>
#include <memory>


// NOTE: PFFFT requires its input array, output array, and workspace to all be
// aligned on a 16-byte boundary.  To ensure this, `io_buf` is allocated and
// aligned, and the input and output arrays are copied into and out of this
// array.  Burdening the code using the FFT with the alignment of the input
// and output arrays would allow us to save some memory and the MIPS for the
// array copies.

// NOTE: If many signal processing blocks are using FFTs of the same size, we
// will have duplicated arrays in memory for the twiddle factors, workspace
// memory, and I/O alignment buffer.  We could optimize memory by reusing FFTs
// of the same size in multiple blocks (perhaps keeping a table of `Fft`
// objects of different sizes).  We would have to be careful about concurrency
// in the case where multiple tasks have blocks using the same FFT size.


namespace fft {


/// An FFT class for abstracting the API of any platform-specific, optimized
/// FFT implementations.  This manages the twiddle factors and workspaces
/// needed by the FFT.
///
/// The same `Fft` object can be used to perform multiple FFTs.  For example,
/// an algorithm that calculates an FFT on multiple channels only needs one
/// instance of this class.
///
/// The frequency-domain data used by the FFT is stored in a float array with
/// the real and imaginary parts interleaved.  The first two elements of the
/// array store the real parts of the DC and Nyquist bins, respectively.  So
/// given a real signal, the output stores the positive half-spectrum as:
///
///     - X[0].re
///     - X[N/2].re
///     - X[1].re
///     - X[1].im
///     - X[2].re
///     - X[2].im
///     - ...
///     - X[N/2-1].re
///     - X[N/2-1].im
///
/// Neither the forward or inverse FFT performs any scaling on the results.
/// If you perform an N-point forward FFT followed by an inverse FFT, the
/// output needs to be scaled by 1/N to match the original signal.
class Fft {

public:
    /// Create an object for performing real FFTs.  This allocates and
    /// initializes any twiddle factors or workspaces needed by the platform-
    /// specific FFT implementation.
    Fft(int_fast32_t size) : size(size)
    {
        pffft_setup = pffft_new_setup(size, PFFFT_REAL);

        if (pffft_setup == nullptr)
        {
            SPDLOG_ERROR("Fft: Couldn't initialize FFT of size {}.", size);
        }

        io_buf.resize(size, ALIGN_SIZE);
        work_buf.resize(size, ALIGN_SIZE);
    }

    ~Fft()
    {
        if (pffft_setup != nullptr)
        {
            pffft_destroy_setup(pffft_setup);
        }
    }


    /// Perform a real forwward FFT.  Only the positive half-spectrum is
    /// calculated, with the real and imaginary parts interleaved, and the
    /// first two values of the output array containing the real parts of the
    /// DC and Nyquist bins, respectively.
    ///
    /// @param  out  The output complex positive half-spectrum.
    /// @param  in   The real, time-domain input signal.
    void forward(float *out, const float *in)
    {
        memcpy(io_buf.get(), in, size * sizeof(float));
        pffft_transform_ordered(pffft_setup, io_buf.get(), io_buf.get(),
                                work_buf.get(), PFFFT_FORWARD);
        memcpy(out, io_buf.get(), size * sizeof(float));
    }


    /// Perform a real inverse FFT.  The input array should consist of only
    /// the positive half-spectrum, with the real and imaginay parts interleaved,
    /// and the first two values of the input array containing the real parts of
    /// the DC and Nyquist bins, respectively.  Note that this doesn't perform
    /// any output scaling, as MATLAB and SciPy FFTs do.  If you perform an
    /// N-point forward FFT followed by an inverse FFT, you need to scale the
    /// output by 1/N to get the original signal.
    ///
    /// @param  out  The real, time-domain output signal.
    /// @param  in   The input complex positive helf-spectrum.
    void inverse(float *out, const float *in)
    {
        memcpy(io_buf.get(), in, size * sizeof(float));
        pffft_transform_ordered(pffft_setup, io_buf.get(), io_buf.get(),
                                work_buf.get(), PFFFT_BACKWARD);
        memcpy(out, io_buf.get(), size * sizeof(float));
    }


private:
    static const size_t ALIGN_SIZE = 4 * sizeof(float);
    int_fast32_t size;
    PFFFT_Setup *pffft_setup;
    bosepro::DspTempMemory<float[]> io_buf;
    bosepro::DspTempMemory<float[]> work_buf;
};

} // namespace fft
