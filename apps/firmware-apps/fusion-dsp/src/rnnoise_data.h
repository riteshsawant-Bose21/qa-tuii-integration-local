
#ifndef RNNOISE_DATA_H
#define RNNOISE_DATA_H

#include "nnet.h"


#define FC_FEAT_OUT_SIZE 64

#define GRU1_OUT_SIZE 64

#define GRU1_STATE_SIZE 64

#define GRU2_OUT_SIZE 32

#define GRU2_STATE_SIZE 32

#define GRU3_OUT_SIZE 64

#define GRU3_STATE_SIZE 64

#define DENSE_OUT_OUT_SIZE 32

#define VAD_DENSE_OUT_SIZE 1

typedef struct {
    LinearLayer fc_feat;
    LinearLayer gru1_input;
    LinearLayer gru1_recurrent;
    LinearLayer gru2_input;
    LinearLayer gru2_recurrent;
    LinearLayer gru3_input;
    LinearLayer gru3_recurrent;
    LinearLayer dense_out;
    LinearLayer vad_dense;
} RNNoise;

int init_rnnoise(RNNoise *model, const WeightArray *arrays);

extern const WeightArray rnnoise_arrays[];

#endif /* RNNOISE_DATA_H */
