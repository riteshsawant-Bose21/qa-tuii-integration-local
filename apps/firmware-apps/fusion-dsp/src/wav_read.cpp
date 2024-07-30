
#include "wav_read.h"

#include <bosepro/algorithm.h>

#include <sndfile.h>

#include <cstring>
#include <string>


namespace bosepro {


ALGORITHM_REGISTER(WavRead, "wav_read");

double WavRead::longest_file_time = 0.0;


WavRead::WavRead(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("out", channels);

    assign_terminal("out", out);

    buffer.resize(get_frame_size() * channels);

    std::string filename;
    SF_INFO sfinfo;
    get_constant("filename", filename);
    sndfile = sf_open(filename.c_str(), SFM_READ, &sfinfo);

    double file_time = (double)sfinfo.frames / sfinfo.samplerate;
    longest_file_time = (file_time > longest_file_time) ?
        file_time : longest_file_time;
}


void WavRead::process()
{
    std::memset(buffer.get(), 0, get_frame_size() * channels * sizeof(float));

    sf_readf_float(sndfile, buffer.get(), get_frame_size());

    for (int channel = 0; channel < channels; channel++)
    {
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            out[channel][sample] = buffer[sample * channels + channel];
        }
    }
}


} // namespace
