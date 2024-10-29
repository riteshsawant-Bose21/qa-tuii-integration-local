#include "iir.h"

#include <bosepro/algorithm.h>

#include <cstdint>


namespace {
    static const int BANDS = 31;
    static const float Q = 4.43;
    static const float ISOFrequencies[] = {
        19.952623, 25.118864, 31.722777, 39.810717, 50.118723,
        63.095734, 79.432823, 100.0, 125.89254, 158.48932,
        199.52623, 251.18864, 317.22777, 398.10717, 501.18723,
        630.95734, 794.32823, 1000.0, 1258.9254, 1584.8932,
        1995.2623, 2511.8864, 3162.2777, 3981.0717, 5011.8723,
        6309.5734, 7943.2823, 10000.0, 12589.254, 15848.932,
        19952.623
    };

class GraphicalEq : public bosepro::Algorithm

{
    public: 
        GraphicalEq(const bosepro::BlockConfiguration &configuration);
        virtual ~GraphicalEq() = default;

        virtual void process() override;

    private:
        int_fast32_t channels;

        bosepro::DspSignalMemory<const float *[]> in;
        bosepro::DspSignalMemory<float *[]> out;
        bosepro::DspStateMemory<filter::IirFilter> iir;

        bosepro::DspParamMemory<float[]> gain;

        bosepro::DspParamMemory<bool> bypass;

        void update_band(int band);
        
        ALGORITHM_DECLARE(GraphicalEq);

};

ALGORITHM_REGISTER(GraphicalEq, "graphical_eq");


GraphicalEq::GraphicalEq(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_constant("channels", channels);

    assign_control("gain", gain, POST_FUNCTION_VECTOR(update_band));


    new (iir.get()) filter::IirFilter(BANDS, channels);
}

void GraphicalEq::process()
{
    iir->process(out.get(), in.get(), get_frame_size());
}

void GraphicalEq::update_band(int band)
{
    iir->design_band("peq_cs", band, ISOFrequencies[band], Q, gain[band], get_sample_rate());
}

}