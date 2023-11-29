// Arbitrary EQ ported from Katana-DSP-IP
//
// Apply EQ based on an "arbitrary" target magnitude response 
// curve using cascaded warped FIR and FIR filters.
// Users can add unlimited numbers of raised cosine filter
// bands to construct the target magnitude response curve.
// Choose raised cosine filter shapes from: 
// high-shelf, low-shelf, peak, mesa. 

#include <bosepro/algorithm.h>
#include "fft.h"
#include "fir.h"
#include "wfir.h"
#include "firbase.h"

#include <memory>
#include <map>
#include <limits>
#include <vector>

namespace {

// There are two meanings for "band" in the context of ArbitraryEQ. One is a
// filter section as defined by the user (high-shelf, mesa, etc). The other
// is a processing band where the spectrum is split into usually 3 bands
// for FIR processing on each band.
class ArbitraryEQ : public bosepro::Algorithm
{
public:
    ArbitraryEQ(const bosepro::BlockConfiguration &configuration);
    virtual ~ArbitraryEQ() = default;

    virtual void process() override;

private:
    // --- constants and terminals ---
    int_fast32_t channels;
    // number of taps for the wFIR filters, default uses 384
    int_fast32_t num_taps_wfir;
    // number of taps for the FIR filter, default uses 768
    int_fast32_t num_taps_fir;
    // how many freq bins per octave, default uses 1/60 octave bins,
    // so points_per_octave = 60
    int_fast32_t points_per_octave;
    // how many octaves in the transition region/overlap between 
    // FIR filter bands, default 1
    int_fast32_t transition_octaves;
    // usually set as 3 bands, which are the 3 cascaded wFIR->wFIR->FIR filters
    int_fast32_t num_bands;
    // how many user-control bands to use to create the target 
    // frequency response vector
    int_fast32_t max_user_bands;

    std::vector<const float *> in;
    std::vector<float *> out;
    
    // --- user controls ---
    std::vector<bool> band_enable;
    // raised cosine filter type: high_shelf, low_shelf, peak, mesa
    std::vector<std::string> filter_type;
    std::vector<float> gain;
    std::vector<float> frequency1;
    std::vector<float> bandwidth1;
    // only used when filter type is mesa
    std::vector<float> frequency2;
    // only used when filter type is mesa
    std::vector<float> bandwidth2;

    // --- processing variables ---
    static const std::map<std::string, filter::CosineFilterType> type_map;
    static constexpr float LAMBDA_SEARCH_MIN{-0.9999f};
    static constexpr float LAMBDA_SEARCH_MAX{0.0000f};
    static constexpr float LAMBDA_SEARCH_STEP{0.0001f};
    static constexpr float FREQ_MIN{16.0f};
    static constexpr float FLOAT_MAX{std::numeric_limits<float>::max()};

    int _num_points;
    int _points_per_band;
    int _wfir_half_length;
    int _fir_half_length;
    int _transition_num_points;

    std::unique_ptr<float[]> _lambda;
    std::shared_ptr<float[]> _freq;
    std::shared_ptr<float[]> _target_mag;
    std::vector<std::shared_ptr<int[]>> _interp_idx;
    std::vector<std::shared_ptr<float[]>> _interp_frac;
    std::unique_ptr<fft::Fft> _fft_wfir;
    std::unique_ptr<fft::Fft> _fft_fir;
    std::vector<std::shared_ptr<filter::FirFilter>> _filters;
    std::unique_ptr<float[]> _transition_ramp;
    std::vector<std::shared_ptr<filter::ArbitraryBand>> _band_list;

    // --- processing functions ---
    void init_frequencies(void);
    float warp_norm(float f, float lambda);
    void compute_max_spacing(float* max_spacing, float lambda);
    void compute_optimal_lambda(void);
    void compute_coeffs(void);
    void compute_interpolation_values(void);
    void clear_target_magnitude(void);
    void recalculate(void);

    // --- user control parameters processing functions ---
    void update_band_enable(int band);
    void update_gain(int band);
    void update_filter_type(int band);
    void update_frequency1(int band);
    void update_frequency2(int band);
    void update_bandwidth1(int band);
    void update_bandwidth2(int band);

    ALGORITHM_DECLARE(ArbitraryEQ);
};

ALGORITHM_REGISTER(ArbitraryEQ, "arbitrary_eq");

const std::map<std::string, filter::CosineFilterType> ArbitraryEQ::type_map = {
    {"high_shelf", filter::CosineFilterType::HIGH_SHELF},
    {"low_shelf", filter::CosineFilterType::LOW_SHELF},
    {"peak", filter::CosineFilterType::PEAK},
    {"mesa", filter::CosineFilterType::MESA}
};

ArbitraryEQ::ArbitraryEQ(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);
    get_constant("num_bands", num_bands);
    get_constant("max_user_bands", max_user_bands);
    get_constant("num_taps_wfir", num_taps_wfir);
    get_constant("num_taps_fir", num_taps_fir);
    get_constant("points_per_octave", points_per_octave);
    get_constant("transition_octaves", transition_octaves);
    assign_terminal("in", &in);
    assign_terminal("out", &out);
    assign_control("band_enable", &band_enable, POST_FUNCTION_VECTOR(update_band_enable));
    assign_control("filter_type", &filter_type, POST_FUNCTION_VECTOR(update_filter_type));
    assign_control("gain", &gain, POST_FUNCTION_VECTOR(update_gain));
    assign_control("frequency1", &frequency1, POST_FUNCTION_VECTOR(update_frequency1));
    assign_control("frequency2", &frequency2, POST_FUNCTION_VECTOR(update_frequency2));
    assign_control("bandwidth1", &bandwidth1, POST_FUNCTION_VECTOR(update_bandwidth1));
    assign_control("bandwidth2", &bandwidth2, POST_FUNCTION_VECTOR(update_bandwidth2));
    // Initialize FFT objects
    _fft_wfir = std::make_unique<fft::Fft>(num_taps_wfir);
    _fft_fir = std::make_unique<fft::Fft>(num_taps_fir);

    _wfir_half_length = num_taps_wfir/2+1;
    _fir_half_length = num_taps_fir/2+1;
    // get the center frequency curve
    init_frequencies();
    // initialize the target gain curve
    _target_mag = std::shared_ptr<float[]>(new float[_num_points]);
    // initialize the list of user set bands (raised cosine filters)
    for (int user_band{0}; user_band < max_user_bands; ++user_band)
    {
        _band_list.push_back(std::shared_ptr<filter::ArbitraryBand>(new filter::ArbitraryBand));
    }

    _transition_num_points = 2 * static_cast<int>(roundf(0.5f * transition_octaves * points_per_octave));
    _transition_ramp = std::make_unique<float[]>(_transition_num_points);
    for (int i{0}; i < _transition_num_points; ++i)
    {
        _transition_ramp[i] = static_cast<float>(i+1) / static_cast<float>(_transition_num_points+1);
    }

    _lambda = std::make_unique<float[]>(num_bands-1);
    compute_optimal_lambda();
    // All but last band are WFIR
    for (int band{0}; band < num_bands-1; ++band)
    {
        _filters.push_back(std::shared_ptr<filter::_WFirFilter>(new filter::_WFirFilter{static_cast<int>(num_taps_wfir), 
            _lambda[band], get_frame_size(), get_sample_rate()}));
        _interp_idx.push_back(std::shared_ptr<int[]>(new int[_wfir_half_length]));
        _interp_frac.push_back(std::shared_ptr<float[]>(new float[_wfir_half_length]));
    }
    // Last band is FIR
    _filters.push_back(std::shared_ptr<filter::FirFilter>(new filter::FirFilter{static_cast<int>(num_taps_fir), 
        get_frame_size(), get_sample_rate()}));

    _interp_idx.push_back(std::shared_ptr<int[]>(new int[_fir_half_length]));
    _interp_frac.push_back(std::shared_ptr<float[]>(new float[_fir_half_length]));

    compute_interpolation_values();
    //computeCoeffs();
}


void ArbitraryEQ::update_band_enable(int band)
{
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_DEBUG("Selected band out of range");
    }
    _band_list.at(band)->set_enable(band_enable[band]);
    recalculate();
}


void ArbitraryEQ::update_frequency1(int band)
{
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_DEBUG("Selected band out of range");
    }
    _band_list.at(band)->set_frequency(frequency1[band], 1);
    recalculate();
}


void ArbitraryEQ::update_frequency2(int band)
{
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_DEBUG("Selected band out of range");
    }
    _band_list.at(band)->set_frequency(frequency2[band], 2);
    recalculate();
}


void ArbitraryEQ::update_gain(int band)
{
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_DEBUG("Selected band out of range");
    }
    _band_list.at(band)->set_gain(gain[band]);
    recalculate();
}


void ArbitraryEQ::update_bandwidth1(int band)
{
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_DEBUG("Selected band out of range");
    }
    _band_list.at(band)->set_bandwidth(bandwidth1[band], 1);
    recalculate();
}


void ArbitraryEQ::update_bandwidth2(int band)
{
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_ERROR("Selected band out of range");
    }
    _band_list.at(band)->set_bandwidth(bandwidth2[band], 2);
    recalculate();
}


void ArbitraryEQ::update_filter_type(int band)
{
    if (type_map.count(filter_type.at(band)) == 0)
    {
        SPDLOG_ERROR("Illegal value '" + filter_type.at(band) + "' for 'type' parameter.");
    }
    filter::CosineFilterType f_type = type_map.find(filter_type.at(band))->second;
    if (band < 0 || band >= max_user_bands)
    {
        SPDLOG_ERROR("Selected band out of range");
    }
    
    _band_list.at(band)->set_type(f_type);
    recalculate();
}


// recompute the target magnitude/gain curves for each of 
// the arbitrary bands, combine into one target gain curve,
// then compute the cascaded FIR filters' coefficients that
// will achieve the gain curve
void ArbitraryEQ::recalculate()
{
    clear_target_magnitude();
    for (auto band : _band_list)
    {
        if (band->is_enabled())
        {
            band->add_band_to_response(_target_mag, _freq, _num_points);
        }
    }
    compute_coeffs();
}


// clear the current target magnitude / gain curves
// of each FIR filter (each processing band)
inline void ArbitraryEQ::clear_target_magnitude(void)
{
    memset(_target_mag.get(), 0, _num_points * sizeof(float));
}

// get the vector of log2-scaled center frequencies, starting from FREQ_MIN Hz to the 
// Nyquist frequency. with default settings, the number of frequency points is 634, 
// covering 16Hz~24kHz
void ArbitraryEQ::init_frequencies(void)
{
    _num_points = static_cast<int>(log2f(0.5f * get_sample_rate() / FREQ_MIN) * 
        points_per_octave) + 1;
    _points_per_band = static_cast<int>(roundf(static_cast<float>(_num_points) / 
        static_cast<float>(num_bands)));
    _freq = std::shared_ptr<float[]>(new float[_num_points]);
    float mult_factor {powf(2.0f, 1.0f/static_cast<float>(points_per_octave))};
    _freq[0] = FREQ_MIN;

    for (int bin{1}; bin < _num_points - 1; ++bin)
    {
        _freq[bin] = !(bin % points_per_octave) ? (_freq[bin -points_per_octave]) * 
            2.0f : (_freq[bin - 1] * mult_factor);
    }

    // last freq is always nyquist
    _freq[_num_points-1] = 0.5f * get_sample_rate();
    //SPDLOG_DEBUG("ArbitraryEQ Frequency vector initialized. Num points: {}",_numPoints);
}

// calculate the normalized warped frequency 
// from normalized linear frequency with given lambda
float ArbitraryEQ::warp_norm(float f, float lambda)
{
    if (f >= 1.0f)
    {
        return 1.0f;
    }
    else if (f <= 0.0f)
    {
        return 0.0f;
    }
    float omega{static_cast<float>(M_PI * f)};
    float theta{atanf(((1.0f - lambda*lambda)*sinf(omega)) / ((1.0f + 
        lambda*lambda)*cosf(omega) - 2.0f*lambda))};

    return ((theta >= 0.0f) ? theta : theta+M_PI) / M_PI;
}


// recompute interpolation related variables to help later
// mapping from arbtirary gain vector spacing to log spaced 
void ArbitraryEQ::compute_interpolation_values(void)
{
    float warped_freq;
    float idx;
    float lambda;
    int length;

    for (int band_idx{0}; band_idx < num_bands; ++band_idx)
    {
        length = (band_idx < num_bands-1) ? _wfir_half_length : _fir_half_length;
        lambda = (band_idx < num_bands-1) ? _lambda[band_idx] : 0.0f;

        for (int tap{0}; tap < length; ++tap)
        {
            warped_freq = 0.5f * get_sample_rate() * warp_norm(static_cast<float>(tap)/
                static_cast<float>(length-1), lambda);
            idx = log2f(warped_freq/FREQ_MIN) * static_cast<float>(points_per_octave);
            if (idx <= 0.0f)
            {
                _interp_idx[band_idx][tap] = 0;
                _interp_frac[band_idx][tap] = 0.0f;
            }
            else if (idx >= static_cast<float>(_num_points) - 1.0f)
            {
                _interp_idx[band_idx][tap] = _num_points - 2;
                _interp_frac[band_idx][tap] = 1.0f;
            }
            else
            {
                _interp_idx[band_idx][tap] = static_cast<int>(floorf(idx));
                _interp_frac[band_idx][tap] = idx - static_cast<float>(_interp_idx[band_idx][tap]);
            }
        }
    }
}


// compute FIR filter coefficients
void ArbitraryEQ::compute_coeffs(void)
{
    bool is_wfir;
    bool left_ramp;
    bool right_ramp;

    int num_taps;
    int gain_length;
    int start_idx;
    int end_idx;

    float a, b;

    std::unique_ptr<float[]> band_target_mag;
    std::unique_ptr<float[]> warped_gain;
    std::unique_ptr<float[]> buf1;
    std::unique_ptr<float[]> buf2;

    fft::Fft* curr_fft;
    float scale{logf(10.0f) / 20.0f};

    for (int band_idx{0}; band_idx < num_bands; ++band_idx)
    {
        is_wfir = band_idx < num_bands-1;
        num_taps = is_wfir ? num_taps_wfir : num_taps_fir;

        std::unique_ptr<float[]> coeffs = std::make_unique<float[]>(num_taps);

        // compute band target magnitudes
        band_target_mag = std::make_unique<float[]>(_num_points);

        start_idx = (band_idx == 0) ? 0 : band_idx*_points_per_band - _transition_num_points/2;
        end_idx = is_wfir ? (band_idx+1)*_points_per_band + _transition_num_points/2 : _num_points;
        left_ramp = band_idx > 0;
        right_ramp = is_wfir;

        memcpy(&band_target_mag[start_idx], &_target_mag[start_idx], 
            sizeof(float)*(end_idx-start_idx));

        for (int i{0}; i < _transition_num_points; ++i)
        {
            if (left_ramp)
            {
                band_target_mag[start_idx+i] *= _transition_ramp[i];
            }
            if (right_ramp)
            {
                band_target_mag[end_idx-i-1] *= _transition_ramp[i];
            }
        }

        gain_length = is_wfir ? _wfir_half_length : _fir_half_length;
        warped_gain = std::make_unique<float[]>(num_taps);

        // generate the warped target gain by interpolation
        for (int tap{0}; tap < gain_length; ++tap)
        {
            warped_gain[2*tap] = ((1.0f - _interp_frac[band_idx][tap]) * 
                band_target_mag[_interp_idx[band_idx][tap]] + _interp_frac[band_idx][tap] * 
                band_target_mag[_interp_idx[band_idx][tap]+1]);
            warped_gain[2*tap] *= scale;
		}
        warped_gain[1] = band_target_mag[_num_points-1] * scale;


        // take the ifft of warped_gain
        buf1 = std::make_unique<float[]>(num_taps);
        buf2 = std::make_unique<float[]>(num_taps);
        memcpy(buf1.get(), &warped_gain[0], sizeof(float)*(num_taps));

        curr_fft = is_wfir ? _fft_wfir.get() : _fft_fir.get();
        curr_fft->inverse(buf2.get(), buf1.get());

        // apply window, post-scaling to buf
        buf2[0] /= static_cast<float>(num_taps);

        for (int tap{1}; tap < gain_length - 1; ++tap)
        {
            buf2[tap] *= 2.0f / static_cast<float>(num_taps);
        }

        buf2[gain_length-1] /= static_cast<float>(num_taps);
        memset(&buf2[gain_length], 0, sizeof(float)*(gain_length-2));

        // real(ifft(exp(fft(buf))))
        curr_fft->forward(buf1.get(), buf2.get());

        // exp(A+jB) = (exp(A)*cos(B)) + j(exp(A)*sin(B))
        buf1[0] = expf(buf1[0]);
        buf1[1] = expf(buf1[1]);

        for (int tap{2}; tap < num_taps; tap += 2)
        {
            a = expf(buf1[tap]);
            b = buf1[tap+1];
            buf1[tap] = a*cosf(b);
            buf1[tap+1] = a*sinf(b);
        }

        curr_fft->inverse(coeffs.get(), buf1.get());

        for (int tap{0}; tap < num_taps; ++tap)
        {
            coeffs[tap] /= static_cast<float>(num_taps);
            // SPDLOG_DEBUG("ArbitraryEQ coeffs[{}][{}] = {}", bandIdx, tap, coeffs[tap]);
        }
        _filters[band_idx]->with_coefficients(coeffs.get());
    }
}


// get the maximum octave spacing with the given lambda
void ArbitraryEQ::compute_max_spacing(float* max_spacing, float lambda)
{
    auto warped_freq {std::make_unique<std::vector<float>[]>(num_bands-1)};

    for (int band_idx{0}; band_idx < num_bands-1; ++band_idx)
    {
        max_spacing[band_idx] = FLOAT_MAX;
        // Save some time with resizing operations by reserving
        warped_freq[band_idx].reserve(_wfir_half_length);
    }

    float curr_freq_norm;
    float curr_warped_freq;
    int band_idx;

    for (int freq_idx{1}; freq_idx < _wfir_half_length; ++freq_idx)
    {
        curr_freq_norm = static_cast<float>(freq_idx) / static_cast<float>(_wfir_half_length-1);
        curr_warped_freq = warp_norm(curr_freq_norm, lambda) * 0.5f * get_sample_rate();

        band_idx = static_cast<int>(floorf(log2f(curr_warped_freq / FREQ_MIN) * 
            points_per_octave / _points_per_band));
        if (band_idx < 0)
        {
            continue;
        }
        if (band_idx >= num_bands-1)
        {
            break;
        }
        warped_freq[band_idx].push_back(curr_warped_freq);
    }

    float curr_spacing;
    for (band_idx = 0; band_idx < num_bands-1; ++band_idx)
    {
        if (warped_freq[band_idx].size() < 3)
        {
            continue;
        }

        max_spacing[band_idx] = fmax(warped_freq[band_idx][1] / warped_freq[band_idx][0], 
                warped_freq[band_idx].back() / warped_freq[band_idx][warped_freq[band_idx].size()-2]);
        max_spacing[band_idx] *= max_spacing[band_idx];

        for (std::vector<float*>::size_type freq_idx{1};
             freq_idx < warped_freq[band_idx].size() - 1;
             ++freq_idx)
        {
            curr_spacing = warped_freq[band_idx][freq_idx+1] / warped_freq[band_idx][freq_idx-1];
            if (curr_spacing > max_spacing[band_idx])
            {
                max_spacing[band_idx] = curr_spacing;
            }
        }
    }
}


// search for the lambda values that results in highest minimum 
// points per octave for all wFIR bands
void ArbitraryEQ::compute_optimal_lambda(void)
{
    auto minimax_spacing{std::make_unique<float[]>(num_bands-1)};
    auto max_spacing{std::make_unique<float[]>(num_bands-1)};

    compute_max_spacing(max_spacing.get(), LAMBDA_SEARCH_MIN);


    for (int band_idx{0}; band_idx < num_bands-1; ++band_idx)
    {
        minimax_spacing[band_idx] = max_spacing[band_idx];
        _lambda[band_idx] = LAMBDA_SEARCH_MIN;
    }

    // brute force search for all lambda candidates for
    // all w_fir processing bands
    for (float lambda_cand{LAMBDA_SEARCH_MIN+LAMBDA_SEARCH_STEP};
         lambda_cand <= LAMBDA_SEARCH_MAX;
         lambda_cand += LAMBDA_SEARCH_STEP)
    {
        compute_max_spacing(max_spacing.get(), lambda_cand);
        for (int band_idx{0}; band_idx < num_bands-1; ++band_idx)
        {
            if (max_spacing[band_idx] < minimax_spacing[band_idx])
            {
                minimax_spacing[band_idx] = max_spacing[band_idx];
                _lambda[band_idx] = lambda_cand;
            }
        }
    }
    for (int band_idx{0}; band_idx < num_bands-1; ++band_idx)
    {
        SPDLOG_TRACE("ArbitraryEQ Optimal lambda, band {}: {}",band_idx,_lambda[band_idx]);
    }
}


void ArbitraryEQ::process()
{
    for (int_fast32_t channel = 0; channel < channels; channel++)
    {
        memcpy(out[channel], in[channel], sizeof(float)*get_frame_size());
        // Process through each FIR filter band
        for (auto firFilter : _filters)
        {
            firFilter->process(out[channel], out[channel]);
        }
    }
}

}

// end of file