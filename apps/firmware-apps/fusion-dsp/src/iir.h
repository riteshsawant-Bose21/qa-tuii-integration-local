#pragma once

#include <pthread.h>

#include <memory>
#include <string>
#include <vector>

namespace filter {


/// An IIR filter that supports multiple second-order sections and multiple
/// channels.  The same filter is applied to each channel.
///
/// The filter coefficients can be set either directly (using
/// `set_section_coeffs()`), or by using one of the design methods
/// (`design_band()` or `design()`).
class IirFilter
{
public:
    /// Create a multi-channel filter.
    ///
    /// \param  num_sections  The number of second-order sections in the filter.
    /// \param  num_channels  The number of channels in the filter.
    IirFilter(int num_sections, int num_channels);


    /// Create a single-channel filter.
    ///
    /// \param  num_sections  The number of second-order sections in the filter.
    IirFilter(int num_sections) : IirFilter(num_sections, 1) {}


    /// Process one frame of audio, for single-channel filters.
    ///
    /// \param  out  The array of output samples, of length `frame_size`.
    /// \param  in  The array of input samples, of length `frame_size`.
    /// \param  frame_size  The number of samples to be processed.
    void process(float *out, const float *in, int frame_size)
    {
        process_impl(out, in, 0, frame_size);
    }


    /// Process one frame of audio, for multi-channel filters.  This applies
    /// the same filter to each channel.
    ///
    /// \param  out  A 2-D array of output samples, `num_channels` by
    ///             `frame_size`.
    /// \param  in  A 2-D array of input samples, `num_channels` by
    ///            `frame_size`.
    /// \param  frame_size  The number of samples to be processed.
    void process(float **out, const float **in, int frame_size)
    {
        for (int channel = 0; channel < num_channels; ++channel)
        {
            process_impl(out[channel], in[channel], channel, frame_size);
        }
    }


    /// Design a filter that requires a single second-order section, such as
    /// a peaking EQ or high shelf.
    ///
    /// \param  method  The name of the design method to use, such as "peq_cs".
    /// \param  section  The index of the section to design.
    /// \param  frequency  The center/cutoff frequency of the filter, in Hz.
    /// \param  q  The Q factor of the filter.
    /// \param  gain_db  The gain of the filter, in dB.
    /// \param  sample_rate  The sample rate of the system, in Hz.
    void design_band(const std::string &method, int section, float frequency,
                     float q, float gain_db, float sample_rate);


    /// Design a filter that requires multiple second-order sections, such as
    /// a Linkwitz-Riley LPF or HPF.
    ///
    /// \param  method  The name of the design method to use, such as
    ///     "butterworth".
    /// \param  start_section  The index of the first section allocated to this
    ///     filter.
    /// \param  frequency  The center/cutoff frequency of the filter, in Hz.
    /// \param  order  The order of the filter.
    /// \param  sample_rate  The sample rate of the system, in Hz.
    /// \param  max_sections  The maximum number of sections that can be
    ///    allocated to this filter.
    void design(const std::string &method, int start_section, float frequency,
                int order, float sample_rate, int max_sections);


    /// Set the coefficients of a second-order section.  The coefficients are
    /// internally normalized so that a0 and b0 are always 1.0, and the gain
    /// of the section is stored separately (to be combined with the gain of
    /// the other sections).
    ///
    /// \param  section  The index of the section to set.
    /// \param  b0  The numerator coefficient of the z^0 term.
    /// \param  b1  The numerator coefficient of the z^-1 term.
    /// \param  b2  The numerator coefficient of the z^-2 term.
    /// \param  a0  The denominator coefficient of the z^0 term.
    /// \param  a1  The denominator coefficient of the z^-1 term.
    /// \param  a2  The denominator coefficient of the z^-2 term.
    void set_section_coeffs(int section, double b0, double b1, double b2,
                            double a0, double a1, double a2);


private:
    int num_sections;
    int num_channels;
    int state_size;
    std::unique_ptr<float[]> coeff;
    std::unique_ptr<float[]> state;
    std::vector<float> section_gain;
    float total_gain;
    pthread_mutex_t mutex;

    void process_impl(float *out, const float *in, int channel, int frame_size);
};


} // namespace filter
