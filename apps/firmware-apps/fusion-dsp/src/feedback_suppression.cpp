// Feedback Suppression
//
// Based on feedback peak detection and 
// parametric filters. Apply notch filters
// on detected feedback peaks. 
//
// For now an fft_size of 8192 is assumed
// becuase the blackman window applied is 
// hard-coded 
//
// algorithm related files used
// - fbs_filter.cpp/.h
// - fbs_struct.h
// - blackman_8192_coeffs.h
// - fft.h
// - iir.cpp/.h
// - iir_design.cpp/.h

#include <bosepro/algorithm.h>
#include "fft.h"
#include "blackman_8192_coeffs.h"
#include "fbs_filter.h"

#include <vector>
#include <deque>

namespace {


class FeedbackSuppression : public bosepro::Algorithm
{
public:
    FeedbackSuppression(const bosepro::BlockConfiguration &configuration);
    virtual ~FeedbackSuppression() = default;

    virtual void process() override;

private:
    // --- constants and terminals ---
    int_fast32_t channels;
    int_fast32_t fft_size;
    //max number of notch filters to apply
    int_fast32_t num_filters;
    //number of peaks to track in each feeback peak detection process
    int_fast32_t num_peaks_to_find;
    //max buffer size to store candidate feedback frequencies
    uint_fast32_t rev_feedback_cand_freq_buf_size;

    std::vector<const float *> in;
    std::vector<float *> out;
    
    // --- user controls ---
    //Any peak below this frequency index (fft bin num) 
    //will be ignored
    int_fast32_t low_freq_ignore_freq;
    //Any peak above this frequency index (fft bin num) 
    //will be ignored
    int_fast32_t high_freq_ignore_freq;
    //the threshold to determine if a given frequency
    //belongs to the mid-freq or above range 
    int_fast32_t mult_band_crossover_freq_mid;
    //the threshold to determine if a given frequency 
    //belongs to the high-freq or above range
    int_fast32_t mult_band_crossover_freq_high;
    //the threshold to determine if a given frequency 
    //belongs to the superhigh-freq range
    int_fast32_t mult_band_crossover_freq_superhigh;
    // For spectral peak detector
    //Any peak with an amplitude below this will be ignored - dB
    int_fast32_t f0_amplitude_th;
    //error margin in octave for each spectral range, to determine 
    //whether two frequencies are close enough to each other
    float frequency_error_margin_in_octaves[NUM_MULTI_BANDS];
    // Harmonics Analysis Parameters
    //Peak appearance counter threshold for each spectral range
    int_fast32_t before_filter_enabled_freq_counter[NUM_MULTI_BANDS];
    // Rise factor analysis test thresholds
    int_fast32_t rise_factor_maximum_cutoff_threshold;
    int_fast32_t rise_factor_minimum_cutoff_threshold;
    // Notch filters
    //default parametric filter Q factor when creating a notch filter
    float default_filter_q;
    //gain step size in dB when a notch filter needs to be strengthened
    float incremental_filter_gain_step;
    //the deepest gain a notch filter can have
    float max_filter_gain;
    //default parametric filter gain when creating a notch filter
    float initial_filter_gain;
    //max number of times a notch filter can be adjusted each analysis process
    int_fast32_t max_num_filter_depth_adjustments_per_period;
    //feedback peak detection sensitivity, 0-music, 1-speech 
    int_fast32_t sensitivity;
    //how long a notch filter expires after creation, in sec
    float filter_reset_time;

    // --- processing variables ---
    std::unique_ptr<float[]> in_buffer;
    std::unique_ptr<float[]> fft_data;
    std::unique_ptr<fft::Fft> curr_fft;
    int fft_data_len;
    int in_buff_ptr;
    // current and previous frame's FFT db magnitudes
    std::unique_ptr<int[]> db_fft_data;
    std::unique_ptr<int[]> pre_db_fft_data;
    // for panic gain control
    float panic_recent_filters;
    float panic_gain;
    // the time at which the panic gain was last strengthened
    time_t panic_time_adjusted;

    // for spectral peak detection
    //list of peak index to output from "find_peaks"
    std::vector<int_fast32_t> final_peak_index_list;

    // feedback frequency candidate buffer
    //double-ended queue (circ buffer) containing potential feedback peak objects
    std::deque <PotentialFeedbackPeak> revolving_container; 

    // for notch filtering
    std::unique_ptr<FilterManager> filter_manager;
    int number_recent_filters_not_to_be_recycled;

    // --- processing functions ---
    void feedback_process();
    void find_peaks();
    MultibandFrequencyClassification multi_band_classification_for_this_frequency(int freq) const;
    PotentialFeedbackPeak & populate_peak_struct_from_peak_index(int peakIndex, 
        PotentialFeedbackPeak & peak) const;
    bool analyze_rise_factor(const PotentialFeedbackPeak & potential_feedback_peak, 
        const FilterManager * filter_manager) const;
    bool fundamental_satisfies_this_harmonic_test(const int i_fundamental, 
        const float harmonic_multiple, const int harmonic_threshold_db);
    bool analyze_harmonics(const PotentialFeedbackPeak & potential_feedback_peak);
    void update_panic_gain(bool feedback_found);
    bool within_frequency_margin(float f1,float f2,float frequency_error_margin_in_octaves) const;
    int number_of_times_frequency_is_in_buffer(const PotentialFeedbackPeak & peak) const;
    void add_candidate(const PotentialFeedbackPeak & newPeak);

    // --- user control parameters processing functions ---
    void update_high_freq_ignore_freq();
    void update_low_freq_ignore_freq();
    void update_max_filter_gain();

    ALGORITHM_DECLARE(FeedbackSuppression);
};

ALGORITHM_REGISTER(FeedbackSuppression, "feedback_suppression");


FeedbackSuppression::FeedbackSuppression(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);
    get_constant("fft_size", fft_size);
    get_constant("num_filters", num_filters);
    get_constant("rev_feedback_cand_freq_buf_size", rev_feedback_cand_freq_buf_size);
    get_constant("num_peaks_to_find", num_peaks_to_find);

    assign_terminal("in", &in);
    assign_terminal("out", &out);

    assign_control("low_freq_ignore_freq", &low_freq_ignore_freq, POST_FUNCTION_SCALAR(update_low_freq_ignore_freq));
    assign_control("high_freq_ignore_freq", &high_freq_ignore_freq, POST_FUNCTION_SCALAR(update_high_freq_ignore_freq));
    assign_control("max_filter_gain", &max_filter_gain, POST_FUNCTION_SCALAR(update_max_filter_gain));
    assign_control("mult_band_crossover_freq_mid", &mult_band_crossover_freq_mid);
    assign_control("mult_band_crossover_freq_high", &mult_band_crossover_freq_high);
    assign_control("mult_band_crossover_freq_superhigh", &mult_band_crossover_freq_superhigh);
    assign_control("before_filter_enabled_freq_counter_low", &before_filter_enabled_freq_counter[0]);
    assign_control("before_filter_enabled_freq_counter_mid", &before_filter_enabled_freq_counter[1]);
    assign_control("before_filter_enabled_freq_counter_high", &before_filter_enabled_freq_counter[2]);
    assign_control("before_filter_enabled_freq_counter_superhigh", &before_filter_enabled_freq_counter[3]);
    assign_control("frequency_error_margin_in_octaves_low", &frequency_error_margin_in_octaves[0]);
    assign_control("frequency_error_margin_in_octaves_mid", &frequency_error_margin_in_octaves[1]);
    assign_control("frequency_error_margin_in_octaves_high", &frequency_error_margin_in_octaves[2]);
    assign_control("frequency_error_margin_in_octaves_superhigh", &frequency_error_margin_in_octaves[3]);
    assign_control("default_filter_q", &default_filter_q);
    assign_control("incremental_filter_gain_step", &incremental_filter_gain_step);
    assign_control("initial_filter_gain", &initial_filter_gain);
    assign_control("max_num_filter_depth_adjustments_per_period", &max_num_filter_depth_adjustments_per_period);
    assign_control("sensitivity", &sensitivity);
    assign_control("filter_reset_time", &filter_reset_time);
    assign_control("f0_amplitude_th", &f0_amplitude_th);
    assign_control("rise_factor_maximum_cutoff_threshold", &rise_factor_maximum_cutoff_threshold);
    assign_control("rise_factor_minimum_cutoff_threshold", &rise_factor_minimum_cutoff_threshold);

    // fft_size warning: we are hard coding the blackman window at 
    // size = 8192 for now, so give an error if fft_size is different
    if (fft_size != 8192)
        SPDLOG_ERROR("fft_size can only be 8192 for now because the fft window is hard-coded!");

    // input buffer
    in_buffer = std::make_unique<float[]>(fft_size + get_frame_size());
    in_buff_ptr = 0;
    // Initialize FFT objects
    curr_fft = std::make_unique<fft::Fft>(fft_size);
    fft_data = std::make_unique<float[]>(fft_size);
    // default 4096
    fft_data_len = fft_size/2 + 1;
    db_fft_data = std::make_unique<int[]>(fft_data_len);
    pre_db_fft_data = std::make_unique<int[]>(fft_data_len);
    // initialize peak detection related
    final_peak_index_list.reserve(num_peaks_to_find*2); 
    // initialize panic gain related
    // the panic gain used to attenuate the whole signal (dB)
    panic_gain = 0.0f;
    // how many new notch filters are created recently
    panic_recent_filters = 0.0f;
    // initialize the filter manager
    number_recent_filters_not_to_be_recycled = static_cast<int>(num_filters * (.666f));
    filter_manager = std::unique_ptr<FilterManager>(new FilterManager(num_filters, 
        number_recent_filters_not_to_be_recycled, 0.0f, channels, get_sample_rate()));
}


void FeedbackSuppression::update_low_freq_ignore_freq()
{
    //convert from frequency in Hz to frequency index
    low_freq_ignore_freq = (int)(low_freq_ignore_freq*fft_size/get_sample_rate());
}

void FeedbackSuppression::update_high_freq_ignore_freq()
{
    //convert from frequency in Hz to frequency index
    high_freq_ignore_freq = (int)(high_freq_ignore_freq*fft_size/get_sample_rate());
}

void FeedbackSuppression::update_max_filter_gain()
{
    filter_manager->set_max_filter_gain(max_filter_gain);
}

// Get a list of potential feedback peaks,
// store in final_peak_index_list
void FeedbackSuppression::find_peaks()
{
    // clear list from last time
    final_peak_index_list.clear(); 

    // For every peak we're hoping to find
    for(int i=0; i < num_peaks_to_find; i++) 
    {
        // flag for if we found a single peak with large enough amplitude
        bool found_at_least_one_peak_higher_than_amplitude_threshold = false;
        int j_max_so_far = i; //Per loop, highest value so far
        int max_so_far = -10000000; //Any number will be higher than this max

        //Loop over db FFT Data
        for(int j=0; j < fft_data_len; j++) 
        {
            //Be sure we don't include the two FFT extrema outlined by these variables
            if((j > low_freq_ignore_freq) && (j <= high_freq_ignore_freq))
            {
                //Then, see if it's greater than the peak at jMaxSoFar of fftData
                if(db_fft_data[j] > max_so_far)	
                {
                    //Then make sure it's not the same index as ALL of the 
                    // low_freq_ignore_freqs points in final_peak_index_list
                    //innocent until proven guilty.
                    bool peak_index_already_exists_in_list = false;
                    //check if this peak is already in the list
                    for(unsigned int k=0; k < final_peak_index_list.size(); k++)
                        if(j == final_peak_index_list[k])
                            peak_index_already_exists_in_list = true;
                    //if it passes all those tests, j_max_so_far = j
                    if(!peak_index_already_exists_in_list)
                    {
                        //first see if this peak's amplitude is greater than the amplitude threshold
                        if(db_fft_data[j] >= f0_amplitude_th) 	
                        {
                            //we found a large enough peak which hasn't already been added to the list
                            found_at_least_one_peak_higher_than_amplitude_threshold = true;
                            j_max_so_far = j;
                            max_so_far = db_fft_data[j];
                        }
                    }
                }
            }
        }
        //if we found at least one peak large enough this round
        if(found_at_least_one_peak_higher_than_amplitude_threshold)
            //add index of this peak (j_max_so_far) to the vector
            final_peak_index_list.push_back(j_max_so_far); 
    }
}


// return the spectral band that corresponds to the given frequency-Hz
MultibandFrequencyClassification FeedbackSuppression::multi_band_classification_for_this_frequency(int freq) const
{
    //If low
    if(freq < mult_band_crossover_freq_mid)
    {
        return LOW;
    }
    else
    {
        //if mid
        if(freq < mult_band_crossover_freq_high)
        {
            return MID;
        }
        else
        {
            //if high
            if(freq < mult_band_crossover_freq_superhigh)
            {
                return HIGH;
            }
            //otherwise, it's super_high.
            else 
            {
                return SUPER_HIGH;
            }
        }
    }
}


// fill in the possible feedback peak information including estimated 
// frequency in Hz with the peak's frequency band index
PotentialFeedbackPeak & FeedbackSuppression::populate_peak_struct_from_peak_index(int peak_index, 
    PotentialFeedbackPeak & peak) const
{
    peak.fft_index = peak_index;

    //Using parabolic interpolation with adjacent bands to fill in frequency info of the peak
    float val = static_cast<float>(db_fft_data[peak.fft_index]);
    float lval = static_cast<float>(db_fft_data[peak.fft_index-1]);
    float rval = static_cast<float>(db_fft_data[peak.fft_index+1]);
    //interpolated peak index
    float i_peak_index;
    // avoid 0 denominator, use the original peak index if interpolation doesn't work
    if(lval- 2.0f*val +rval == 0)
    {
        i_peak_index = peak.fft_index;
    }
    else
    {
        i_peak_index  = static_cast<float>(peak.fft_index) + .5f*(lval-rval)/(lval- 2.0f*val +rval);
    }
    peak.frequency = i_peak_index * (get_sample_rate() / ((float)fft_size));
    // fill in info of the spectral band the peak belongs to
    peak.multi_band_classification = multi_band_classification_for_this_frequency(static_cast<int>(peak.frequency)); 
    // Using that multi_band_classification, update the peak's freq error margin in octaves using the enum value
    peak.frequency_error_margin_in_octaves = frequency_error_margin_in_octaves[peak.multi_band_classification];

    return peak;
}


// the rise factor test - returns if the given peak is rising moderately fast
bool FeedbackSuppression::analyze_rise_factor(const PotentialFeedbackPeak & potential_feedback_peak, 
    const FilterManager * filter_manager) const
{
    //Ratio of current amplitude to past amplitude (dB, so we subtract), all divided by FFT 
    // window time period. results in d_b rise per second
    int rise_factor = static_cast<int>((db_fft_data[potential_feedback_peak.fft_index] - 
        pre_db_fft_data[potential_feedback_peak.fft_index])/( (float)fft_size/get_sample_rate()));
    //if rise_factor is too big
    if(rise_factor > rise_factor_maximum_cutoff_threshold)
    {
        return false;
    }
    //If risefactor is too small
    //and that's not because a filter is currently at this frequency, which would explain why it's diminishing
    if((rise_factor < rise_factor_minimum_cutoff_threshold)
        && !(filter_manager->filter_exists_at_this_frequency(potential_feedback_peak)))
    {
        return false;
    }
    //Otherwise, this looks like feedback
    return true;
}


// the harmonics test - single harmonic
bool FeedbackSuppression::fundamental_satisfies_this_harmonic_test(const int i_fundamental, 
    const float harmonic_multiple, const int harmonic_threshold_db)
{
    //index of harmonic in question
    int harmonic_index = static_cast<int>((float)i_fundamental * harmonic_multiple);
    //if this harmonic would be greater than the nyquist and therefore go out of array bounds,
    if(harmonic_index > (fft_data_len-1))
    {
        //we say the fundamental passed the harmonic test this time
        return true; 
    }
    //if our fundamental is harmonic_threshold_db greater than this harmonic, our fundamental passed this harmonic test
    if( (db_fft_data[i_fundamental] - db_fft_data[harmonic_index]) >= harmonic_threshold_db)
    {
        return true;
    }
    //otherwise, it didn't pass.
    return false;
}


// the harmonics test
bool FeedbackSuppression::analyze_harmonics(const PotentialFeedbackPeak & potential_feedback_peak)
{
    //get pointer to struct we'll be using, based on the peak's multi band classification
    // harmonic_analysis_parameters *harmonic_params = &_harmonic_analysis_parameters[potential_feedback_peak.multi_band_classification];
    //analyze each harmonic. must pass all tests in order to return true
    //second harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,2,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].SECOND_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //Third harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,3,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].THIRD_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //Fourth harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,4,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].FOURTH_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //Fifth harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,5,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].FIFTH_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //NOW THE SUBHARMONICS (Partials)
    //Half harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,.5,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].HALF_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //Three halves harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,1.5,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].THREE_HALVES_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //Two thirds harmonic test
    if(!fundamental_satisfies_this_harmonic_test(potential_feedback_peak.fft_index,.66666666666666666666666f,
        harmonics_params[sensitivity][potential_feedback_peak.multi_band_classification].TWO_THIRDS_HARMONIC_COMPARISON_LEVEL))
    {
        return false;
    }
    //If it passed all of those tests, it must be feedback
    return true; 
}


// update the panic gain
// - if too many new notch filters were created recently, lower the gain
// - raise the gain back up if no new notch filter is created
// - reset the gain if it's a while since last adjustment of the gain
void FeedbackSuppression::update_panic_gain(bool feedback_found)
{
    if (feedback_found)
    {
        panic_recent_filters += 1.0f;

        // if too many new notch filters were created recently, lower the gain
        if (panic_recent_filters > PANIC_RECENT_FILTER_THRESHOLD)
        {
            if (panic_gain < 0.0f && panic_gain > MAX_PANIC_GAIN)
            {
                panic_gain += INCREMENTAL_PANIC_GAIN_STEP;
            }
            // make sure the gain is lower than the inital panic gain
            else if (panic_gain > INITIAL_PANIC_GAIN)
            {
                panic_gain = INITIAL_PANIC_GAIN;
            }
            time(&panic_time_adjusted);
            SPDLOG_TRACE("FBS Panic! {}", panic_gain);
        }
    }
    else
    {
        // gradually raise the gain back up if no new feedback peak found
        if (panic_recent_filters > 0.0f)
        {
            panic_recent_filters -= PANIC_RECENT_FILTER_DECAY;
        }
        // reset the gain to 0 if it's a while since last adjustment of the gain
        if ((panic_gain < 0.0f)
            && (difftime(time(nullptr), panic_time_adjusted) > PANIC_RELEASE_TIME))
        {
            panic_gain = 0.0f;
            SPDLOG_TRACE("FBS Panic expired");
        }
    }
}


// For the feedback candidate frequency buffer
//Function indicating whether two frequencies are within an octave range of one another
//Lookup octave constant based on f1
bool FeedbackSuppression::within_frequency_margin(float f1,float f2,float frequency_error_margin_in_octaves) const
{
    //window in freq
    float calculated_range = f1*powf(2,frequency_error_margin_in_octaves)-f1;

    if(fabs(f2-f1) < calculated_range)
    {
        return true;
    }
    return false;
}


// For the feedback candidate frequency buffer
// Check number of times given peak's frequency is in 
// the range of the each frequency in the peak candidate buffer
int FeedbackSuppression::number_of_times_frequency_is_in_buffer(const PotentialFeedbackPeak & peak) const
{
    int count = 0;
    //for each frequency currently in the revolving buffer
    for(unsigned int i=0; i<revolving_container.size(); i++)
    {
        //see if the peak's frequency is the same as this one, within an error range
        //if so, add to the count
        if(within_frequency_margin(revolving_container[i].frequency, peak.frequency, peak.frequency_error_margin_in_octaves))
        {
            count++; 
        }
    }
    return count;
}


// For the feedback candidate frequency buffer
// add a frequency candicate to the buffer
void FeedbackSuppression::add_candidate(const PotentialFeedbackPeak & new_peak)
{
    //If adding another frequency would mean exceeding the max size
    if(rev_feedback_cand_freq_buf_size < (revolving_container.size() + 1))
        //delete the oldest element (lower index)
        revolving_container.pop_front();
    //add the new element on the newest end (higher index)
    revolving_container.push_back(new_peak);
}

// Detect feedback peaks from dB FFT magnitude data.
// if a notch filter is already at a peak, increase
// the notch filter depth, otherwise create a new
// notch filter at that peak.
void FeedbackSuppression::feedback_process()
{
    // get list of indices of potential feedback peaks in FFT data
    // in final_peak_index_list
    bool feedback_found = false;
    find_peaks();
    
    // Create a struct containing all necessary data regarding a possible peak.
    PotentialFeedbackPeak potential_fb_peak;
    // For every potential feedback peak
    for(unsigned int i=0; i < final_peak_index_list.size(); i++)
    {
        //populate the struct using this method
        potential_fb_peak = populate_peak_struct_from_peak_index(final_peak_index_list[i],potential_fb_peak);

        //If this peak looks like feedback based on its riseFactor statistics
        if(analyze_rise_factor(potential_fb_peak,filter_manager.get()))
        {
            //and if this peak looks like feedback based on our harmonic analysis
            if(analyze_harmonics(potential_fb_peak))
            {
                //add it to our revolving potential feedback peak buffer
                add_candidate(potential_fb_peak);
                //if this potential feedback peak appears often enough (threshold dictated by its frequency band)
                if(number_of_times_frequency_is_in_buffer(potential_fb_peak) >=
                    before_filter_enabled_freq_counter[potential_fb_peak.multi_band_classification])
                {
                    //get possible address of filter currently at this frequency
                    const FbsFilter* existing_filter = filter_manager->filter_exists_at_this_frequency(potential_fb_peak);

                    //if filter exists already at this frequency
                    if(existing_filter)
                    {
                        //if this is a dynamic filter, we can adjust it. otherwise, leave it alone
                    	if(!(existing_filter->is_static()))
                    	{
    						//if this filter hasn't already been adjusted by max_num_filter_depth_adjustments_per_period 
                            //during this period
    						if(existing_filter->num_depth_adjustments_this_period() < max_num_filter_depth_adjustments_per_period)
    						{
    							//increase this filter's gain depth by a pre-defined incremental value
    							filter_manager->adjust_filter_depth(existing_filter,incremental_filter_gain_step);
    						}
                    	}
                    }
                    //There is not yet a filter at this frequency
                    else
                    {
                        feedback_found = true;
                        filter_manager->create_filter(potential_fb_peak.frequency,initial_filter_gain,default_filter_q);
                    }
                }
            }
        }
	}

	//Reset all filter depth adjustment counters back to 0, so they can be deepened in the next analysis period
	filter_manager->reset_all_filters_num_depth_adjustments_this_period(); 
    update_panic_gain(feedback_found);
    filter_manager->reset_expired_filters(filter_reset_time);

    //swap fft data pointers, so delayed data becomes current data
    pre_db_fft_data.swap(db_fft_data);
}


void FeedbackSuppression::process()
{
    // if fft_size input buffer filled, do detection
    // below, else proceed to apply notch filters

    // store data (on the first ch) to input buffer
    memcpy(&in_buffer[in_buff_ptr], in[0], sizeof(float)*get_frame_size());
    in_buff_ptr += get_frame_size();

    // when input buffer is filled,
    // do feedback detection,
    // reset input buffer pointer
    if(in_buff_ptr >= fft_size)
    {
        // multiply audio data by blackman window
        for(int_fast32_t i = 0; i < fft_size; i++) 
        {
            in_buffer[i] = in_buffer[i] * blackman_window_8192[i];
        }
        // apply fft
        curr_fft->forward(fft_data.get(), in_buffer.get());
        // fft data to db magnitude
        // DC
        db_fft_data[0] = 20*log10(fft_data[0]);
        // Nyquist
        db_fft_data[fft_data_len] = 20*log10(fft_data[1]);
        // the rest
        int_fast32_t band_n = 1;
        for (int_fast32_t i{2}; i < fft_size; i += 2)
        {
            db_fft_data[band_n] = 10*log10(fft_data[i]*fft_data[i] + 
                fft_data[i+1]*fft_data[i+1]);
            band_n++;
        }

        // run feedback detection algorithm,
        // update notch filters in filter manager
        feedback_process();

        // check if need to store remaining samples
        // (because fft_size % frame_size != 0)
        int buff_remain_len = in_buff_ptr - fft_size;
        if (buff_remain_len > 0) 
        {
            memcpy(&in_buffer[0], &in_buffer[fft_size], sizeof(float)*buff_remain_len);
        }
        // reset input buffer pointer
        in_buff_ptr = buff_remain_len;
    }

    // apply notch filters on all channels
    filter_manager->_iir->process(out, in, get_frame_size());

    // apply panic gain
    if (panic_gain < 0.0f)
    {
        // to linear
        float g = powf(10.0f, 0.05f * panic_gain);
        for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
        {
            for (int_fast32_t channel = 0; channel < channels; channel++)
            {
                out[channel][sample] = out[channel][sample] * g;
            }
        }
    }
}

}
