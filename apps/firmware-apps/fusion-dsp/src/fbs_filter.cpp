// fbs_filter.cpp
// the notch filter and filter manager classes for 
// feedback suppression
//
#include "fbs_filter.h"
#include <bosepro/algorithm.h>

#include <ctime>

// constructor
FbsFilter::FbsFilter(float frequency, float gain, float q, bool is_static, bool is_bypassed, 
	int filter_number, int num_at_time_filter_instantiated) : 
	_num_at_time_filter_instantiated(num_at_time_filter_instantiated)
{
    _number = filter_number;
	set_is_static(is_static);
    set_frequency(frequency);
    set_q(q);
    set_gain(gain);
    set_is_bypassed(is_bypassed);
	//depth of filter has not yet been changed, as filter is new
	_num_depth_adjustments_this_period = 0; 
}

int FbsFilter::get_time_since_adjusted()
{
    if (_is_bypassed || _is_static)
    {
        return 0;
    }
    else
    {
        return static_cast<int>(difftime(time(nullptr), _time_adjusted));
    }
}

void FbsFilter::print_filter_contents() const
{
	SPDLOG_TRACE("Filter#{}: Freq={}, Gain={}, Q={}, static={}, bypassed={}, num depth adjust={}",
		_number, _frequency, _gain, _q, _is_static, _is_bypassed, _num_depth_adjustments_this_period);
}

// constructor
FilterManager::FilterManager(int num_filters, int num_recent_filters_not_to_recycle, 
	float max_filter_gain, int channels, int_fast32_t fs) :
	_max_num_filters(num_filters), _num_recent_filters_not_to_recycle(num_recent_filters_not_to_recycle), 
	_max_filter_gain(max_filter_gain), _sampling_rate(fs)
{
    _total_filters_intantiated = 0;
	//pre-allocate space for filters
    _filter_container.reserve(_max_num_filters*2);
	// initialize iir filters with _max_num_filters of bands, and channels (usually 1 channel)
	_iir = std::unique_ptr<filter::IirFilter>(new filter::IirFilter(_max_num_filters,channels));
	// disable all iir bands
	for(unsigned int band=0; band < _max_num_filters; band++)
	{
		_iir->design_band("disabled", band, 0.0f, 0.0f, 0.0f, _sampling_rate);
	}
}

//Returns true if not all filters are being used
bool FilterManager::filters_available() const
{
	//If we're using fewer filters than exist
    if(_filter_container.size() < _max_num_filters)
        return true;

    return false;
}

//Checks to see if a filter exists with this exact filter number
bool FilterManager::filter_exists_at_filter_number(int filter_number)
{
	//looking at all filters
	for(unsigned int i=0; i < _filter_container.size(); i++)
		//if this is the filter we're looking for, based on the filter number
		if( _filter_container[i].number() == filter_number )
			return true;
	return false;
}


//Checks to see the lowest filter position number available,
//return -1 if filtercontainer is filled with static filters,
//when the returned number = _maxNumFilters, no filters are available. 
//Developer should check if there are any filters available after making this call
int FilterManager::find_lowest_available_filter_position()
{
	//start at the bottom
	int lowest_filter_position_available = 0;
	//static filters count
	unsigned int num_static_filters_found = 0;

	for(unsigned int i=0; i < _filter_container.size(); i++)
	{
		if(_filter_container[i].is_static())
			//count up as we find each static filter
			num_static_filters_found++;

		if(filter_exists_at_filter_number(lowest_filter_position_available))
		{
			lowest_filter_position_available++;
		}
	}

	//Protection from us trying to go out of bounds when we're using all the filters,
	//and they're all static
	if(num_static_filters_found == _max_num_filters)
		return -1;

	//NOTE: If we have "All" filters, this will return index 16. This is illegal
	return lowest_filter_position_available;
}

//remove filter based on filter number
void FilterManager::remove_filter_number(int filter_number)
{
	//looking at all filters
	for(unsigned int i=0; i < _filter_container.size(); i++)
	{
		//if this is the filter we're looking for based on filter number
		if( _filter_container[i].number() == filter_number )
		{
			//remove filter at i location from our list
			_filter_container.erase( _filter_container.begin() + i );
			 SPDLOG_TRACE("Removed filter at position: {} due to command ", filter_number);
			 break;
		}
	}
}

//Change filter # x to static or dynamic
//isStatic = True to change this filter to be static
//Change filter # x to static or dynamic
void FilterManager::change_filter_to_static_or_dynamic(int filter_number, bool is_static)
{
	// Looking at all filters
	for(unsigned int i=0; i < _filter_container.size(); i++)
	{
		//If this is the filter we're looking for, based on filer number
		if( _filter_container[i].number() == filter_number )
		{
            if (!is_static)
            {
                // Treat newly unlocked filters as if they were just created as dynamic
                // for the purpose of automatic release time.
				// filter's age is based on its most recent adjustment
                _filter_container[i].set_time_adjusted();
            }
			// change this specific filter to be static or dynamic
			_filter_container[i].set_is_static(is_static);
			SPDLOG_TRACE("Changed filter at position: {} to 'isStatic': {}, due to command ", filter_number, is_static);
			break;
		}
	}
}

// Indicate whether this filter number is in use
bool FilterManager::filter_is_in_use(int filter_number)
{
	//looking at all filters
	for(unsigned int i=0; i < _filter_container.size(); i++)
	{
		//If this is the filter we're looking for, based on filter number
		if( _filter_container[i].number() == filter_number )
		{
            return true;
		}
	}
    return false;
}

// Remove the least important filter
int FilterManager::remove_least_important_filter()
{
	//find filter to remove using prescribed algorithm
    int index_of_filter_to_remove = find_filter_with_smallest_amplitude(); 

	//error protection
    if(index_of_filter_to_remove == -1)
    {
   		SPDLOG_TRACE("In remove_least_important_filter. Returning {}", -1);
    	return -1;
    }
    int filter_number_of_filter_to_remove = _filter_container[index_of_filter_to_remove].number();

    //Give this filter a gain of 0 before it's re-written. This is a workaround for the fade, drop-out behavior when
    //Changing biquads to a significantly different frequency w/ a non-zero gain. If gain is brought to 0, there should
    //Now be no delay
    _filter_container[index_of_filter_to_remove].set_gain(0.0f);

	//Remove filter at indexOfFilterToRemove location
    _filter_container.erase(_filter_container.begin() + index_of_filter_to_remove); 
   	SPDLOG_TRACE("Removed filter at position: {} ", index_of_filter_to_remove);
	SPDLOG_TRACE("In remove_least_important_filter. Returning {}", filter_number_of_filter_to_remove);

    return filter_number_of_filter_to_remove;
}

// Identifies index of filter w/ smallest amplitude
int FilterManager::find_filter_with_smallest_amplitude() const
{
	//Where to stop looping so we don't remove any of the "most recent" filters
    int end_indexof_filter_subset_excluding_most_recent_filters = 
		_filter_container.size() - _num_recent_filters_not_to_recycle;
	//starting point for finding filter w/ minimum amplitude. If no filters found, this will be returned
    int min_index = -1;
	//indication of if we've successfully found at least one possible filter to replace
    bool filter_found = false;

    //Look for the first dynamic filter as our comparison for filter magnitudes
    //Leave after we find our first dynamic filter and use that for later
    for(int i=0; i < end_indexof_filter_subset_excluding_most_recent_filters; i++)
    {
        if(!_filter_container[i].is_static())
        {
            min_index = i;
            filter_found = true;
            break;
        }
    }
	// comparison for min filter magnitudes
    for(int i=0; i < end_indexof_filter_subset_excluding_most_recent_filters; i++)
    {
		//if filter is dynamic
        if(!_filter_container[i].is_static())
        {
            if(fabs(_filter_container[i].gain()) < fabs(_filter_container[min_index].gain()))
            {
                min_index = i;
                filter_found = true;
            }
        }
    }
    //if at this point we still haven't found a suitable filter because all the dynamics are too recent,
    //select the lowest valued dynamic filter out of the bunch, irrespective of its history.
	//if we still haven't found a suitable filter to replace
	if (!filter_found) 
	{
		//for every filter in existence
		for (unsigned int i = 0; i < _filter_container.size(); i++)
		{
			//if this filter is dynamic
			if (!_filter_container[i].is_static())
			{
				//just choose the lowest valued dynamic filter
				if ((min_index == -1)
                    || (fabs(_filter_container[i].gain()) < fabs(_filter_container[min_index].gain())))
				{
					min_index = i;
					filter_found = true;
				}
			}
		}
	}
    //if filter still not found at this point, all of our filters have been declared Static,
	//so return -1, indicating we should do nothing
	SPDLOG_TRACE("In find_filter_with_smallest_amplitude. Returning {}", min_index);
	//Return index of filter with lowest gain
    return min_index;
}

//Creates filter based on input parameters and returns filter object.
//If no filters free, deletes least important filter and makes new filter
FbsFilter* FilterManager::create_filter(float frequency, float gain, float q)
{
	//Returns -1 if all filters are used, and they're all static.
	//if there are filters available, this our new filter's index
	int new_filter_number = find_lowest_available_filter_position();

	if(new_filter_number == -1)
	{
		SPDLOG_TRACE("FBS: Tried to recycle a dynamic filter, but all filters are Static!");
		return nullptr;
	}
	//if no filters available
    if(!filters_available())
    {
		//remove least important dynamic filter and return its index
        new_filter_number = remove_least_important_filter();
        if(new_filter_number != -1)
        	SPDLOG_TRACE("Dynamic Filter # {} overwritten", new_filter_number);
    }
    //If we actually have a dynamic filter spot available and we Definitely won't be going out of bounds
    if((new_filter_number != -1) && ((unsigned int)new_filter_number < _max_num_filters))
    {
		//Running count of the number of filters instantiated
        _total_filters_intantiated++;
		//instantiate and populate new filter
        FbsFilter new_filter = FbsFilter(frequency,gain,q,false,false,new_filter_number,_total_filters_intantiated);
		//filter's age is based on its most recent adjustment
        new_filter.set_time_adjusted();
		//add our new filter to filterContainer at the back of the list
        _filter_container.push_back(new_filter);
		//set up iir band
		_iir->design_band("peq_cs", new_filter_number, frequency, q, gain, _sampling_rate);
		new_filter.print_filter_contents();
		//Return reference to the filter we just added
        return &_filter_container.back();
    }
    return nullptr;
}

// Adjust the filter's gain, making it deeper if possible
void FilterManager::adjust_filter_depth(const FbsFilter* filter, float gain_step)
{
	//de-const, because we're allowed to modify this guy
    FbsFilter* adjustable_filter = const_cast<FbsFilter*>(filter);
	//If there really is a filter here
    if(adjustable_filter)
    {
		//If we're at the exact limit, no need to send more commands
        if(adjustable_filter->gain() == _max_filter_gain)
        {
            //Do nothing
        }
		//If we're at the exact limit, no need to send more commands
        else if((adjustable_filter->gain() + gain_step) < _max_filter_gain)
        {
			//limit total gain to _maxFilterGain
            adjustable_filter->set_gain(_max_filter_gain);
			// set up iir band
			_iir->design_band("peq_cs", adjustable_filter->number(), adjustable_filter->frequency(), 
				adjustable_filter->q(), _max_filter_gain, _sampling_rate);
        }
		//Gain change is valid. Make the change for this filter
        else
        {
            adjustable_filter->set_gain(adjustable_filter->gain() + gain_step);
			// set up iir band
			_iir->design_band("peq_cs", adjustable_filter->number(), adjustable_filter->frequency(), 
				adjustable_filter->q(), adjustable_filter->gain(), _sampling_rate);

			// SPDLOG_DEBUG("------>> filter {} new adjusted gain={}", 
			// 	adjustable_filter->number(), adjustable_filter->gain());

			//Record that we've adjusted the depth of this filter
			adjustable_filter->increment_num_depth_adjustments_this_period();
			// filter's age is based on its most recent adjustment
            adjustable_filter->set_time_adjusted();
        }
    }
}

// Check if a filter already exists at this frequency, we return the filter's address. 
// If none exists, we return NULL
const FbsFilter* FilterManager::filter_exists_at_this_frequency(const PotentialFeedbackPeak & peak) const
{
    //Use within Frequency Margin, use data from Potential Feedback peak
    for(unsigned int i=0; i < _filter_container.size(); i++)
    {
        if(within_frequency_margin(_filter_container[i].frequency(), peak.frequency, 
			peak.frequency_error_margin_in_octaves))
        {
			// Return address of filter
        	return &_filter_container[i];
        }
    }
	//If filter not found, return NULL
    return nullptr;
}

//called at end of analyis period, to reset filter's depth adjustment 
//counter back at 0 for the next round
void FilterManager::reset_all_filters_num_depth_adjustments_this_period()
{
	for(unsigned int i=0; i<_filter_container.size(); i++)
	{
		_filter_container[i].reset_num_depth_adjustments_this_period();
	}
}

//Clears all filters' states, then destroys those objects
void FilterManager::reset_all_filters()
{
	for(unsigned int i=0; i< _filter_container.size(); i++)
	{
		_filter_container[i].set_gain(0);
        _filter_container[i].set_frequency(0.0f);
		// disable iir band
		_iir->design_band("disabled", _filter_container[i].number(), 0.0f, 0.0f, 0.0f, _sampling_rate);
	}
	_filter_container.clear(); //Remove all filters from list
}

//Clears all dynamic filters' states, then destroys those objects
void FilterManager::clear_all_dynamic_filters()
{
	std::vector<FbsFilter>::iterator my_filter_vector_iterator;

	//This is a tricky way of dealing with the issue
	//which occurs when you delete just one item from a vector
	for(my_filter_vector_iterator =_filter_container.begin(); my_filter_vector_iterator != _filter_container.end(); )
	{
		//if this is a dynamic filter
		if(! my_filter_vector_iterator->is_static() )
		{
			//clear it, first setting gain and freq values to nominal unused position
			my_filter_vector_iterator->set_gain(0);
			my_filter_vector_iterator->set_frequency(0.0f);
			// disable iir band
			_iir->design_band("disabled", my_filter_vector_iterator->number(), 0.0f, 0.0f, 0.0f, _sampling_rate);
			SPDLOG_TRACE("About to remove filter #{} due to serial command ", my_filter_vector_iterator->number() );
			//Remove filter at index i
			_filter_container.erase( my_filter_vector_iterator );
			my_filter_vector_iterator =_filter_container.begin();
		}
		else
			my_filter_vector_iterator++;
	}
}

// Clear any filters that are older than the specified time. 
// This prevents spurious filters from existing forever.
void FilterManager::reset_expired_filters(int reset_time)
{
	std::vector<FbsFilter>::iterator my_filter_vector_iterator;

	for(my_filter_vector_iterator =_filter_container.begin(); my_filter_vector_iterator != _filter_container.end(); )
	{
        int filter_age = my_filter_vector_iterator->get_time_since_adjusted();

		// the filter is too old
		if(filter_age > 0 && filter_age > reset_time )
		{
			//clear it, first setting gain and freq values to nominal unused position
			my_filter_vector_iterator->set_gain(0);
			my_filter_vector_iterator->set_frequency(0.0f);
			// disable iir band
			_iir->design_band("disabled", my_filter_vector_iterator->number(), 0.0f, 0.0f, 0.0f, _sampling_rate);
			SPDLOG_TRACE("About to remove filter #{} due to reset timeout: {} {}", 
				my_filter_vector_iterator->number(), filter_age, reset_time);
			//Remove filter at index i
			_filter_container.erase( my_filter_vector_iterator ); 
			my_filter_vector_iterator =_filter_container.begin();
		}
		else
			my_filter_vector_iterator++;
	}
}

//Get rid of our local filter state without actually calling messages to
//alter filters outside of the FeedbackAlgorithm context
void FilterManager::reset_local_filter_state()
{
	_filter_container.clear(); //Remove all filters from list
}

//Function indicating whether two frequencies are within an octave range of one another
//Lookup octave constant based on f1
bool FilterManager::within_frequency_margin(float f1,float f2,float frequency_error_margin_in_octaves) const
{
	//window in freq
	float calculated_range = f1*powf(2,frequency_error_margin_in_octaves)-f1;

	//float calculated_range = f1*1.0042 - f1;
    if(fabs(f2-f1) < calculated_range)
    {
        return true;
    }

    return false;
}

//Debug functions
void FilterManager::print_filter_container_contents()
{
	SPDLOG_TRACE("Printing contents of all active filters");

	int total_num_active_filters = _filter_container.size();
	int num_static = 0;

	for(unsigned int i=0; i < _filter_container.size(); i++)
	{
		if(_filter_container[i].is_static())
		{
			num_static++;
		}
	}

	SPDLOG_TRACE("{} active filters:", total_num_active_filters);
	SPDLOG_TRACE("{} static. %d dynamic", num_static, total_num_active_filters-num_static);

    for(unsigned int i=0; i < _filter_container.size(); i++)
    {
        _filter_container[i].print_filter_contents();
    }
}

