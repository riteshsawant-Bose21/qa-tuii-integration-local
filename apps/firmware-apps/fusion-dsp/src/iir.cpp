#include "arm_neon_defs.h"
#include "iir.h"
#include "iir_design.h"

#include <spdlog/spdlog.h>

#include <cmath>
#include <memory>


namespace filter {


// The order in which a second-order section's a1, etc.,  coefficients appear
// in the `coeffs` array.

static const int IIR_A1_INDEX = 0;
static const int IIR_A2_INDEX = 1;
static const int IIR_B1_INDEX = 2;
static const int IIR_B2_INDEX = 3;


// The alignment required for the `state` and `coeffs` parameters passed to
// `process()`, for filters that have 4 or more sections.

static const int IIR_ALIGN = 4 * sizeof(float);


// These functions help with coefficient and state indexing, working with
// the alignment constraints for NEON optimized vector instructions.

static int iir_state_size(int num_sections);
static int iir_coeff_index_start(int section, int num_sections);
static int iir_coeff_index_stride(int section, int num_sections);


// iir_{1,2,4} each implement 1, 2 or 4 stages of direct-form 2 transposed
// biquads.  When compiling for a non-ARM-NEON target, fake versions of the ARM
// intrinsics will be used, so that the same main code is executed.  When
// compiling for LCC, alternative implementations of the iir_x functions are
// used to make up for deficiencies in the compiler.
//
// Each function implements a Direct Form II-Transposed biquad, using the
// following equations:
//
//  y[n]  = v1[n-1] + b0*x[n]
//  v1[n] = b1*x[n] - a1*y[n] + v2[n-1]
//  v2[n] = b2*x[n] - a2*y[n]
//
// All of the gains are combined into a single gain, which is only applied
// during the first stage.

static void iir_1(const float * coeffs, float * state,
                  const float *in, float *out, int frame_size, float g);
static void iir_2(const float * coeffs, float * state,
                  const float *in, float *out, int frame_size, float g);
static void iir_4(const float * coeffs, float * state,
                  const float *in, float *out, int frame_size, float g);


IirFilter::IirFilter(int num_sections, int num_channels)
    : num_sections(num_sections),
      num_channels(num_channels),
      state_size(iir_state_size(num_sections)),
      total_gain(1.0f)
{
    state = std::unique_ptr<float[]>(new (std::align_val_t(IIR_ALIGN))
                                             float[num_channels * state_size]());
    coeff = std::unique_ptr<float[]>(new (std::align_val_t(IIR_ALIGN))
                                             float[4 * num_sections]());

    section_gain.resize(num_sections);

    for (auto &g : section_gain)
    {
        g = 1.0f;
    }

    int err;
    pthread_mutexattr_t mutex_attr;

    err = pthread_mutexattr_init(&mutex_attr);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_mutexattr_init: {}", strerror(err));
    }

    err = pthread_mutexattr_setprotocol(&mutex_attr, PTHREAD_PRIO_INHERIT);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_mutexattr_setprotocol: {}", strerror(err));
    }

    err = pthread_mutex_init(&mutex, &mutex_attr);

    if (err != 0)
    {
        SPDLOG_CRITICAL("pthread_mutex_init: {}", strerror(err));
    }
}


void IirFilter::design_band(const std::string &method, int section,
                            float frequency, float q, float gain_db,
                            float sample_rate)
{
    filter::IirDesignBand *design_band =
        bosepro::ObjectRegistry<filter::IirDesignBand>::get_object(method);
    filter::IirDesignBandFunc design_func = design_band->get_function();
    design_func(this, section, frequency, q, gain_db, sample_rate);
}


void IirFilter::design(const std::string &method, int start_section,
                       float frequency, int order, float sample_rate,
                       int max_sections)
{
    filter::IirDesign *iir_design =
            bosepro::ObjectRegistry<filter::IirDesign>::get_object(method);
    filter::IirDesignFunc design_func = iir_design->get_function();
    design_func(this, start_section, frequency, order, sample_rate,
                max_sections);
}


void IirFilter::set_section_coeffs(int section, double b0, double b1, double b2,
                                   double a0, double a1, double a2)
{
    int index_start = iir_coeff_index_start(section, num_sections);
    int index_stride = iir_coeff_index_stride(section, num_sections);

    b1 /= b0;
    b2 /= b0;
    a1 /= a0;
    a2 /= a0;

    section_gain[section] = b0 / a0;

    float tmp_gain = 1.0f;

    for (auto g : section_gain)
    {
        tmp_gain *= g;
    }

    pthread_mutex_lock(&mutex);

    total_gain = tmp_gain;

    coeff[index_start + IIR_B1_INDEX * index_stride] = b1;
    coeff[index_start + IIR_B2_INDEX * index_stride] = b2;
    coeff[index_start + IIR_A1_INDEX * index_stride] = a1;
    coeff[index_start + IIR_A2_INDEX * index_stride] = a2;

    pthread_mutex_unlock(&mutex);
}


// Process one frame of audio through an IIR filter.
//
// The coefficients for all sections are normalized, with a1 and a2 being
// divided by a0, and b1 and b2 divided by b0.  The gain `g` passed to this
// function is the product of b0/a0 of all sections.
//
// This function is optimized to use vector operations, and thus requires the
// coefficients in `coeff` to be stored in a particular order.
//
// For each group of 4 sections, the coefficients are arranged as:
//
// a1_1 a1_2 a1_3 a1_4 a2_1 ... a2_4 b1_1 ... b1_4 b2_1 ... b2_4
//
// If `num_sections % 4` is 2 or 3, the groups of 4 sections will be followed
// by a group of 2 sections' coefficients arranged as:
//
// a1_1 a1_2 a2_1 a2_2 b1_1 b1_2 b2_1 b2_2
//
// Finally, if `num_sections` is odd, these will be followed by the odd
// section's coefficients:
//
// a1 a2 b1 b2
//
// Writing coefficients in the correct order can be facilitated using
// `iir_coeff_index_start()`, `iir_coeff_index_stride()`, and `IIR_A1_INDEX`,
// etc. For example, to write the 4 coefficients to section `n`:
//
// ~~~
// start = iir_coeff_index_start(n, num_sections);
// stride = iir_coeff_index_stride(n, num_sections);
// coeff[start + IIR_A1_INDEX * stride] = a1 / a0;
// coeff[start + IIR_A2_INDEX * stride] = a2 / a0;
// coeff[start + IIR_B1_INDEX * stride] = b1 / b0;
// coeff[start + IIR_B2_INDEX * stride] = b2 / b0;
// g *= b0/a0;
// ~~~
//
// \param out  The array of output samples, of length `frame_size`.
// \param in  The array of input samples, of length `frame_size`.
// \param channel  The index of the channel to be processed.
// \param frame_size  The number of samples to be processed.

void IirFilter::process_impl(float *out, const float *in, int channel,
                             int frame_size)
{
    const float *x = in;
    float *p_coeff = coeff.get();
    float *p_state = &state[channel * state_size];
    float g = total_gain;
    int remaining_sections = num_sections;

    pthread_mutex_lock(&mutex);

    while (remaining_sections)
    {
        if (remaining_sections >= 4)
        {
            iir_4(p_coeff, p_state, x, out, frame_size, g);

            remaining_sections  -= 4;
            p_coeff       += 16;
            p_state       += 8;
        }
        else if (num_sections >= 2)
        {
            iir_2(p_coeff, p_state, x, out, frame_size, g);

            remaining_sections  -= 2;
            p_coeff       += 8;
            p_state       += 4;
        }
        else
        {
            iir_1(p_coeff, p_state, x, out, frame_size, g);

            remaining_sections  -= 1;
            p_coeff       += 4;
            p_state       += 2;
        }

        // Only apply the gain, g, during the first set of sections.
        g = 1.0f;

        // After processing the input for the first stage, the remaining
        // stages are done in place.
        x = out;
    }

    pthread_mutex_unlock(&mutex);
}


// For multichannel filters, return the size of the `state` memory allocated
// for each channel, such that alignment can be guaranteed for all channels.
// This allows the state memory for all of the channels to be allocated from
// a single aligned array of size `num_channels * iir_state_size(num_sections)`.
//
// \param num_sections  The number of second-order sections in the filter.
// \return  `2 * num_sections`, rounded up to a multiple of 4.

static int iir_state_size(int num_sections)
{
    return ((num_sections & 1) != 0) ? 2 * num_sections + 2 : 2 * num_sections;
}


// Calculate the index of the first (a1) coefficient for a second-order
// section. See `iir_process_impl()`.
//
// \param section  The index of this section.
// \param num_sections  The total number of sections.
// \return  The index of this section's a1 coefficient within a `coeff` array.

static int iir_coeff_index_start(int section, int num_sections)
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


// Calculate the index offset between coefficients of a second-order section.
// See `iir_process_impl()`.
//
// \param section  The index of this section.
// \param num_sections  The total number of sections.
// \return  The index stride between this section's coefficients within a
//     `coeff` array.

static inline int iir_coeff_index_stride(int section, int num_sections)
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


// Process one second-order section.  No SIMD, but at least try to use
// optimized multiply-accumulate.

static void iir_1(const float * coeffs, float * state,
                  const float *in, float *out, int frame_size, float g)
{
    float a1 = coeffs[IIR_A1_INDEX];
    float a2 = coeffs[IIR_A2_INDEX];
    float b1 = coeffs[IIR_B1_INDEX];
    float b2 = coeffs[IIR_B2_INDEX];

    float v1 = state[0];
    float v2 = state[1];

    for (int i = 0; i < frame_size; i++)
    {
        float x = g * in[i];
        float y = v1 + x;
        out[i] = y;

        #ifdef FP_FAST_FMA
        // v1 = b1*x - a1*y + v2;
        v1 = fmaf(b1,  x, v2);
        v1 = fmaf(-a1, y, v1);

        // v2 = b2*x - a2*y;
        v2 = fmaf(b2, x, -a2*y);
        #else
        v1 = b1*x - a1*y + v2;
        v2 = b2*x - a2*y;
        #endif
    }

    state[0] = v1;
    state[1] = v2;
}


// Process 2 second-order sections with 2x SIMD using ARM NEON intrinsics (or
// equivalent portable code on other platforms).

static void iir_2(const float * coeffs, float * state,
                  const float *in, float *out, int frame_size, float g)
{
    const float32x2_t gain = vdup_n_f32(g);

    // Load coefficients for all 2 stages.  Coeffs are in the following order:
    //
    //  stage1_a1, stage2_a1,
    //  stage1_a2, stage2_a2,
    //  stage1_b1, stage2_b1,
    //  stage1_b2, stage2_b2

    const float32x2_t a1 = vld1_f32(&coeffs[2 * IIR_A1_INDEX]);
    const float32x2_t a2 = vld1_f32(&coeffs[2 * IIR_A2_INDEX]);
    const float32x2_t b1 = vld1_f32(&coeffs[2 * IIR_B1_INDEX]);
    const float32x2_t b2 = vld1_f32(&coeffs[2 * IIR_B2_INDEX]);

    // Load states for all 2 stages.  States are in the following order:
    //
    // stage1_v1, stage2_v1,
    // stage1_v2, stage2_v2

    float32x2_t v1 = vld1_f32(&state[0]);
    float32x2_t v2 = vld1_f32(&state[2]);

    const float32x2_t c01 = { 0.0f, 1.0f };

    for (int i = 0; i < frame_size; i++)
    {
        // Calculate { x1, x2 } == { x1, y1 } and { y1, y2 }
        //  y1 = v11 + x1;
        //  y2 = v21 + y1;

        float32x2_t inputs = vmul_n_f32(gain, in[i]);
        inputs = vmla_f32(inputs, vdup_n_f32(vget_lane_f32(v1, 0)), c01);

        float32x2_t outputs = vadd_f32(v1,  inputs);

        out[i] = vget_lane_f32(outputs, 1);

        // Update v1 for each stage.
        //  v11 = b11*x1 - a11*y1 + v12;
        //  v21 = b21*y1 - a21*y2 + v22;

        v1 = vadd_f32(
                 vsub_f32(
                     vmul_f32(b1, inputs),
                     vmul_f32(a1, outputs)),
                 v2);

        // Update v2 for each stage.
        //  v12 = b12*x1 - a12*y1;
        //  v22 = b22*y1 - a22*y2;

        v2 = vsub_f32(
                 vmul_f32(b2, inputs),
                 vmul_f32(a2, outputs));
    }

    vst1_f32(&state[0], v1);
    vst1_f32(&state[2], v2);
}


// Process 4 second-order sections with 4x SIMD using ARM NEON intrinsics (or
// equivalent portable code on other platforms).

static void iir_4(const float * coeffs, float * state,
                  const float *in, float *out, int frame_size, float g)
{
    // Load coefficients for all 4 stages.  Coeffs are in the following order:
    //
    //  stage1_a1, stage2_a1, stage3_a1, stage4_a1,
    //  stage1_a2, stage2_a2, stage3_a2, stage4_a2,
    //  stage1_b1, stage2_b1, stage3_b1, stage4_b1,
    //  stage1_b2, stage2_b2, stage3_b2, stage4_b2

    const float32x4_t a1 = vld1q_f32(&coeffs[4 * IIR_A1_INDEX]);
    const float32x4_t a2 = vld1q_f32(&coeffs[4 * IIR_A2_INDEX]);
    const float32x4_t b1 = vld1q_f32(&coeffs[4 * IIR_B1_INDEX]);
    const float32x4_t b2 = vld1q_f32(&coeffs[4 * IIR_B2_INDEX]);


    // Load states for all 4 stages.  States are in the following order:
    //
    // stage1_v1, stage2_v1, stage3_v1, stage4_v1,
    // stage1_v2, stage2_v2, stage3_v2, stage4_v2

    float32x4_t v1 = vld1q_f32(&state[0]);
    float32x4_t v2 = vld1q_f32(&state[4]);

    // These constants will be used to calculate stage inputs in-place.
    const float32x4_t c0111 = { 0.0f, 1.0f, 1.0f, 1.0f };
    const float32x4_t c0011 = { 0.0f, 0.0f, 1.0f, 1.0f };
    const float32x4_t c0001 = { 0.0f, 0.0f, 0.0f, 1.0f };

    for (int i = 0; i < frame_size; i++)
    {
        // Create vector of stage inputs { x1, x2, x3, x4 } in place to avoid
        // memory moves later.
        //  x1[n] = x1[n]  =                                       x1
        //  x2[n] = y1[n]  = v11[n-1] + x1[n] =              v11 + x1
        //  x3[n] = y2[n]  = v21[n-1] + y1[n] =        v21 + v11 + x1
        //  x4[n] = y3[n]  = v31[n-1] + y2[n] =  v31 + v21 + v11 + x1

        float32x4_t inputs = vdupq_n_f32(g * in[i]);
        inputs = vmlaq_f32(inputs, vdupq_n_f32(vgetq_lane_f32(v1, 0)), c0111);
        inputs = vmlaq_f32(inputs, vdupq_n_f32(vgetq_lane_f32(v1, 1)), c0011);
        inputs = vmlaq_f32(inputs, vdupq_n_f32(vgetq_lane_f32(v1, 2)), c0001);

        // We also need { y1, y2, y3, y4 } for the output and state updates.
        //  y1[n]  = v11[n-1] + x1[n]
        //  y2[n]  = v21[n-1] + y1[n]
        //  y3[n]  = v31[n-1] + y2[n]
        //  y4[n]  = v41[n-1] + y3[n]

        float32x4_t outputs = vaddq_f32(inputs, v1);

        // Output is in the last lane of the above.
        out[i] = vgetq_lane_f32(outputs, 3);

        // Update v1 for each stage.
        //  v11[n] = b11*x1[n] - a11*y1[n] + v12[n-1]
        //  v21[n] = b21*x2[n] - a21*y2[n] + v22[n-1]
        //  v31[n] = b31*x3[n] - a31*y3[n] + v32[n-1]
        //  v41[n] = b41*x4[n] - a41*y4[n] + v42[n-1]

        v1 = vaddq_f32(
                 vsubq_f32(
                     vmulq_f32(b1, inputs),
                     vmulq_f32(a1, outputs)),
                 v2);

        // Update v2 for each stage.
        //  v12[n] = b12*x1[n] - a12*y1[n]
        //  v22[n] = b22*x2[n] - a22*y2[n]
        //  v32[n] = b32*x3[n] - a32*y3[n]
        //  v42[n] = b42*x4[n] - a42*y4[n]

        v2 = vsubq_f32(
                 vmulq_f32(b2, inputs),
                 vmulq_f32(a2, outputs));
    }

    vst1q_f32(&state[0], v1);
    vst1q_f32(&state[4], v2);
}


} // namespace filter
