#pragma once

#include <bosepro/algorithm.h>
#include <bosepro/message_spec.h>

#include <sndfile.h>

#include <string>


class MessagePlayer : public bosepro::Algorithm {
public:
    MessagePlayer(const bosepro::BlockConfiguration &configuration);
    virtual ~MessagePlayer();
    virtual void process() override;

    static const std::set<std::string> &get_player_names()
    {
        return player_names;
    }

private:
    typedef struct {
        uint64_t channel_mask;
        std::string filename;
    } MessageEntry;
    static std::set<std::string> player_names;

    int channels;
    bosepro::DspSignalMemory<float *[]> out;
    bosepro::DspTempMemory<float[]> buffer;
    bosepro::DspParamMemory<std::string []> zone_name;
    std::string new_message;
    SNDFILE *sndfile = nullptr;
    uint64_t channel_mask;

    std::unordered_map<std::string, int> zone_map;
    std::multimap<int, MessageEntry> message_queue;
    std::mutex mutex;
    std::condition_variable cv;

    void update_play_message();
    void update_zone_name(int index);
    void enqueue_message(uint64_t channel_mask, const std::string &filename, int priority);
    void dequeue_message();

    ALGORITHM_DECLARE(MessagePlayer);
};
