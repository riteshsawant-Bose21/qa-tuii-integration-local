#pragma once

namespace filter {

/// The order in which a second-order section's a1 coefficient appears in a
/// `coeffs` array.  See `iir_process()`
const int A1_INDEX = 0;

/// The order in which a second-order section's a2 coefficient appears in a
/// `coeffs` array.  See `iir_process()`
const int A2_INDEX = 1;

/// The order in which a second-order section's b1 coefficient appears in a
/// `coeffs` array.  See `iir_process()`
const int B1_INDEX = 2;

/// The order in which a second-order section's b2 coefficient appears in a
/// `coeffs` array.  See `iir_process()`
const int B2_INDEX = 3;


/// Calculate the index of the first (a1) coefficient for a second-order
/// section. See `iir_process()`.
///
/// \param section  The index of this section.
/// \param num_sections  The total number of sections.
/// \return  The index of this section's a1 coefficient within a `coeffs` array.

static inline int coeff_index_start(int section, int num_sections)
{
    if (section < (num_sections & ~0x3))
    {
        return 16 * (section >> 2) + (section & 0x3);
    }
    else if (section < (num_sections & ~0x1))
    {
        return 16 * (num_sections >> 2) + (section & 0x3);
    }
    else
    {
        return 16 * (num_sections >> 2) + 4 * (num_sections & 0x2);
    }
}


/// Calculate the index offset between coefficients of a second-order section.
/// See `iir_process()`.
///
/// \param section  The index of this section.
/// \param num_sections  The total number of sections.
/// \return  The index stride between this section's coefficients within a
///     `coeffs` array.

static inline int coeff_index_stride(int section, int num_sections)
{
    if (section < (num_sections & ~0x3))
    {
        return 4;
    }
    else if (section < (num_sections & ~0x1))
    {
        return 2;
    }
    else
    {
        return 1;
    }
}


/// The alignment required for the `state` and `coeffs` parameters passed to
/// `iir_process()`, for filters that have 4 or more sections.

const int IIR_ALIGN = 4 * sizeof(float);


/// For multichannel filters, return the size of the `state` memory allocated
/// for each channel, such that alignment can be guaranteed for all channels.
/// This allows the state memory for all of the channels to be allocated from
/// a single aligned array of size `num_channels * iir_state_size(num_sections)`.
///
/// \param num_sections  The number of second-order sections in the filter.
/// \return  `2 * num_sections`, rounded up to a multiple of 4.

int iir_state_size(int num_sections);


/// Process one frame of audio through an IIR filter.
///
/// The coefficients for all sections are normalized, with a1 and a2 being
/// divided by a0, and b1 and b2 divided by b0.  The gain `g` passed to this
/// function is the product of b0/a0 of all sections.
///
/// This function is optimized to use vector operations, and thus requires the
/// coefficients in `coeffs` to be stored in a particular order.
///
/// For each group of 4 sections, the coefficients are arranged as:
///
/// a1_1 a1_2 a1_3 a1_4 a2_1 a2_2 a2_3 a2_4 b1_1 b1_2 b1_3 b1_4 b2_1 b2_2 b2_3 b2_4
///
/// If `numSections % 4` is 2 or 3, the groups of 4 sections will be followed
/// by a group of 2 sections' coefficients arranged as:
///
/// a1_1 a1_2 a2_1 a2_2 b1_1 b1_2 b2_1 b2_2
///
/// Finally, if `numSections` is odd, these will be followed by the odd
/// section's coefficients:
///
/// a1 a2 b1 b2
///
/// Writing coefficients in the correct order can be facilitated using
/// `coeff_index_start()`, `coeff_index_stride()`, and `A1_INDEX`, etc.  For
/// example, to write the 4 coefficients to section `n`:
///
/// ~~~
/// start = coeff_index_start(n, num_sections);
/// stride = coeff_index_stride(n, num_sections);
/// coeffs[start + A1_INDEX * stride] = a1 / a0;
/// coeffs[start + A2_INDEX * stride] = a2 / a0;
/// coeffs[start + B1_INDEX * stride] = b1 / b0;
/// coeffs[start + B2_INDEX * stride] = b2 / b0;
/// g *= b0/a0;
/// ~~~
///
/// \param out  The array of output samples, of length `frame_size`.
/// \param in  The array of input samples, of length `frame_size`.
/// \param state  The filter's memory, of length 2 * `num_sections`.  This must
///    be unique for each signal to be filtered, and must be preserved between
///    calls.  This array must be aligned by `IIR_ALIGN` for filters of 4 or
///    more sections.
/// \param g  The overall gain of the filter (product of b0/a0 for each
///    section).
/// \param coeffs  The filter coefficients, of length 4 * `num_sections`.  This
///    array must be aligned by `IIR_ALIGN` for filters of 4 or more sections.
/// \param num_sections  The number of second-order sections in the filter.
/// \param frame_size  The number of samples to be processed.

void iir_process(float *out, const float *in, float * state, float g,
                 const float * coeffs, int num_sections,
                 int frame_size);


} // namespace filter
