// PercepNet - speech enhancement
//
// Speech enhancement using DNN and comb
// filtering
//
// A frame size of 480 with 48kHz sampling frequency
// is assumed by the pre-trained model. onnxruntime
// is used for model inference.
//
// algorithm related files used
// - percepnet.h
// - pitch.c/.h
// - fft.h
// other files 
// - celt_lpc.c/.h
// - arch.h
// - opus_types.h

#include "percepnet.h"
#include "pitch.h"
#include "fft.h"


namespace {


class PercepNet : public bosepro::Algorithm
{
public:
	PercepNet(const bosepro::BlockConfiguration &configuration);
	virtual ~PercepNet() = default;

	virtual void process() override;

private:
	// --- constants and terminals ---
	int_fast32_t channels;

	bosepro::DspSignalMemory<const float *[]> in;
	bosepro::DspSignalMemory<float *[]> out;
	
	// --- user properties ---
	// onnx model path, default is percepnet.onnx
	std::string model_path;
	// if use frame skipping to save computation,
	// need to change model_path to corresponding model
	// too if doing frame skipping 
	int_fast32_t skip_frame;
	// if use comb filtered output directly for gain application
	int_fast32_t ignore_strengths = 0;

	// --- processing variables ---

	// frame processing states
	DenoiseState * st;
	CommonState common;

	// for frame processing
	int frame_in;
	int frame_out;
	// if skipping this frame's processing (to save computation)
	// 0 means need to compute new gains (but apply previous gains), 
	// 1 means need to update gains to apply (but don't compute new gains)
	int skip_switch;

	// fft analysis
	fft_cpx X[MAX_LOOKAHEAD][FREQ_SIZE];
	fft_cpx P[MAX_LOOKAHEAD][WINDOW_SIZE];
	std::unique_ptr<fft::Fft> curr_fft;
	float Ex[MAX_LOOKAHEAD][NB_BANDS];
	float Ep[MAX_LOOKAHEAD][NB_BANDS];
	float Exp[MAX_LOOKAHEAD][NB_BANDS];

	// onnxruntime related
	const OrtApi *O = nullptr;
	OrtSessionOptions *session_options;
	OrtSession *session;
	OrtAllocator *ort_alloc;
	OrtEnv* env;
	size_t nin;
	size_t nout;
	size_t *input_tensor_size;
	size_t *output_tensor_size;
	char **input_names;
	char **output_names;
	OrtValue **input_tensor;
	OrtValue **output_tensor;

	// --- processing functions ---
	void rnnoise_create(const char *onnx);
	void check_init();
	void apply_window(float *x);
	void forward_transform(fft_cpx *output, const float *input);
	void frame_analysis(DenoiseState *st, fft_cpx *X, float *Ex, const float *input);
	void compute_band_energy(float *band_e, const fft_cpx *X);
	void compute_band_corr(float *band_e, const fft_cpx *X, const fft_cpx *P);
	int compute_frame_features(DenoiseState *st, fft_cpx *X, fft_cpx *P,
		float *Ex, float *Ep, float *Exp, float *features, const float *input);
	void post_filtering(float *g, const float *Ey);
	void smooth_gains(DenoiseState *st, float *g);
	void interp_band_gain(float *g, const float *band_e);
	void apply_gains(fft_cpx *X, float *mel_gains);
	void apply_limiter(float *x);
	void inverse_transform(float *output, const fft_cpx *input);
	void frame_synthesis(DenoiseState *st, float *output, const fft_cpx *y);
	void apply_comb_filter(DenoiseState *st, int pitch_index, const float *input, float *output);
	void pitch_filter(fft_cpx *X, const fft_cpx *P, const float *r);
	void compute_onnx(const char *onnx, float *gains, float *rb_gains, const float *input);
	void rnnoise_process_frame(DenoiseState *st, float *output, const float *input, int pf, 
		int post, int lookahead, int frame_skip);

	// --- user parameter processing functions ---
	void update_model();

	ALGORITHM_DECLARE(PercepNet);
};

ALGORITHM_REGISTER(PercepNet, "percepnet");


PercepNet::PercepNet(const bosepro::BlockConfiguration &configuration)
	: bosepro::Algorithm(configuration)
{
	get_property("channels", channels);

	assign_terminal("in", in);
	assign_terminal("out", out);

	assign_parameter("model_path", &model_path,
                     POST_FUNCTION_SCALAR(update_model));
	assign_parameter("skip_frame", &skip_frame);
	assign_parameter("ignore_pf_strength", &ignore_strengths);

	rnnoise_create(model_path.c_str());

	// right now only works when frame_size = FRAME_SIZE = 480,
	// print error if frame_size is different
	if (get_frame_size() != FRAME_SIZE)
		SPDLOG_ERROR("frame size for the percepnet model can only be 480");

	curr_fft = std::make_unique<fft::Fft>(WINDOW_SIZE);
	
	frame_in = -1;
	frame_out = -1;
}


void PercepNet::update_model()
{
	st->onnx = model_path.c_str();
}


// set up frame processing states
// and the onnx model
void PercepNet::rnnoise_create(const char *onnx)
{
	st = (DenoiseState *)malloc(sizeof(DenoiseState));
	memset(st, 0, sizeof(DenoiseState));
	st->onnx = onnx;
}


// check if windows are initialized
// if not, initialize them
void PercepNet::check_init()
{
	int i;
	float temp_sum = 0;

	if (common.init)
		return;

	for (i = 0; i < FRAME_SIZE; i++)
		common.half_window[i] = sin(.5 * M_PI * sin(.5 * M_PI * (i + .5) / FRAME_SIZE) * sin(.5 * M_PI * (i + .5) / FRAME_SIZE));

	for (i = 1; i < COMB_M * 2 + 2; i++)
	{
		common.comb_hann_window[i - 1] = 0.5 - 0.5 * cos(2.0 * M_PI * i / (COMB_M * 2 + 2));
		temp_sum += common.comb_hann_window[i - 1];
	}
	for (i = 1; i < COMB_M * 2 + 2; i++)
	{
		common.comb_hann_window[i - 1] /= temp_sum;
	}
	common.init = 1;
}


/**
 * @brief Applies a Half Window to the given frame
 *
 * @param x: Input signal of size WINDOW_SIZE
 */
void PercepNet::apply_window(float *x)
{
	int i;
	check_init();
	for (i = 0; i < FRAME_SIZE; i++)
	{
		x[i] *= common.half_window[i];
		x[WINDOW_SIZE - 1 - i] *= common.half_window[i];
	}
}


/**
 * @brief Do FFT transform, 
 *
 * @param output: The fft results in complex form
 * @param input: The time-domain input windowed data
 */
void PercepNet::forward_transform(fft_cpx *output, const float *input)
{
	int i;
	std::unique_ptr<float[]> fft_data = std::make_unique<float[]>(WINDOW_SIZE);
	curr_fft->forward(fft_data.get(), input);
	// DC and Nyquist
	output[0].r = fft_data[0]/WINDOW_SIZE;
	output[0].i = 0.0f;
	// output[FREQ_SIZE-1].r = fft_data[1]/WINDOW_SIZE;
	// output[FREQ_SIZE-1].i = 0.0f;

	for (i = 1; i < LAST_BAND; i++)
	{
		output[i].r = fft_data[i*2] / WINDOW_SIZE;
		output[i].i = fft_data[i*2+1] / WINDOW_SIZE;
	}
	for (i = LAST_BAND; i < FREQ_SIZE; i++)
	{
		output[i].r = 0;
		output[i].i = 0;
	}
}


/**
 * @brief Converts 480 frequency bins into 34 Mel Bands
 *
 * @param band_e: The resulting Mel Band data
 * @param X: The input frequency data
 */
void PercepNet::compute_band_energy(float *band_e, const fft_cpx *X)
{
	int i;
	float sum[NB_BANDS] = {0};

	for (i = 0; i < NB_BANDS - 1; i++)
	{
		int j;
		int band_size;
		band_size = eband5ms[i + 1] - eband5ms[i];
		for (j = 0; j < band_size; j++)
		{
			float tmp;
			float frac = (float)j / band_size;
			tmp = SQUARE(X[(eband5ms[i]) + j].r);
			tmp += SQUARE(X[(eband5ms[i]) + j].i);
			sum[i] += (1 - frac) * tmp;
			sum[i + 1] += frac * tmp;
		}
	}
	sum[0] *= 2;
	sum[NB_BANDS - 1] *= 2;
	for (i = 0; i < NB_BANDS; i++)
	{
		band_e[i] = sum[i];
	}
}


/**
 * @brief Performs a forward FFT on the input, and converts frequencies to mel-bands
 *
 * @param st: denoise state [relevant info for computations]
 * @param X: FFT result
 * @param Ex: Energy input each Mel-Band
 * @param input: Pointer to the samples input the input frame
 */
void PercepNet::frame_analysis(DenoiseState *st, fft_cpx *X, float *Ex, const float *input)
{
	int i;
	float x[WINDOW_SIZE];
	RNN_COPY(x, st->analysis_mem, FRAME_SIZE);

	for (i = 0; i < FRAME_SIZE; i++)
	{
		x[FRAME_SIZE + i] = input[i];
	}
	RNN_COPY(st->analysis_mem, input, FRAME_SIZE);
	apply_window(x);
	forward_transform(X, x);

	// Get rid of DC
	X[0].r = X[0].i = 0;

	compute_band_energy(Ex, X);
}


/**
 * @brief Computes pitch coherence for each mel band?
 *
 * @param band_e: pitch coherence for each mel band
 * @param X: FFT of original signal
 * @param P: FFT of pitch enhanced (comb filtered signal)
 */
void PercepNet::compute_band_corr(float *band_e, const fft_cpx *X, const fft_cpx *P)
{
	int i;
	float sum[NB_BANDS] = {0};
	for (i = 0; i < NB_BANDS - 1; i++)
	{
		int j;
		int band_size;
		band_size = (eband5ms[i + 1] - eband5ms[i]);
		for (j = 0; j < band_size; j++)
		{
			float tmp;
			float frac = (float)j / band_size;
			tmp = X[(eband5ms[i]) + j].r * P[(eband5ms[i]) + j].r;
			tmp += X[(eband5ms[i]) + j].i * P[(eband5ms[i]) + j].i;
			sum[i] += (1 - frac) * tmp;
			sum[i + 1] += frac * tmp;
		}
	}
	sum[0] *= 2;
	sum[NB_BANDS - 1] *= 2;
	for (i = 0; i < NB_BANDS; i++)
	{
		band_e[i] = sum[i];
	}
}


/**
 * @brief Applies a comb filter on audio input stored input the current state's comb_buffer
 *
 * @param st: The current processor state object, which holds the filled comb buffer
 * @param pitch_index: The pitch index of the current frame
 * @param input: The input frame
 * @param output: Where the comb filtered samples will be written to
 */
void PercepNet::apply_comb_filter(DenoiseState *st, int pitch_index, const float *input, float *output)
{

	// Prepare Comb Buffer
	RNN_MOVE(st->comb_buf, &st->comb_buf[FRAME_SIZE], COMB_BUF_SIZE - FRAME_SIZE);
	RNN_COPY(&st->comb_buf[COMB_BUF_SIZE - FRAME_SIZE], input, FRAME_SIZE);

	// for (int i = 0; i < FRAME_SIZE; i++)
	// {
	//     celt_assert(st->comb_buf[COMB_BUF_SIZE - FRAME_SIZE + i] == input[i])
	// }

	for (int i = 0; i < WINDOW_SIZE; i++) 
	{
		output[i] = 0;
	}

	if (FRAME_LOOKAHEAD > 0)
	{
		/**
		 * Original comb filter implementation
		 * COMB_M is the number of periods on either side of the central tap
		 * We have to evaluate here how the lookahead effects the comb filter
		 */

		// Prepare Comb Buffer
		RNN_MOVE(st->comb_buf, &st->comb_buf[FRAME_SIZE], COMB_BUF_SIZE - FRAME_SIZE);
		RNN_COPY(&st->comb_buf[COMB_BUF_SIZE - FRAME_SIZE], input, FRAME_SIZE);

		// for (int i = 0; i < FRAME_SIZE; i++)
		// {
		//     celt_assert(st->comb_buf[COMB_BUF_SIZE - FRAME_SIZE + i] == input[i])
		// }

		int read_idx = COMB_BUF_SIZE - WINDOW_SIZE - pitch_index;
		for (int k = -COMB_M; k < COMB_M + 1; k++)
		{
			for (int i = 0; i < WINDOW_SIZE; i++)
			{
				output[i] += st->comb_buf[read_idx * k + i] * common.comb_hann_window[k + COMB_M];
			}
		}
	}
	else
	{
		/**
		 * self implementation of a basic feedforward comb filter.
		 * y[n] = b0*x[n]+bM*x[n-M]
		 * M = the amount samples input one period of the speaker's f0 (fundamental frequency)
		 */

		int read_start = COMB_BUF_SIZE - WINDOW_SIZE;
		float b0 = 0.5f;
		float bM = 0.5f;
		int M = pitch_index;
		for (int i = 0; i < WINDOW_SIZE; i++)
		{
			output[i] = b0 * st->comb_buf[read_start + i] + bM * st->comb_buf[read_start + i - M];
		}

	}
}


/**
 * @brief Computes all Features for a given frame
 *
 * @param st: Denoise State
 * @param X: Pointer to frequency data of the original input frame
 * @param P: Pointer to pitch filtered frequency data
 * @param Ex: Pointer to energy input each mel band
 * @param Ep: Pointer to pitch filtered energy for each mel band
 * @param Exp: Pointer to pitch coherence for each mel band
 * @param features: Pointer to memory where feature predictors will be written
 * @param input: The time-domain input frame
 */
int PercepNet::compute_frame_features(DenoiseState *st, fft_cpx *X, fft_cpx *P,
								  float *Ex, float *Ep, float *Exp, float *features, const float *input)
{
	int i;
	float E = 0;
	float p[WINDOW_SIZE];
	float pitch_buf[PITCH_BUF_SIZE >> 1];
	/** This is really the pitch frequency */
	int pitch_index;
	float gain;
	float *pre[1];
	/** Pitch correlation calculated by pitch_search*/
	float pitch_corr;

	frame_analysis(st, X, Ex, input);

	for (i = 0; i < FRAME_SIZE; i++)
	{
		E += SQUARE(X[i].r) + SQUARE(X[i].i);
	}
	// fft is already scaled
	// E = E / (FRAME_SIZE*FRAME_SIZE);
	E = 10 * log10(E + 1e-12);
	
	if (E <= -60.0)
	{
		RNN_CLEAR(features, NB_FEATURES_IN);
		return 1;
	}

	// Prepare Pitch Buffer
	RNN_MOVE(st->pitch_buf, &st->pitch_buf[FRAME_SIZE], PITCH_BUF_SIZE - FRAME_SIZE);
	RNN_COPY(&st->pitch_buf[PITCH_BUF_SIZE - FRAME_SIZE], input, FRAME_SIZE);
	pre[0] = &st->pitch_buf[0];

	// Estimate Pitch
	pitch_downsample(pre, pitch_buf, PITCH_BUF_SIZE, 1);
	pitch_search(pitch_buf + (PITCH_MAX_PERIOD >> 1),
				pitch_buf,
				PITCH_FRAME_SIZE,
				PITCH_MAX_PERIOD - 3 * PITCH_MIN_PERIOD,
				&pitch_index,
				&pitch_corr);
	pitch_index = PITCH_MAX_PERIOD - pitch_index;
	gain = remove_doubling(pitch_buf,
							PITCH_MAX_PERIOD,
							PITCH_MIN_PERIOD,
							PITCH_FRAME_SIZE,
							&pitch_index,
							st->last_period,
							st->last_gain);
	st->last_period = pitch_index;
	st->last_gain = gain;
	st->pitch_corr = pitch_corr;

	if (USE_COMB_FILTER)
	{
		apply_comb_filter(st, pitch_index, input, p);
	}
	else
	{
		for (i = 0; i < WINDOW_SIZE; i++)
		{
			p[i] = st->pitch_buf[PITCH_BUF_SIZE - WINDOW_SIZE + i];
		}
	}

	apply_window(p);
	forward_transform(P, p);
	compute_band_energy(Ep, P);
	compute_band_corr(Exp, X, P); // numerator of eq(5)
	for (i = 0; i < NB_BANDS; i++)
	{
		Exp[i] = SQUARE(Exp[i]) / (1e-8 + Ex[i] * Ep[i]); // denominator of eq(5)

		features[FEAT_MAG_Y + i] = Ex[i];
		features[FEAT_PITCH_COHERENCE + i] = Exp[i];
	}

	features[FEAT_PITCH_PERIOD] = pitch_index / (PITCH_MAX_PERIOD - 3.0 * PITCH_MIN_PERIOD);
	features[FEAT_PITCH_CORRELATION] = pitch_corr;

	return 0;
}



/**
 * @brief Performs the over-attenuation post filtering of noisy bands [Section 5 of Valin's Paper]
 * We further attenuate the noisy bands even more here here.
 * Listeners will notice reduced noise, much more than they will notice the slight degradation input speech quality.
 *
 * @param g: The predicted gains from the neural network
 * @param Ey: The Mel-Band energy of the original input frame
 */
void PercepNet::post_filtering(float *g, const float *Ey)
{
	// Envelope Postfiltering
	int i = 0;
	float E0 = 0;
	float E1 = 0;
	float E_div = 0;
	float g_w[NB_BANDS] = {0};
	float G = 0.0f;
	int mid_band = 24; // mel-band for division between high and low freq

	// warped gain - low freq
	for (i = 0; i < mid_band; i++)
	{
		g_w[i] = (g[i]+0.14) * sinf(M_PI / 2 * g[i] * 1.2) * 0.93;
	}
	// warped gain - high freq
	for (i = mid_band; i < NB_BANDS; i++)
	{
		g_w[i] = g[i] * sinf(M_PI / 2 * g[i]);
	}
	// for gain compensation 
	for (i = 0; i < NB_BANDS; i++)
	{
		E0 += g[i] * Ey[i];   // total energy of the enhanced signal
		E1 += g_w[i] * Ey[i]; // total energy when using the warped gain
	}

	// global gain compensation heuristic
	E_div = E0 / (E1 + 1e-8f);
	G = sqrtf(((1 + ENVELOPE_POSTFILTERING_BETA) * E_div) / (1 + ENVELOPE_POSTFILTERING_BETA * E_div * E_div));

	// Scaling the final signal for the frame by G
	for (i = 0; i < NB_BANDS; i++)
	{
		g[i] = G * g_w[i];
	}
}


/**
 * @brief gain smoothing with alpha * g(n) + (1-alpha) g(n-1)
 * @param st: Current Processor State
 * @param g: pointer to the mel-band gains to normalize
 */
void PercepNet::smooth_gains(DenoiseState *st, float *g)
{
	float alpha = 0.6f;
	for (int i = 0; i < NB_BANDS; i++)
	{
		g[i] = MAX16(alpha * g[i] + (1-alpha) * st->lastg[i], g[i]);
		st->lastg[i] = g[i];
	}
}


/**
 * @brief Converts 34 Mel Bands to 480 freq bins
 *
 * @param g: The resulting freqeuncy data
 * @param band_e: The input Mel Band data
 */
void PercepNet::interp_band_gain(float *g, const float *band_e)
{
	int i;
	memset(g, 0, FREQ_SIZE * sizeof(float));
	for (i = 0; i < NB_BANDS - 1; i++)
	{
		int j;
		int band_size;
		band_size = (eband5ms[i + 1] - eband5ms[i]);
		for (j = 0; j < band_size; j++)
		{
			float frac = (float)j / band_size;
			g[(eband5ms[i]) + j] = (1 - frac) * band_e[i] + frac * band_e[i + 1];
		}
	}
}


/**
 * @brief Applies Mel-Band Gains to FFT data.
 *
 * @param X: input FFT data
 * @param mel_gains: Gains to apply for each Mel frequency band
 */
void PercepNet::apply_gains(fft_cpx *X, float *mel_gains)
{
	float gf[FREQ_SIZE];
	interp_band_gain(gf, mel_gains);
	for (int i = 0; i < FREQ_SIZE; i++)
	{
		X[i].r *= gf[i];
		X[i].i *= gf[i];
	}
}


/**
 * @brief Apply a quick and dirty limiter to an audio frame
 *
 * @param x: time-domain input frame of floating point samples.
 */
void PercepNet::apply_limiter(float *x)
{
	for (int i = 0; i < FRAME_SIZE; i++)
	{
		if (x[i] > +1)
			x[i] = 1;
		else if (x[i] < -1)
			x[i] = -1;
	}
}


/**
 * @brief Do inverse FFT transform
 *
 * @param input: The fft results in complex form
 * @param output: The time-domain output
 */
void PercepNet::inverse_transform(float *output, const fft_cpx *input)
{
	std::unique_ptr<float[]> buff = std::make_unique<float[]>(WINDOW_SIZE);

	int i;
	// DC and Nyquist
	buff[0] = input[0].r;
	buff[1] = input[FREQ_SIZE-1].r;

	for (i = 1; i < FREQ_SIZE-1; i++)
	{
		buff[i*2] = input[i].r;
		buff[i*2+1] = input[i].i;
	}

	curr_fft->inverse(output, buff.get());
}


/**
 * @brief Converts a Frame of audio back to time-domain, by performing an inverse FFT, and windowing
 *
 * @param st: current state of processor
 * @param output: Memory to write output samples to
 * @param y: input FFT data
 */
void PercepNet::frame_synthesis(DenoiseState *st, float *output, const fft_cpx *y)
{
	float x[WINDOW_SIZE];
	int i;
	inverse_transform(x, y);
	apply_window(x);
	for (i = 0; i < FRAME_SIZE; i++)
		output[i] = x[i] + st->synthesis_mem[i];
	RNN_COPY(st->synthesis_mem, &x[FRAME_SIZE], FRAME_SIZE);
}


/**
 * @brief Performs a Frequency Domain filter
 *
 * For pitch filter strenghts r, the equation should be:
 * y = {(1-r)x + rp}
 * where x is the original signal, and p is the enhanced, comb filtered signal.
 * the filter strengths r that we approximate, should determine the ratio for crossfading between
 * the enhanced, comb filtered signal and the original signal for each band.
 *
 * @param X: The FFT data of the current frame
 * @param P: The FFT data of the pitch enhanced (comb filtered) current frame
 * @param r: The predicted mel-band filter strengths
 */
void PercepNet::pitch_filter(fft_cpx *X, const fft_cpx *P, const float *r)
{
	int i;
	float rf[FREQ_SIZE] = {0};
	float inv_r[NB_BANDS] = {0};

	for (int i = 0; i < NB_BANDS; i++)
	{
		inv_r[i] = 1 - r[i];
	}

	// Interpolate mel-band filter strengths to all 480 freqs
	interp_band_gain(rf, inv_r); // (1 - r)

	for (i = 0; i < FREQ_SIZE; i++)
	{
		X[i].r = rf[i] * X[i].r;
		X[i].i = rf[i] * X[i].i;
	}

	interp_band_gain(rf, r); // r
	for (i = 0; i < FREQ_SIZE; i++)
	{
		X[i].r += rf[i] * P[i].r;
		X[i].i += rf[i] * P[i].i;
	}
}


/**
 * @brief Call the trained onnx model
 *
 * Given features of the current frame,
 * predict the enhancement gains and pitch
 * filter ratios
 *
 * @param onnx: The onnx model path
 * @param gains: The model output, predicted gains
 * @param rb_gains: The model output, pitch filter strengths/ratios
 * @param input: features of one frame, to save as a part of model input
 */
void PercepNet::compute_onnx(const char *onnx, float *gains, float *rb_gains, const float *input)
{
	if (O == nullptr) 
  	{
		O = OrtGetApiBase()->GetApi(ORT_API_VERSION);
		if (!O) 
		{
			SPDLOG_ERROR("Failed to init ONNX Runtime engine");
			exit(1);
		}

		ORT_ABORT_ON_ERROR(O->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "PercepNet", &env));
		
		ORT_ABORT_ON_ERROR(O->CreateSessionOptions(&session_options));

		ORT_ABORT_ON_ERROR(O->CreateSession(env, onnx, session_options, &session));
		ORT_ABORT_ON_ERROR(O->GetAllocatorWithDefaultOptions(&ort_alloc));

		// Find the input and output tensors
		ORT_ABORT_ON_ERROR(O->SessionGetInputCount(session, &nin));
		ORT_ABORT_ON_ERROR(O->SessionGetOutputCount(session, &nout));
	
		input_names = (char**)calloc(sizeof(char*), nin);
		output_names = (char**)calloc(sizeof(char*), nout);
		OrtTypeInfo *input[nin];
		OrtTypeInfo *output[nout];
		OrtTensorTypeAndShapeInfo *input_tensor_info[nin];
		OrtTensorTypeAndShapeInfo *output_tensor_info[nout];
		ONNXTensorElementDataType input_tensor_elem_type[nin];
		ONNXTensorElementDataType output_tensor_elem_type[nout];
		size_t input_dim[nin];
		size_t output_dim[nout];

		input_tensor = (OrtValue **)calloc(sizeof(OrtValue*), nin);
		input_tensor_size = (size_t *)calloc(sizeof(size_t), nin);
		output_tensor = (OrtValue **)calloc(sizeof(OrtValue*), nout);
		output_tensor_size = (size_t *)calloc(sizeof(size_t), nout);

		// Input
		for (size_t i=0; i<nin; i++) 
		{
			ORT_ABORT_ON_ERROR(O->SessionGetInputName(session, i, ort_alloc, &input_names[i]));
			ORT_ABORT_ON_ERROR(O->SessionGetInputTypeInfo(session, i, &input[i]));
			ORT_ABORT_ON_ERROR(O->CastTypeInfoToTensorInfo((const OrtTypeInfo *)input[i],
									(const OrtTensorTypeAndShapeInfo **)&input_tensor_info[i]));
			ORT_ABORT_ON_ERROR(O->GetTensorElementType((const OrtTensorTypeAndShapeInfo *)input_tensor_info[i],
								&input_tensor_elem_type[i]));
			ORT_ABORT_ON_ERROR(O->GetDimensionsCount((const OrtTensorTypeAndShapeInfo *)input_tensor_info[i],
								&input_dim[i]));
			
			int64_t dim[input_dim[i]];

			ORT_ABORT_ON_ERROR(O->GetDimensions((const OrtTensorTypeAndShapeInfo *)input_tensor_info[i],
							dim, input_dim[i]));
			// SPDLOG_DEBUG("{}: {} ", input_names[i], input_tensor_elem_type[i]);
			input_tensor_size[i] = 1;
			for (size_t d=0; d<input_dim[i]; d++) 
			{
				// SPDLOG_DEBUG("{} ", dim[d]);
				input_tensor_size[i] *=  dim[d];
			}
		
			ORT_ABORT_ON_ERROR(O->CreateTensorAsOrtValue(ort_alloc, dim, input_dim[i],
								input_tensor_elem_type[i], &input_tensor[i]));
			float *fp;
			ORT_ABORT_ON_ERROR(O->GetTensorMutableData(input_tensor[i], (void**)&fp));
			memset(fp,0,input_tensor_size[i]*sizeof(float));
		}

		// Output
		for (size_t i=0; i<nout; i++) 
		{
			ORT_ABORT_ON_ERROR(O->SessionGetOutputName(session, i, ort_alloc, &output_names[i]));
			ORT_ABORT_ON_ERROR(O->SessionGetOutputTypeInfo(session, i, &output[i]));
			ORT_ABORT_ON_ERROR(O->CastTypeInfoToTensorInfo((const OrtTypeInfo *)output[i],
									(const OrtTensorTypeAndShapeInfo **)&output_tensor_info[i]));
			ORT_ABORT_ON_ERROR(O->GetTensorElementType((const OrtTensorTypeAndShapeInfo *)output_tensor_info[i],
								&output_tensor_elem_type[i]));
			ORT_ABORT_ON_ERROR(O->GetDimensionsCount((const OrtTensorTypeAndShapeInfo *)output_tensor_info[i],
								&output_dim[i]));

			int64_t dim[output_dim[i]];

			ORT_ABORT_ON_ERROR(O->GetDimensions((const OrtTensorTypeAndShapeInfo *)output_tensor_info[i], dim, output_dim[i]));
			// SPDLOG_DEBUG("{}: {} ", output_names[i], output_tensor_elem_type[i]);
			output_tensor_size[i] = 1;
			for (size_t d=0; d<output_dim[i]; d++) 
			{
				// SPDLOG_DEBUG("{} ", dim[d]);
				output_tensor_size[i] *= dim[d];
			}
		
			ORT_ABORT_ON_ERROR(O->CreateTensorAsOrtValue(ort_alloc, dim, output_dim[i],
								output_tensor_elem_type[i], &output_tensor[i]));
		}
	}

	//Run the model
	float *p;

	ORT_ABORT_ON_ERROR(O->GetTensorMutableData(input_tensor[0], (void**)&p));
	memcpy(p, input, sizeof(float)*input_tensor_size[0]);
	
	ORT_ABORT_ON_ERROR(O->Run(session, nullptr,
					(const char * const*)input_names, (const OrtValue * const*)input_tensor, nin,
					(const char * const*)output_names, nout,
					output_tensor));

	ORT_ABORT_ON_ERROR(O->GetTensorMutableData(output_tensor[0], (void**)&p));
	memcpy(gains,p,NB_BANDS*sizeof(float));
	memcpy(rb_gains,&p[NB_BANDS],NB_BANDS*sizeof(float));
		
	// Swap the internal state (parameter 0 is the predictor/result tensor).
	// This is where the output rolling window buffer is switched into the input 
	// rolling window buffer for the next frame.
	for (size_t i=1; i<nin; i++) {
		OrtValue *tmp = input_tensor[i];
		input_tensor[i] = output_tensor[i];
		output_tensor[i] = tmp;
	}
}


/**
 * @brief Performs denoising on a single audio frame
 *
 * @param st: Processor State
 * @param output: The denoised output frame
 * @param input: The noisy input frame
 * @param pf: Whether to use pitch filtering
 * @param post: Whether to use post filtering / over-attenuation
 * @param lookahead: The number of lookahead frames to use during processing
 * @param frame_skip: Whether to do frame skipping to save computations, call 
 * 						the model every other frame
 */
void PercepNet::rnnoise_process_frame(DenoiseState *st, float *output, const float *input, int pf, 
	int post, int lookahead, int frame_skip)
{

	float features[NB_FEATURES_IN];
	float g[NB_BANDS];
	float r[NB_BANDS];

	int silence;

	if (frame_in == -1 && frame_out == -1)
	{
		// First time through the loop
		frame_in = lookahead;
		frame_out = 0;
		skip_switch = 1;
	}
	// toggle the frame skipping switch
	skip_switch = 1 - skip_switch;

	silence = compute_frame_features(st, X[frame_in], P[frame_in], Ex[frame_in], Ep[frame_in], Exp[frame_in], features, input);
	if (!silence)
	{
		// frame skipping turned on
		if (frame_skip == 1) 
		{

			// compute new gains and filter ratios since switch=compute stage
			if (skip_switch == 0) 
			{
				// call the DNN and update the rolling
				compute_onnx(st->onnx, g, r, features);
				if (post)
				{
					post_filtering(g, Ex[frame_out]);
				}
				// normalize_gains(st, g);
				smooth_gains(st, g);
				for (int i = 0; i < NB_BANDS; i++) 
				{
					st->g_app[i] = g[i];
					st->r_app[i] = r[i];
					g[i] = st->g_pre[i];
					r[i] = st->r_pre[i];
				}
			// update new gains and ratios (ignore current frame gains and ratios) since switch=update stage
			} 
			else 
			{
				for (int i = 0; i < NB_BANDS; i++) 
				{
					g[i] = st->g_app[i];
					r[i] = st->r_app[i];
					st->g_pre[i] = st->g_app[i];
					st->r_pre[i] = st->r_app[i];
				}
			}
		// no frame skipping
		} 
		else 
		{
			// We need to call the DNN even if we ignore the result. The call is needed to update
			// the rolling window.
			compute_onnx(st->onnx, g, r, features);
			if (post)
			{
				post_filtering(g, Ex[frame_out]);
			}
			smooth_gains(st, g);
		}

		if (ignore_strengths)
		{ 
			apply_gains(P[frame_out], g);
		}
		else 
		{
			apply_gains(X[frame_out], g);
			if (pf)
				pitch_filter(X[frame_out], P[frame_out], r);
		}
	}

	if (ignore_strengths)
	{ 
		frame_synthesis(st, output, P[frame_out]);
	}
	else 
	{
		frame_synthesis(st, output, X[frame_out]);
	}

	if (!silence) 
	{
	    apply_limiter(output);
	}
	frame_in = (frame_in + 1) % MAX_LOOKAHEAD;
	frame_out = (frame_out + 1) % MAX_LOOKAHEAD;
}


void PercepNet::process()
{
	// percepnet can process only one channel !
	rnnoise_process_frame(st, out[0], in[0], 1, 1, 0, skip_frame);
	// copy ch1 to the rest
	for (int_fast32_t channel = 1; channel < channels; channel++)
	{
		for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
		{
			out[channel][sample] = out[0][sample];
		}
	}
}

}
