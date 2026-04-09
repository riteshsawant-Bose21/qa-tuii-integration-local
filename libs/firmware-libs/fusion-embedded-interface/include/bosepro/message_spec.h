#pragma once

#include <bosepro/navigator.h>

#include <set>
#include <sstream>
#include <string>


namespace bosepro {


/// Contains the specification for an audio message to be played back over
/// one or more zones.
class MessageSpec : public Navigator {
public:
    /// Create a message specification from a JSON string.
    ///
    /// @param  A JSON string specifying a message to be played back.
    MessageSpec(std::stringstream &ss);


    /// Get the filename associated with the message to be played back.
    ///
    /// @return The full path of the file to be played back.
    const std::string &get_filename() const;


    /// Get the numerical priority level of the message.
    ///
    /// @return  The priority level of the message.
    int get_priority() const;


    /// Check whether this message specification includes zone names for where
    /// the message is to be played back.  If the list of zone names is omitted
    /// or is specified as "all", this returns false.
    ///
    /// @return  True if the message specification has a list of zone names.
    bool has_zone_names() const;


    /// Get the list of names of zones to which the message is to
    /// be played in.
    void get_zone_names(std::set<std::string> &zone_names) const;
};


}  // namespace bosepro
