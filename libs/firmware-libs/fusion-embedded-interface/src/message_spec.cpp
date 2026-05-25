
#include <bosepro/message_spec.h>

#include <spdlog/spdlog.h>

#include <set>
#include <sstream>
#include <string>


namespace bosepro {


MessageSpec::MessageSpec(std::stringstream &ss)
    : Navigator(ss)
{
}


const std::string &MessageSpec::get_filename() const
{
    return get_string("path");
}


int MessageSpec::get_priority() const
{
    int_fast32_t priority;
    get_member_value("priority", priority);
    return static_cast<int>(priority);
}


bool MessageSpec::has_zone_names() const
{
    if (!has_member("zones"))
    {
        SPDLOG_DEBUG("No \"zones\" in playback message, assuming all.");
        return false;
    }

    std::string value;

    if (list_size("zones") == 0)
    {
        if (try_member_value("zones", value))
        {
            if (value == "all")
            {
                SPDLOG_DEBUG("Playback message \"zones\" set to \"all\".");
                return false;
            }
            else if (value == "null")
            {
                SPDLOG_DEBUG("Playback message \"zones\" set to null, assuming all.");
                return false;
            }
            else if (value.empty())
            {
                SPDLOG_DEBUG("Empty \"zones\" in playback message, assuming all.");
                return false;
            }
        }
        else
        {
            SPDLOG_DEBUG("Empty \"zones\" list in playback message, assuming all.");
            return false;
        }
    }
    else if (list_size("zones") == 1)
    {
        if (try_list_value("zones", 0, value))
        {
            if (value == "all")
            {
                SPDLOG_DEBUG("Playback messages \"zones\" set to [\"all\"].");
                return false;
            }
            else if (value == "null")
            {
                SPDLOG_DEBUG("Playback messages \"zones\" set to [null].");
                return false;
            }
        }
    }

    return true;
}


void MessageSpec::get_zone_names(std::set<std::string> &zone_names) const
{
    std::string value;

    if (list_size("zones") > 0)
    {
        SPDLOG_DEBUG("Populating playback message zones from list.");
        get_list_values("zones", zone_names);
    }
    else if (try_member_value("zones", value))
    {
        SPDLOG_DEBUG("Populating playback message zones from string: {}",
                value.c_str());
        zone_names.insert(value);
    }
}


}  // namespace bosepro
