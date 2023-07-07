
#include <bosepro/algorithm.h>

#include <sndfile.h>

#include <memory>
#include <string>
#include <vector>


namespace {


class WavWrite : public bosepro::Algorithm {
public:
    WavWrite(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

private:
    int channels;
    std::vector<const float *> in;
    std::unique_ptr<float[]> buffer;
    SNDFILE *sndfile;

    ALGORITHM_DECLARE(WavWrite);
};

ALGORITHM_REGISTER(WavWrite, "wav_write");


WavWrite::WavWrite(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("in", channels);

    assign_terminal("in", &in);

    buffer = std::unique_ptr<float[]>(new float[get_frame_size() * channels]());

    std::string filename;
    SF_INFO sfinfo;
    sfinfo.samplerate = get_sample_rate();
    sfinfo.channels = channels;
    sfinfo.format = SF_FORMAT_WAV | SF_FORMAT_PCM_16;
    get_constant("filename", filename);
    sndfile = sf_open(filename.c_str(), SFM_WRITE, &sfinfo);
}


void WavWrite::process()
{
    for (int channel = 0; channel < channels; channel++)
    {
        for (int sample = 0; sample < get_frame_size(); sample++)
        {
            buffer[sample * channels + channel] = in[channel][sample];
        }
    }

    sf_writef_float(sndfile, buffer.get(), get_frame_size());
}


} // namespace
