
#include <bosepro/algorithm.h>

#include <cstdint>


namespace {


class HdrCombiner : public bosepro::Algorithm
{
public:
    HdrCombiner(const bosepro::BlockConfiguration &configuration);
    virtual ~HdrCombiner() = default;

    virtual void process() override;


private:
    bosepro::DspSignalMemory<const float *[]> in;
    bosepro::DspSignalMemory<float []> out;

    float branch_gain;
    float threshold;
    float branch_attenuation;

    int_fast32_t hold_time;
    int_fast32_t hold_count = 0;

    void update_branch_gain();

    ALGORITHM_DECLARE(HdrCombiner);
};

ALGORITHM_REGISTER(HdrCombiner, "hdr_combiner");


HdrCombiner::HdrCombiner(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    assign_terminal("in", in);
    assign_terminal("out", out);

    assign_parameter("branch_gain", &branch_gain,
                     POST_FUNCTION_SCALAR(update_branch_gain));
    assign_parameter("hold_time", &hold_time);
}


void HdrCombiner::process()
{
    for (int_fast32_t sample = 0; sample < get_frame_size(); sample++)
    {
        float combined = in[0][sample];

        if (std::fabs(combined) > threshold)
        {
            if (hold_count == 0)
            {
                SPDLOG_TRACE("HDR combiner: Branch U");
            }

            hold_count = hold_time;
        }
        else if (hold_count > 0)
        {
            hold_count--;

            if (hold_count == 0)
            {
                SPDLOG_TRACE("HDR combiner: Branch G");
            }
        }
        else
        {
            combined = in[1][sample] * branch_attenuation;
        }

        out[sample] = combined;
    }
}


void HdrCombiner::update_branch_gain()
{
    branch_attenuation = bosepro::db_to_linear(-branch_gain);
    threshold = 0.9f * branch_attenuation;
}


} // namespace
