// parameters and structs for the PercepNet algorithm
#pragma once
#include <onnxruntime_c_api.h>


#define SQUARE(x) ((x) * (x))
#define ORT_ABORT_ON_ERROR(expr)								\
	do 															\
	{     														\
		OrtStatus* onnx_status = (expr);			     		\
		if (onnx_status != nullptr) {                             	\
			const char* msg = O->GetErrorMessage(onnx_status);	\
			fprintf(stderr, "ONNX: %s\n", msg);		     		\
			O->ReleaseStatus(onnx_status);                    	\
			abort();                                           	\
		}                                                      	\
	} while (0);
	
// for frequency band analysis
const int FRAME_SIZE = 480;
const int WINDOW_SIZE = 2 * FRAME_SIZE;
const int FREQ_SIZE = FRAME_SIZE + 1;
const int NB_BANDS = 34;
const int NB_FEATURES_IN = NB_BANDS * 2 + 2;
const int NB_TARGETS = NB_BANDS * 2;
const int NB_FEATURES = NB_FEATURES_IN + NB_TARGETS;

// for pitch analysis and filtering
const int PITCH_MIN_PERIOD = 60;
const int PITCH_MAX_PERIOD = 768;
const int PITCH_FRAME_SIZE = 960;
const int PITCH_BUF_SIZE = PITCH_MAX_PERIOD + PITCH_FRAME_SIZE;
// Maximum number of frames allowed in the lookahead buffer
const int MAX_LOOKAHEAD = 3;
const int COMB_M = 1;
const int FRAME_LOOKAHEAD = 0; // round(PITCH_MAX_PERIOD*COMB_M/WINDOW_SIZE + 0.5)
const int FRAME_LOOKAHEAD_SIZE = (FRAME_LOOKAHEAD * FRAME_SIZE);
const int COMB_BUF_SIZE = (WINDOW_SIZE + PITCH_FRAME_SIZE);
const int USE_COMB_FILTER = 1;

// for accessing features
const int FEAT_MAG_Y = 0;
const int FEAT_PITCH_COHERENCE = FEAT_MAG_Y + NB_BANDS;
const int FEAT_PITCH_PERIOD = FEAT_PITCH_COHERENCE + NB_BANDS;
const int FEAT_PITCH_CORRELATION = FEAT_PITCH_PERIOD + 1;
const int FEAT_GAIN = FEAT_PITCH_CORRELATION + 1;
const int FEAT_STRENGTH = FEAT_GAIN + NB_BANDS;

// post-filtering parameter
const float ENVELOPE_POSTFILTERING_BETA = 0.02f;

// Limit the analysis to 16 kHz audio
// Use maximum resolution below 450 Hz and then MEL spacing
// Mel frequencies assuming 34-8 bands.  Band 0 (DC) is merged
// with band 1, ideal upper bound distribution starting from band 9:
/*
[  	450.           579.54005501   709.08011002   838.62016503
	968.16022005   1106.00675809  1264.08387321  1444.75431711
	1651.24726377  1887.25342005  2156.99099078  2465.28107189
	2817.63381923  3220.34693319  3680.61821919  4206.67423619
	4807.91733225  5495.09369536  6280.48542313  7178.13004417
	8204.07141479  9376.64647546 10716.81299205 12248.52413997
 13999.15662601 16000.        ]
*/

// Actual band frequency upper bound distribution used becuase of the 
// 50Hz bin resolution restriction, starting from band 9
/*
	450,            550,            700,            800, 
	950,            1100,           1250,           1400,
	1650,           1850,           2150,           2450,
	2800,           3200,           3650,           4200,
	4800,           5450,           6250,           7150,
	8200,           9350,           10700,          12200,
	13950,          15950
*/
static const short eband5ms[] = 
{
	1,   2,   3,   4,   5,   6,  7,   8,
	9,  11,  14,  16,  19,  22,  25,  28,  33,  37,  43,  49,  56,  64,  73,  84,  96, 109,
	125, 143, 164, 187, 214, 244, 279, 319,
};

// fft band where 16khz ends
const int LAST_BAND = 320; 

// fft data
typedef struct 
{
	float r;
	float i;
} fft_cpx;

// for fft windowing
typedef struct
{
	int init;
	float half_window[FRAME_SIZE];
	float comb_hann_window[COMB_M * 2 + 1];
} CommonState;

// states for frame processing
struct DenoiseState
{
	float analysis_mem[FRAME_SIZE];
	float synthesis_mem[FRAME_SIZE];
	float pitch_buf[PITCH_BUF_SIZE];
	float comb_buf[COMB_BUF_SIZE];
	float pitch_enh_buf[PITCH_BUF_SIZE];
	float last_gain;
	int last_period;
	float pitch_corr;
	float lastg[NB_BANDS];
	// for frame skipping
	float g_pre[NB_BANDS]; 
	float r_pre[NB_BANDS];
	float g_app[NB_BANDS];
	float r_app[NB_BANDS];
	fft_cpx lastE[FREQ_SIZE]; // last frame's output clean FFT bands
	fft_cpx noisyE[FREQ_SIZE]; // this frame's input noisy FFT bands
	const char* onnx;
};



