#pragma once

#include "rnnoise.h"
#include "kiss_fft.h"
#include "denoise.h"

extern const float rnn_dct_table[];
extern const kiss_fft_state rnn_kfft;
extern const float rnn_half_window[];