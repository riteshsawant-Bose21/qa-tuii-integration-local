//
// _fir.cpp
// FIR filtering optimized for ARM targets using NEON vector intrinsics.
//
// Ben Overzat, May 2020
//
//

#include "arm_neon_defs.h"
#include "fir.h"

#include <cmath>
#include <memory>
#include <cstring>

namespace filter
{

// DESCRIPTION HERE

FirFilter::FirFilter(int num_taps, int_fast32_t frame_size, int_fast32_t sample_rate)
    : FirFilterBase{num_taps, frame_size, sample_rate}
{
    // pad state and coeffs so length of coeffs is multiple of 4
    _num_taps_optimize = show_num_taps() + 3 - ((show_num_taps()+3) % 4);

    _states = std::unique_ptr<float[]>(new (std::align_val_t(4 * sizeof(float))) float[_num_taps_optimize]());
    _coeffs = std::unique_ptr<float[]>(new (std::align_val_t(4 * sizeof(float))) float[_num_taps_optimize]());

    memset(_states.get(), 0, _num_taps_optimize * sizeof(float));
    memset(_coeffs.get(), 0, _num_taps_optimize * sizeof(float));
}

FirFilterBase *
FirFilter::with_coefficients(const float *coeffs)
{
    memcpy(_coeffs.get(), coeffs, show_num_taps() * sizeof(float));
    return this;
}

void FirFilter::process(float *out, const float *in)
{
    float32x4_t sum_vec, coeff_vec;
    float *state_trav_ptr;
    const float *coeff_trav_ptr;
    float last_state;
    for (int samp_idx{0}; samp_idx < get_frame_size(); ++samp_idx) {
        state_trav_ptr = _states.get();
        coeff_trav_ptr = _coeffs.get();
        last_state = in[samp_idx];
        sum_vec = vdupq_n_f32(0.0f);
        for (int tap{0}; tap < _num_taps_optimize; tap += 4)
        {
            float32x4_t state_vec{ last_state, state_trav_ptr[0], 
                state_trav_ptr[1], state_trav_ptr[2] };
            coeff_vec = vld1q_f32(&coeff_trav_ptr[0]);
            sum_vec = vmlaq_f32(sum_vec, state_vec, coeff_vec);
            last_state = state_trav_ptr[3];
            vst1q_f32(&state_trav_ptr[0], state_vec);
            state_trav_ptr += 4;
            coeff_trav_ptr += 4;
        }
        out[samp_idx] = vaddvq_f32(sum_vec);
    }
}

}

// end of file
