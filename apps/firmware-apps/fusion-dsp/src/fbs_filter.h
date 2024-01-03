// fbs_filter.h
// the notch filter and the filter manager classes for 
// feedback suppression
//
#include <iostream>
#include <vector>
#include <math.h>
#include <ctime>
#include "fbs_structs.h"
#include "iir.h"


using namespace std;

//Class declaration for single parametric filter
class FbsFilter
{
protected:
    //gain of filter
    float _gain;
    //frequency of filter
    float _frequency;
    //Q (bandwidth) of filter
    float _q;
    //if true, this filter is static, not dynamic, so it shall not be recycled
    bool _is_static;
    //if true, filter is bypassed, but still allocated and potentially momentarily activated within the audio stream
    bool _is_bypassed; 
    //number of times this filter's depth has been changed 
	unsigned int _num_depth_adjustments_this_period;
    //identifier for this filter's unique number. number set at instantiation and does not change, even if filter re-used.
    //corresponds to the band number of the iir filter object
    int _number;
    //from 1 to infinity - the unique number of this filter at the time of its instantiation, to see which filters are recent.
    //the higher the number, the later it was created
    int _num_at_time_filter_instantiated; 
    // the time at which the filter's depth was last increased
    time_t _time_adjusted; 

public:

    //Cotr
    FbsFilter(float frequency, float gain, float q, bool is_static, bool is_bypassed, int filter_number, int num_at_time_filter_instantiated);

    //Detr
    ~FbsFilter() {}

    //getters
    float gain() const { return _gain;}
    float frequency() const { return _frequency;}
    float q() const { return _q;}
    bool is_bypassed() const { return _is_bypassed;}
    bool is_static() const { return _is_static;}
    int number() const { return _number; }
	int num_depth_adjustments_this_period() const { return _num_depth_adjustments_this_period;}
    int num_at_time_filter_instantiated() const { return _num_at_time_filter_instantiated; }

    //setters - These will update the local copy of FBS algorithm's state
    void set_gain(float gain) { _gain = gain;}
    void set_frequency(float frequency) { _frequency = frequency;}
    void set_q(float q) { _q = q;}
    void set_is_static(bool is_static) {_is_static = is_static;}
    void set_is_bypassed(bool is_bypassed) { _is_bypassed = is_bypassed;}

    //other
	void increment_num_depth_adjustments_this_period() { _num_depth_adjustments_this_period++;}
	void reset_num_depth_adjustments_this_period() { _num_depth_adjustments_this_period = 0;}
    void set_time_adjusted() { time(&_time_adjusted); }
    int get_time_since_adjusted();

    //info
    void print_filter_contents() const;
};


//Set of parametric filters for one channel. Manages behavior of filters
class FilterManager
{
protected:
    //Number of filters
    int unsigned _max_num_filters;
    //Number of recent dynamic filters not to recycle
    int unsigned _num_recent_filters_not_to_recycle;
    //the lowest filter gain in dB
    float _max_filter_gain;
    //Number of filters instantiated so far. Helps to keep track of what filters are recent
    int _total_filters_intantiated;
    //vector - container of filters
    vector <FbsFilter> _filter_container;
    //sampling frequency of input signal
    int_fast32_t _sampling_rate;

    //returns true if not all filters are being used
    bool filters_available() const;
    //identifies index of filter w/ smallest amplitude
    int find_filter_with_smallest_amplitude() const;
    //internal function used to calculate error tolerance from fft data
    bool within_frequency_margin(float f1,float f2,float frequency_error_margin_in_octaves) const;
    //remove least important filter, private method used by create_filter()
    int remove_least_important_filter();
    //checks to see if a filter exists with this exact filter number
    bool filter_exists_at_filter_number(int filter_number);
    //returns the lowest available filter position
    int find_lowest_available_filter_position();

public:
    // the actual notch filters to apply
    std::unique_ptr<filter::IirFilter> _iir;

    //Cotr
    FilterManager(int _num_filters, int _num_recent_filters_not_to_recycle, float _max_filter_gain, int channels, int_fast32_t fs);

    //Detr
    ~FilterManager() {};

    //Get rid of our local filter state without actually calling messages to
    //alter filters outside of the FeedbackAlgorithm context
    void reset_local_filter_state();

    //remove filter according to filter #
    void remove_filter_number(int filter_number);

    //change filter # x to static or dynamic
    // is_static = true to change this filter to be static
    void change_filter_to_static_or_dynamic(int filter_number, bool is_static);

    //Creates filter based on input parameters and returns filter object.
    //If no filters free, deletes least important filter and makes new filter
    FbsFilter* create_filter(float frequency, float gain, float q);

    //If a filter already exists at this frequency, we return the filter's address. If none exists, we return NULL
    const FbsFilter * filter_exists_at_this_frequency(const PotentialFeedbackPeak & peak) const;

    //If user has only a pointer to the filter, we adjust the depth of the filter at end of pointer
    void adjust_filter_depth(const FbsFilter* filter, float gain_step);

	//called at end of analyis period, to reset filter's depth adjustment counter back at 0 for the next round
	void reset_all_filters_num_depth_adjustments_this_period();

    //setters for changing internal state from outside
    void set_num_recent_filters_not_to_recycle(const int NUMBER_RECENT_FILTERS_NOT_TO_BE_RECYCLED)
        { _num_recent_filters_not_to_recycle = NUMBER_RECENT_FILTERS_NOT_TO_BE_RECYCLED; }
    void set_max_filter_gain(const float MAX_FILTER_GAIN) { _max_filter_gain = MAX_FILTER_GAIN; }
    void set_max_filter_gain(int gain) { _max_filter_gain = gain;}

    //debug
    void print_filter_container_contents();

    //clears all filters' states, then destroys those objects
    void reset_all_filters();

    //clears all dynamic filters' states, then destroys those objects
    void clear_all_dynamic_filters();

    // reset dynamic filters that have not been updated for a specified time
    void reset_expired_filters(int reset_time);

    // true if filter is used (dynamic or static) regardless of bypass
    bool filter_is_in_use(int filter_number);
};