
#include "message_player.h"

#include <bosepro/algorithm.h>
#include <bosepro/message_spec.h>

#include <sndfile.h>

#include <cstring>
#include <string>




ALGORITHM_REGISTER(MessagePlayer, "message_player");

std::set<std::string> MessagePlayer::player_names;


MessagePlayer::MessagePlayer(const bosepro::BlockConfiguration &configuration)
    : bosepro::Algorithm(configuration)
{
    get_terminal_num_channels("out", channels);

    assign_terminal("out", out);

    assign_parameter("zone_name", zone_name,
                     POST_FUNCTION_VECTOR(update_zone_name));
    assign_parameter("play_message", &new_message,
                     POST_FUNCTION_SCALAR(update_play_message));

    buffer.resize(get_frame_size());

    player_names.insert(this->get_block_name());
}


MessagePlayer::~MessagePlayer()
{
    player_names.erase(this->get_block_name());
}


void MessagePlayer::update_zone_name(int index)
{
    for (const auto &pair : zone_map)
    {
        if (pair.second == index)
        {
            zone_map.erase(pair.first);
            break;
        }
    }

    if (!zone_name[index].empty())
    {
        zone_map[zone_name[index]] = index;
    }
}

void MessagePlayer::update_play_message()
{
    SPDLOG_INFO("New play_message: {}", new_message);
    if (new_message.empty())
    {
        return;
    }

    std::stringstream ss;
    ss << new_message;

    try
    {
        bosepro::MessageSpec ms = bosepro::MessageSpec(ss);
        uint64_t new_channel_mask = 0;

        if (ms.has_zone_names())
        {
            std::set<std::string> message_zones;
            ms.get_zone_names(message_zones);

            new_channel_mask = 0;
            for (const auto &zone : message_zones)
            {
                auto it = zone_map.find(zone);
                if (it != zone_map.end())
                {
                    new_channel_mask |= (1ULL << it->second);
                }
            }
        }
        else
        {
            new_channel_mask = (1ULL << channels) - 1;
        }

        enqueue_message(new_channel_mask, ms.get_filename(), ms.get_priority());
    }
    catch (const std::exception &e)
    {
        SPDLOG_ERROR("Failed to parse play_message: {}", e.what());
        return;
    }
}

void MessagePlayer::enqueue_message(uint64_t channel_mask, const std::string &filename, int priority)
{
    {
        std::lock_guard<std::mutex> lock(mutex);
        MessageEntry entry = {channel_mask, filename};
        message_queue.emplace(priority, entry);
    }
}

void MessagePlayer::dequeue_message()
{
    std::unique_lock<std::mutex> lock(mutex);

    if (!message_queue.empty())
    {
        SPDLOG_INFO("Playing message");
        auto it = std::prev(message_queue.end());
        auto entry = it->second;


        SF_INFO sfinfo;
        sndfile = sf_open(entry.filename.c_str(), SFM_READ, &sfinfo);

        channel_mask = entry.channel_mask;

        if (sndfile == nullptr)
        {
            SPDLOG_ERROR("Failed to open file: {}", entry.filename.c_str());
            channel_mask = 0;
        }

        if (sfinfo.channels != 1)
        {
            SPDLOG_ERROR("File must be mono: {}", entry.filename.c_str());
            sf_close(sndfile);
            sndfile = nullptr;
            channel_mask = 0;
        }

        if (sfinfo.samplerate != get_sample_rate())
        {
            SPDLOG_ERROR("File does not match system sample rate: {}",
                         entry.filename.c_str());
            sf_close(sndfile);
            sndfile = nullptr;
            channel_mask = 0;
        }

        message_queue.erase(--message_queue.end());
    }
}


void MessagePlayer::process()
{
    // Clear file buffer in case of a short read at the end of a file.
    std::memset(buffer.get(), 0, get_frame_size() * sizeof(float));

    if (sndfile != nullptr)
    {
        sf_count_t samples_read;
        samples_read = sf_readf_float(sndfile, buffer.get(), get_frame_size());

        if (samples_read == 0)
        {
            sf_close(sndfile);
            sndfile = nullptr;
            channel_mask = 0;
        }
    }
    else
    {
        dequeue_message();
    }

    for (int channel = 0; channel < channels; channel++)
    {
        if ((channel_mask & (1ULL << channel)) != 0)
        {
            std::memcpy(out[channel], buffer.get(),
                        get_frame_size() * sizeof(float));
        }
    }
}


