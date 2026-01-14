#include <math.h>
#include "opus_types.h"
#include "common.h"
#include "arch_rnnoise.h"
#include "rnn.h"
#include "rnnoise_data.h"

#define INPUT_SIZE 65  /* keep if still true for your feature vector */

void compute_rnn(const RNNoise *model, RNNState *rnn,
                 float *gains, float *vad,
                 const float *input, int arch)
{
  float proj[MAX_NEURONS];
  float cat[FC_FEAT_OUT_SIZE + GRU1_OUT_SIZE + GRU2_OUT_SIZE + GRU3_OUT_SIZE];

  /* Front-end dense projection */
  compute_generic_dense(&model->fc_feat, proj, input, ACTIVATION_TANH, arch);

  /* Recurrent stack */
  compute_generic_gru(&model->gru1_input, &model->gru1_recurrent,
                      rnn->gru1_state, proj, arch);
  compute_generic_gru(&model->gru2_input, &model->gru2_recurrent,
                      rnn->gru2_state, rnn->gru1_state, arch);
  compute_generic_gru(&model->gru3_input, &model->gru3_recurrent,
                      rnn->gru3_state, rnn->gru2_state, arch);

  /* Concatenate proj + GRU outputs */
  RNN_COPY(cat, proj, FC_FEAT_OUT_SIZE);
  RNN_COPY(&cat[FC_FEAT_OUT_SIZE], rnn->gru1_state, GRU1_OUT_SIZE);
  RNN_COPY(&cat[FC_FEAT_OUT_SIZE + GRU1_OUT_SIZE], rnn->gru2_state, GRU2_OUT_SIZE);
  RNN_COPY(&cat[FC_FEAT_OUT_SIZE + GRU1_OUT_SIZE + GRU2_OUT_SIZE],
           rnn->gru3_state, GRU3_OUT_SIZE);

  /* Heads */
  compute_generic_dense(&model->dense_out, gains, cat, ACTIVATION_SIGMOID, arch);
  compute_generic_dense(&model->vad_dense, vad, cat, ACTIVATION_SIGMOID, arch);
}