#pragma once

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

#include <spdlog/spdlog.h>

#include <string>
#include <type_traits>


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
    /// Default constructor
    Navigator()
        : boost::property_tree::ptree()
    {
    }


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
        // First, check that the member exists
        if (!has_member(member_name))
        {
            SPDLOG_CRITICAL("Member '{}' not found.", member_name);
        }

        // If T is not std::vector<std::string>, do the usual single-value read.
        if constexpr (!std::is_same<T, std::vector<std::string>>::value)
        {
            // Just retrieve a single value from the property tree.
            // get<T>() is presumably your wrapper that calls m_ptree.get<T>(member_name)
            value = get<T>(member_name);
        }
        else
        {
            // Here, T is std::vector<std::string>, so we expect multiple child nodes.

            // Clear the vector to ensure it's empty before we start populating it.
            value.clear();

            // Get the child tree under 'member_name'.
            // If you prefer optional-based checks, you could do get_child_optional instead.
            auto &subtree = get_child(member_name);

            // Now iterate over all child nodes. Each child is presumably a string entry.
            for (auto &kv : subtree)
            {
                // kv.first is the child’s name (often empty if it’s an array-like structure).
                // kv.second is the ptree node containing the data for that child.
                value.push_back(kv.second.get_value<std::string>());
            }
        }
    }



    /// Set the value of the member of the given name.  The member must exist:
    /// use `has_member()` to test for its existence before calling this method.
    /// The value must be convertible to the given type.
    ///
    /// @param  member_name  The name of the member.
    /// @param  value  The value to set the member of the given name.
    template <typename T>
    void set_member(const std::string &member_name, const T &value)
    {
        if (!has_member(member_name))
        {
            SPDLOG_CRITICAL("Member {} not found.", member_name);
        }

        put(member_name, value);
    }


    /// Set an array in the property tree.
    /// This method creates or replaces a member with the given name, setting its value as an array.
    ///
    /// @param member_name The name of the member.
    /// @param array The array to set as the member value.
    template <typename T>
    void set_list(const std::string &member_name, const std::vector<T> &array)
    {
        // Create a property tree node for the array
        boost::property_tree::ptree array_node;

        // Add each element of the vector to the node
        for (const auto &value : array)
        {
            boost::property_tree::ptree element_node;
            element_node.put("", value);  // Use an empty key for array elements
            array_node.push_back(std::make_pair("", element_node));
        }

        // Set the array node in the property tree
        put_child(member_name, array_node);
    }


    /// Set a matrix in the property tree.
    /// This method creates or replaces a member with the given name, setting its value as a matrix.
    ///
    /// @param member_name The name of the member.
    /// @param matrix The matrix to set as the member value.
    template <typename T>
    void set_list(const std::string &member_name, const std::vector<std::vector<T>> &matrix)
    {
        boost::property_tree::ptree outer_array_node;
        for (const auto &row : matrix)
        {
            boost::property_tree::ptree row_node;
            for (const auto &val : row)
            {
                boost::property_tree::ptree val_node;
                val_node.put("", val);
                row_node.push_back(std::make_pair("", val_node));
            }
            outer_array_node.push_back(std::make_pair("", row_node));
        }

        put_child(member_name, outer_array_node);
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
    bool try_list_value(const std::string &list_name, int index, T &value) const {
        int n = 0;

        if (!has_member(list_name)) {
            SPDLOG_CRITICAL("List {} not found.", list_name);
            return false;
        }

        for (const auto &a : get_child(list_name)) {
            if (n == index) {
                // Check for int
                if constexpr (std::is_same_v<T, int>) {
                    auto opt_value = a.second.get_value_optional<int>();
                    if (opt_value) {
                        value = *opt_value;
                        return true;
                    }
                }
                // Check for std::string
                else if constexpr (std::is_same_v<T, std::string>) {
                    auto opt_value = a.second.get_value_optional<std::string>();
                    if (opt_value) {
                        // Ensure the value isn't an integer masquerading as a string
                        auto int_check = a.second.get_value_optional<int>();
                        if (int_check) {
                            return false;
                        }

                        value = *opt_value;
                        return true;
                    }
                } else {
                    SPDLOG_CRITICAL("Unsupported type requested.");
                    return false;
                }

                SPDLOG_WARN("Value at index {} is not of expected type.", index);
                return false;
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
    /// name and value. The list and member must exist, and must contain a property
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
            if (a.second.count(member_name) > 0)  // Boost ptree check for existing key
            {
                // Compare the value of the member with the target value
                if (a.second.get<std::string>(member_name) == member_value)
                {
                    return (const Navigator &)a.second;
                }
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


    /// Get the serialized Navigator (ptree/json blob)
    ///
    /// @return The string with the serialized json
    const std::string serialize() const
    {
        std::ostringstream oss;
        boost::property_tree::write_json(oss, *this, false); // `false` for compact JSON
        return oss.str();
    }
};


} // namespace bosepro
