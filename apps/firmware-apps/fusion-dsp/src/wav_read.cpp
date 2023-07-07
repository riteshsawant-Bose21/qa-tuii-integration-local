
#include <bosepro/algorithm.h>

#include <sndfile.h>

#include <cstring>
#include <memory>
#include <string>
#include <vector>


namespace {


class WavRead : public bosepro::Algorithm {
public:
    WavRead(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    int channels;
    std::vector<float *> out;
    std::unique_ptr<float[]> buffer;
    SNDFILE *sndfile;

    ALGORITHM_DECLARE(WavRead);
};

ALGORITHM_REGISTER(WavRead, "wav_read");


WavRead::WavRead(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("out", channels);

    assign_terminal("out", &out);

    buffer = std::unique_ptr<float[]>(new float[get_frame_size() * channels]());

    std::string filename;
    SF_INFO sfinfo;
    get_constant("filename", filename);
    sndfile = sf_open(filename.c_str(), SFM_READ, &sfinfo);
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
