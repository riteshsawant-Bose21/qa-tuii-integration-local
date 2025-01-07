#pragma once

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

#include <spdlog/spdlog.h>

#include <string>


namespace bosepro {


/// A class for navigating a property tree.  This abstracts the Boost property
/// tree class and provides some convenience methods common for navigating
/// configuration files and parameter definitions.
class Navigator : public boost::property_tree::ptree {
public:
    /// Construct a property navigator from a JSON file.  This is used to
    /// load entire configurations from files.
    ///
    /// @param  filename  The name of a JSON file.
    Navigator(const std::string &filename)
        : boost::property_tree::ptree()
    {
        boost::property_tree::ptree &pt = *this;
        boost::property_tree::read_json(filename, pt);
    }


    /// Construct a property navigator from a JSON string.  This is used to
    /// parse single JSON command strings.
    ///
    /// @param  ss  A string stream containing a JSON string.
    Navigator(std::stringstream &ss)
        : boost::property_tree::ptree()
    {
        boost::property_tree::ptree &pt = *this;
        boost::property_tree::read_json(ss, pt);
    }


protected:
    /// Test whether the property has a member of the given name.
    ///
    /// @param  member_name  The name of the member.
    /// @return  True if the property has a member of the given name, false
    ///          otherwise.
    bool has_member(const std::string &member_name) const
    {
        return find(member_name) != not_found();
    }


    /// Get the member of the given name.  The member must exist: use
    /// `has_member()` to test for its existence before calling this method.
    ///
    /// @param  member_name  The name of the member.
    /// @return  The member of the given name.
    const Navigator &get_member(const std::string &member_name) const
    {
        if (!has_member(member_name))
        {
            SPDLOG_CRITICAL("Member {} not found.", member_name);
        }
        return (const Navigator &)get_child(member_name);
    }


    /// Get the value of the member of the given name.  The member must exist:
    /// use `has_member()` to test for its existence before calling this method.
    /// The value must be convertible to the given type.
    ///
    /// @param  member_name  The name of the member.
    /// @param  value  The value of the member of the given name.
    template <typename T>
    void get_member_value(const std::string &member_name, T &value) const
    {
        if (!has_member(member_name))
        {
            SPDLOG_CRITICAL("Member {} not found.", member_name);
        }
        value = get<T>(member_name);
    }


    /// Get the value of the member of the given name, if it exists and agrees
    /// with the type of the requested value.
    ///
    /// @param  member_name  The name of the member.
    /// @param  value  The value of the member of the given name.
    /// @return  True if the member exists and has a value of the requested
    ///          type.
    template <typename T>
    bool try_member_value(const std::string &member_name, T &value) const
    {
        boost::optional<T> v;

        if (!has_member(member_name))
        {
            SPDLOG_CRITICAL("Member {} not found.", member_name);
            return false;
        }

        v = get_optional<T>(member_name);

        if (v != boost::none)
        {
            value = *v;
            return true;
        }
        else
        {
            return false;
        }
    }


    /// Get the number of elements in a list.
    ///
    /// @param  list_name  The name of the list.
    /// @return  The number of elements in the list, or 0 if it does not exist.
    size_t list_size(const std::string &list_name) const
    {
        if (!has_member(list_name))
        {
            return 0;
        }

        return get_child(list_name).size();
    }


    /// Get the value of the list member of the given name at the given index.
    /// The list must exist: use `has_member()` to test for its existence before
    /// calling this method.
    /// The value must be convertible to the given type.
    ///
    /// @param  list_name  The name of the list.
    /// @param  index  The index of the list member to retrieve.
    /// @param  value  The value of the list member of the given name and index.
    template <typename T>
    bool get_list_value(const std::string &list_name, int index, T &value) const
    {
        int n = 0;

        if (!has_member(list_name))
        {
            SPDLOG_CRITICAL("List {} not found.", list_name);
            return false;
        }

        for (auto a : get_child(list_name))
        {
            if (n == index)
            {
                value = a.second.get_value<T>();
                return true;
            }

            n++;
        }

        SPDLOG_CRITICAL("List {} index {} out of range.", list_name, index);
        return false;
    }


    /// Get the value of the member of a list of the given name at the given
    /// index, if it exists and agrees with the type of the requested value.
    ///
    /// @param  list_name  The name of the list.
    /// @param  index  The index of the list member to retrieve.
    /// @param  value  The value of the list member of the given name and index.
    /// @return  True if the member exists and has a value of the requested
    ///          type.
    template <typename T>
    bool try_list_value(const std::string &list_name, int index, T &value) const
    {
        boost::optional<T> v;
        int n = 0;

        if (!has_member(list_name))
        {
            SPDLOG_CRITICAL("List {} not found.", list_name);
            return false;
        }

        for (auto a : get_child(list_name))
        {
            if (n == index)
            {
                v = a.second.get_value_optional<T>();

                if (v != boost::none)
                {
                    value = *v;
                    return true;
                }
                else
                {
                    return false;
                }
            }

            n++;
        }

        SPDLOG_CRITICAL("List {} index {} out of range.", list_name, index);
        return false;
    }


    /// Test whether a list of properties has a member of the given name and
    /// value.
    ///
    /// @param  list_name  The name of the list of properties.
    /// @param  member_name  The name of the member.
    /// @param  member_value  The value of interest of the member.
    bool list_has_member(const std::string &list_name,
                         const std::string &member_name,
                         const std::string &member_value) const
    {
        if (!has_member(list_name))
        {
            return false;
        }

        for (auto &a : get_child(list_name))
        {
            if (a.second.get<std::string>(member_name) == member_value)
            {
                return true;
            }
        }

        return false;
    }


    /// Get the member of a list of properties which has a member with the given
    /// name and value.  The list and must exist, and must contain a property
    /// with the given member and value: use `list_has_member()` to test for
    /// their existence before calling this method.
    ///
    /// @param  list_name  The name of the list of properties.
    /// @param  member_name  The name of the member.
    /// @param  member_value  The value of interest of the member.
    /// @return  The property from the list which has a member with the given
    ///          name and value.
    const Navigator &list_get_member(const std::string &list_name,
                                     const std::string &member_name,
                                     const std::string &member_value) const
    {
        if (!has_member(list_name))
        {
            SPDLOG_CRITICAL("List {} not found.", list_name);
        }

        for (auto &a : get_child(list_name))
        {
            if (a.second.get<std::string>(member_name) == member_value)
            {
                return (const Navigator &)a.second;
            }
        }

        SPDLOG_CRITICAL("Member {} not found in list {}.", member_value,
                        list_name);

        return (const Navigator &)get_child(list_name);
    }


    /// Get the value (as a string) of the member of the given name.  The member
    /// must exist: use `has_member()` to test for its existence before calling
    /// this method.
    const std::string &get_string(const std::string &member_name) const
    {
        auto it = find(member_name);

        if (it == not_found())
        {
            SPDLOG_CRITICAL("Member {} not found.", member_name);
        }

        return it->second.data();
    }


    /// Get the value (as an integer index) of the member of the given name.
    /// If the member does not exist, return 0.
    int get_index(const std::string &member_name) const
    {
        int index = 0;

        if (has_member(member_name))
        {
            get_member_value(member_name, index);
            index--;
        }

        return index;
    }


    /// Get the value (as an integer count) of the member of the given name.
    /// If the member does not exist, return 0.
    int get_count(const std::string &member_name) const
    {
        int count = 0;

        if (has_member(member_name))
        {
            get_member_value(member_name, count);
        }

        return count;
    }
};


} // namespace bosepro
