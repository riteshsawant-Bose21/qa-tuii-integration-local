
#include "iir.h"

#include <bosepro/algorithm.h>

#include <cstdint>
#include <memory>
#include <vector>

namespace {


class Peq : public bosepro::Algorithm
{
public:
    Peq(const bosepro::BlockConfiguration &configuration);
    virtual ~Peq() = default;

    virtual void process() override;


private:
    int_fast32_t channels;
    int_fast32_t bands;
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float *[]> out;
    std::unique_ptr<filter::IirFilter> iir;

    std::vector<bool> band_enable;
    std::vector<float> gain;
    std::vector<float> frequency;
    std::vector<float> q;

    void update_band(int band);

    ALGORITHM_DECLARE(Peq);
};

ALGORITHM_REGISTER(Peq, "peq");


Peq::Peq(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);
    get_constant("bands", bands);

    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_control("band_enable", &band_enable,
                   POST_FUNCTION_VECTOR(update_band));
    assign_control("gain", &gain, POST_FUNCTION_VECTOR(update_band));
    assign_control("frequency", &frequency, POST_FUNCTION_VECTOR(update_band));
    assign_control("q", &q, POST_FUNCTION_VECTOR(update_band));

    iir = std::unique_ptr<filter::IirFilter>(new filter::IirFilter(bands,
                                                                   channels));
}


void Peq::process()
{
    iir->process(out.get(), in.get(), get_frame_size());
}


void Peq::update_band(int band)
{
    if (band_enable[band])
    {
        iir->design_band("peq_cs", band, frequency[band], q[band], gain[band],
                         get_sample_rate());
    }
    else
    {
        iir->design_band("disabled", band, 0.0, 0.0, 0.0, get_sample_rate());
    }
}


} // namespace
