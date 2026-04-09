
#include <bosepro/message_spec.h>

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
        return false;
    }

    std::string value;

    if (try_member_value("zones", value))
    {
        return value != "all";
    }

    return true;
}


void MessageSpec::get_zone_names(std::set<std::string> &zone_names) const
{
    get_list_values("zones", zone_names);
}


}  // namespace bosepro
