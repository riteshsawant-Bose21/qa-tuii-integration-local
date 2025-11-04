#pragma once

#include <bosepro/navigator.h>

#include <sstream>
#include <string>


namespace bosepro {

class MessageSpec : public Navigator {
public:
    MessageSpec(std::stringstream &ss)
        : Navigator(ss)
    {
    }

    const std::string &get_filename() const
    {
        return get_string("path");
    }

    int get_priority() const
    {
        int priority;
        get_member_value("priority", priority);
        return priority;
    }

    bool has_zone_names() const
    {
        if (!has_member("zones"))
        {
            return false;
        }

        std::string value;

        if (try_member_value("zones", value))
        {
            return value != "all";
        }

        return true;
    }

    void get_zone_names(std::set<std::string> &zone_names) const
    {
        get_list_values("zones", zone_names);
    }
};



}  // namespace bosepro
