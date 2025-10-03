
#include "asrc.h"

#include <samplerate.h>
#include <spdlog/spdlog.h>


namespace asrc {

Asrc::Asrc(int channels, int frame_size, bool is_input)
    : frame_size(frame_size), is_input(is_input)
{
    int error;
    state = src_new(converter_type, channels, &error);

    if (state == nullptr)
    {
        throw std::runtime_error("Failed to create ASRC state");
    }
}


Asrc::~Asrc()
{
    if (state != nullptr)
    {
        src_delete(state);
    }
}


int Asrc::process(float *out, const float *in, int buffer_size, double ratio)
{
    SRC_DATA src_data;
    src_data.data_in = const_cast<float *>(in);
    src_data.data_out = out;
    src_data.input_frames = is_input ? buffer_size : frame_size;
    src_data.output_frames = is_input ? frame_size : buffer_size;
    src_data.src_ratio = ratio;
    src_data.end_of_input = 0;

    int err = src_process(state, &src_data);

    if (err != 0)
    {
        SPDLOG_ERROR("ASRC error: {}", src_strerror(err));
    }

    if (is_input && src_data.output_frames_gen != frame_size)
    {
        SPDLOG_ERROR("Unexpected samples generated: {}",
                     src_data.output_frames_gen);
    }

    if (!is_input && src_data.input_frames_used != frame_size)
    {
        SPDLOG_ERROR("Unexpected samples used: {}}",
                     src_data.input_frames_used);
    }

    return is_input ? src_data.input_frames_used : src_data.output_frames_gen;
}

} // namespace asrc
