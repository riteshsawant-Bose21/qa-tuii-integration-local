#pragma once

#include <bosepro/algorithm.h>

#include <sndfile.h>

#include <memory>
#include <vector>


namespace bosepro {

class WavRead : public bosepro::Algorithm {
public:
    WavRead(const bosepro::BlockConfiguration &configuration);
    virtual void process() override;

    /// Return the length of the longest input WAV file, in seconds.
    static double longest_file_seconds()
    {
        return longest_file_time;
    }

private:
    int channels;
    std::vector<float *> out;
    std::unique_ptr<float[]> buffer;
    SNDFILE *sndfile;
    static double longest_file_time;

    ALGORITHM_DECLARE(WavRead);
};

}
