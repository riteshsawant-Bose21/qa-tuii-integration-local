#ifndef RNN_H_
#define RNN_H_

#include "rnnoise.h"
#include "rnnoise_data.h"
#include "opus_types.h"

#define WEIGHTS_SCALE (1.f/256)
#define MAX_NEURONS 1024

typedef struct {
  /* No conv states in lightweight architecture */
  float gru1_state[GRU1_STATE_SIZE];
  float gru2_state[GRU2_STATE_SIZE];
  float gru3_state[GRU3_STATE_SIZE];
} RNNState;

/* arch parameter can be ignored (or keep if you support both) */
void compute_rnn(const RNNoise *model, RNNState *rnn,
                 float *gains, float *vad,
                 const float *input, int arch);

#endif /* RNN_H_ */
