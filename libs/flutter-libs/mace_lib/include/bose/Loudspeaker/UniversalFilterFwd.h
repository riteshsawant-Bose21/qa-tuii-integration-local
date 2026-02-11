#pragma once
#ifndef UNIVERSALFILTERFWD_H
#define UNIVERSALFILTERFWD_H

#include <vector>
#include <unordered_map>
#include <bose/FilterInterface.h>

namespace bosepro::acoustics
{

	class UniversalFilter;            // forward declaration
	using UniversalFilterPtr          = std::shared_ptr<UniversalFilter>;
	using ConstUniversalFilterPtr     = std::shared_ptr<const UniversalFilter>;
	using UniversalFilters            = std::vector<UniversalFilterPtr>;    
    using MapUniversalFilterPresets   = std::unordered_map<FilterScope, UniversalFilters>; // used for stock presets.  
}

#endif // UNIVERSALFILTERFWD_H

