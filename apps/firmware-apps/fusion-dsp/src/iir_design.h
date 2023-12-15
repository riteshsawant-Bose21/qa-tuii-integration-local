#pragma once

#include <bosepro/object_registry.h>


namespace filter {

/// Register a design method for a single-band filter type.  The provided
/// design function must call `IirFilter::set_section_coeffs()` to update the
/// coefficients for that band.  The function must have the signature:
///
/// `void iir_design_band_func(IirFilter *iir, int section, float frequency,
///                           float q, float gain_db, float sample_rate)`
///
/// where:
///
/// - `iir` is the filter to be updated.
/// - `section` is the index of the section-order section to be updated.
/// - `frequency` is the center/cutoff frequency of the filter, in Hz.
/// - `q` is the Q factor of the filter.
/// - `gain_db` is the gain of the filter, in dB.
/// - `sample_rate` is the sample rate of the system, in Hz.
///
/// \param  name  The name of the design method.  This must be a valid
///               identifier, not a string.
/// \param  function  The function that performs the design method.
#define IIR_DESIGN_BAND_REGISTER(name, function) \
    static const filter::IirDesignBand iir_design_band_func_##name(#name, function)


/// Register a design method for a multi-band filter type.  The provided design
/// function must call `IirFilter::set_section_coeffs()` to update the
/// coefficients for each updated second-order section.  The function must have
/// the signature:
///
/// `void iir_design_func(IirFilter *iir, int start_section, float frequency,
///                       int order, float sample_rate, int max_sections)`
///
/// where:
///
/// - `iir` is the filter to be updated.
/// - `start_section` is the index of the first section to be updated.
/// - `frequency` is the center/cutoff frequency of the filter, in Hz.
/// - `order` is the order of the filter.
/// - `sample_rate` is the sample rate of the system, in Hz.
/// - `max_sections` is the maximum number of second-order sections that can be
///          allocated to this filter.
///
/// If `order` is less than `2 * max_sections`, then the function must call
/// `IirFilter::set_section_coeffs()` for each unused section to disable it.
///
/// \param  name  The name of the design method.  This must be a valid
///              identifier, not a string.
/// \param  function  The function that performs the design method.
#define IIR_DESIGN_REGISTER(name, function) \
    static const filter::IirDesign iir_design_func_##name(#name, function)


// The code below is only to be used internally by `IirFilter`,
// `IIR_DESIGN_BAND_REGISTER()`, and `IIR_DESIGN_REGISTER()`.  When writing
// new IIR filter design methods, use only the appropriate macro above.

class IirFilter;

typedef void (*IirDesignBandFunc)(IirFilter *, int, float, float, float, float);
typedef void (*IirDesignFunc)(IirFilter *, int, float, int, float, int);


class IirDesignBand {
public:
    IirDesignBand(const std::string &name, IirDesignBandFunc function)
        : function(function)
    {
        bosepro::ObjectRegistry<IirDesignBand>::register_object(name, this);
    }

    virtual ~IirDesignBand() = default;

    IirDesignBandFunc get_function() const
    {
        return function;
    }

private:
    IirDesignBandFunc function;
};


class IirDesign {
public:
    IirDesign(const std::string &name, IirDesignFunc function)
        : function(function)
    {
        bosepro::ObjectRegistry<IirDesign>::register_object(name, this);
    }

    virtual ~IirDesign() = default;

    IirDesignFunc get_function() const
    {
        return function;
    }

private:
    IirDesignFunc function;
};


} // namespace filter
