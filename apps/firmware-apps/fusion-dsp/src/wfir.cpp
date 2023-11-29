// Warped FIR filtering

#include "arm_neon_defs.h"
#include "wfir.h"

#include <cmath>
#include <memory>
#include <cstring>

namespace filter {


void _WFirFilter::process(float *out, const float *in)
{
    float32x4_t sum_vec, coeff_vec, apf_out_vec;
    float *state_trav_ptr;
    const float *coeff_trav_ptr;
    float last_apf_out;
    for (int samp_idx{0}; samp_idx < get_frame_size(); ++samp_idx) {
        state_trav_ptr = _states.get();
        coeff_trav_ptr = _coeffs.get();
        last_apf_out = in[samp_idx];
        sum_vec = vdupq_n_f32(0.0f);
        for (int tap{0}; tap < _num_taps_optimize; tap += 4) {
            apf_out_vec = vsetq_lane_f32(last_apf_out, apf_out_vec, 0);
            apf_out_vec = vsetq_lane_f32(state_trav_ptr[0] + _lambda*
                vgetq_lane_f32(apf_out_vec, 0), apf_out_vec, 1);
            apf_out_vec = vsetq_lane_f32(state_trav_ptr[1] + _lambda*
                vgetq_lane_f32(apf_out_vec, 1), apf_out_vec, 2);
            apf_out_vec = vsetq_lane_f32(state_trav_ptr[2] + _lambda*
                vgetq_lane_f32(apf_out_vec, 2), apf_out_vec, 3);
            coeff_vec = vld1q_f32(&coeff_trav_ptr[0]);
            sum_vec = vmlaq_f32(sum_vec, apf_out_vec, coeff_vec);
            // use mla
            last_apf_out = state_trav_ptr[3] + _lambda*vgetq_lane_f32(apf_out_vec, 3);
            state_trav_ptr[0] = vgetq_lane_f32(apf_out_vec, 0) - _lambda*
                vgetq_lane_f32(apf_out_vec, 1);
            state_trav_ptr[1] = vgetq_lane_f32(apf_out_vec, 1) - _lambda*
                vgetq_lane_f32(apf_out_vec, 2);
            state_trav_ptr[2] = vgetq_lane_f32(apf_out_vec, 2) - _lambda*
                vgetq_lane_f32(apf_out_vec, 3);
            // use mla
            state_trav_ptr[3] = vgetq_lane_f32(apf_out_vec, 3) - _lambda*last_apf_out;
            state_trav_ptr += 4;
            coeff_trav_ptr += 4;
        }
        out[samp_idx] = vaddvq_f32(sum_vec);
    }
}

}