#pragma once

#ifndef FILTER_INTERFACE_H
#define FILTER_INTERFACE_H

#include <vector>
#include <cctype> // for tolower
#include <algorithm> // for transform

namespace bosepro::acoustics
{
	enum class FilterScope : int
	{
		Unknown = -1,
		System = 0,
		Cluster = 1,
		Loudspeaker = 2,
		AmpChannel = 3
	};

	// define strings for testing
	constexpr auto FilterScopeSystem = "System";
	constexpr auto FilterScopeSystemLC = "system";

	constexpr auto FilterScopeCluster = "Cluster";
	constexpr auto FilterScopeClusterLC = "cluster";

	constexpr auto FilterScopeLoudspeaker = "Loudspeaker";
	constexpr auto FilterScopeLoudspeakerLC = "loudspeaker";

	constexpr auto FilterScopeAmpChannel = "AmpChannel";
	constexpr auto FilterScopeAmpChannelLC = "ampchannel";

	//Get Scope as string
	static inline std::string   filterScopeToString(FilterScope scope)
	{
		std::string str;

		switch (scope)
		{
		case FilterScope::System: str = FilterScopeSystem; break;
		case FilterScope::Cluster: str = FilterScopeCluster; break;
		case FilterScope::Loudspeaker: str = FilterScopeLoudspeaker; break;
		case FilterScope::AmpChannel: str = FilterScopeAmpChannel; break;
		case FilterScope::Unknown:
		default:
			str = "";
		}

		return str;
	}

	//Get scope from string
	static inline FilterScope     filterScopeFromString(std::string str)
	{
		std::transform(str.begin(), str.end(), str.begin(), [](unsigned char c) { return static_cast<unsigned char>(std::tolower(c)); });
		FilterScope scope = FilterScope::Unknown;

		if (FilterScopeSystemLC == str)               scope = FilterScope::System;
		else if (FilterScopeClusterLC == str)         scope = FilterScope::Cluster;
		else if (FilterScopeLoudspeakerLC == str)     scope = FilterScope::Loudspeaker;
		else if (FilterScopeAmpChannelLC == str)      scope = FilterScope::AmpChannel;

		return scope;
	}

    struct FilterDataCore
    {
        FilterScope scope{FilterScope::Unknown};
        std::string type;
        std::string preset;
        double gaindB{0.0};
        double delaySecs{0.0};
        bool polarityInvert{false};
        bool custom;
    };
    
    // why two?  we only take TF data in but don't return it due to expense of decode.  
    struct FilterDataSet
	{
        FilterDataCore core;
        std::vector<double> tfReals;
        std::vector<double> tfImags;        
	};

    using FiltersData = std::vector<FilterDataCore>;

	/**
     * \class       FilterInterface
     * \brief       abstract interface for objects that need to provide filter support
     * 
     */
    class FilterInterface
	{
	public:
        FilterInterface() noexcept = default;
        virtual ~FilterInterface() noexcept = default;
        FilterInterface(const FilterInterface&) noexcept = default;
        FilterInterface(FilterInterface&&) noexcept = default;
        FilterInterface& operator=(const FilterInterface&) noexcept = default;
        FilterInterface& operator=(FilterInterface&&) noexcept = default;
        
		virtual bool                    addFilter(FilterDataSet fd)     = 0;
        virtual FiltersData             listFilters()                   = 0;
		virtual bool                    removeFilter(std::string type)  = 0;
        virtual void                    removeAllFilters()              = 0;

        static constexpr std::size_t    transferFunctionSize            = 4097;
	};
}
#endif
