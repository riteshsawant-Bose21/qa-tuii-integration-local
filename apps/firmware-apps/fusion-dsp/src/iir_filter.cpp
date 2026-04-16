
#include "iir.h"

#include <bosepro/algorithm.h>

#include <cstdint>

namespace {


class IirFilter : public bosepro::Algorithm
{
public:
    IirFilter(const bosepro::BlockConfiguration &configuration);
    virtual ~IirFilter() = default;

    virtual void process() override;


private:
    int_fast32_t channels;
    int_fast32_t bands;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspStateMemory<filter::IirFilter> iir;

    bosepro::DspParamMemory<float *[]> coefficients;

    void update_coefficients(int band, int index);

    ALGORITHM_DECLARE(IirFilter);
};

ALGORITHM_REGISTER(IirFilter, "iir_filter");


IirFilter::IirFilter(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_property("channels", channels);
    get_property("bands", bands);

    assign_terminal("in", in);
    assign_terminal("out", out);

    new (iir.get()) filter::IirFilter(bands, channels);

    assign_parameter("coefficients", coefficients,
                     POST_FUNCTION_MATRIX(update_coefficients));
}


void IirFilter::process()
{
    iir->process(out.get(), in.get(), get_frame_size());
}


void IirFilter::update_coefficients(int band, int /* index */)
{
    iir->set_section_coeffs(band, coefficients[band][0],
                            coefficients[band][1], coefficients[band][2],
                            1.0, coefficients[band][3], coefficients[band][4]);
}


} // namespace
