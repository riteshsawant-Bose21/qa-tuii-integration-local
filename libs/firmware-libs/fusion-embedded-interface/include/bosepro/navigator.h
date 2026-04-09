#pragma once

#include <boost/property_tree/ptree.hpp>

#include <set>
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
    Navigator(const std::string &filename);


    /// Construct a property navigator from a JSON string.  This is used to
    /// parse single JSON command strings.
    ///
    /// @param  ss  A string stream containing a JSON string.
    Navigator(std::stringstream &ss);


protected:
    /// Test whether the property has a member of the given name.
    ///
    /// @param  member_name  The name of the member.
    /// @return  True if the property has a member of the given name, false
    ///          otherwise.
    bool has_member(const std::string &member_name) const;


    /// Get the member of the given name.  The member must exist: use
    /// `has_member()` to test for its existence before calling this method.
    ///
    /// @param  member_name  The name of the member.
    /// @return  The member of the given name.
    const Navigator &get_member(const std::string &member_name) const;


    /// Get the value of the member of the given name.  The member must exist:
    /// use `has_member()` to test for its existence before calling this method.
    /// The value must be convertible to the given type.
    ///
    /// @param  member_name  The name of the member.
    /// @param  value  The value of the member of the given name.
    template <typename T>
    void get_member_value(const std::string &member_name, T &value) const;


    /// Set the value of the member of the given name.  The member must exist:
    /// use `has_member()` to test for its existence before calling this method.
    /// The value must be convertible to the given type.
    ///
    /// @param  member_name  The name of the member.
    /// @param  value  The value to set the member of the given name.
    template <typename T>
    void set_member(const std::string &member_name, const T &value);


    /// Set an array in the property tree.  This method creates or replaces a
    /// member with the given name, setting its value as an array.
    ///
    /// @param  member_name  The name of the member.
    /// @param  array  The array to set as the member value.
    template <typename T>
    void set_list(const std::string &member_name, const std::vector<T> &array);


    /// Set a matrix in the property tree.  This method creates or replaces a
    /// member with the given name, setting its value as a matrix.
    ///
    /// @param  member_name  The name of the member.
    /// @param  matrix  The matrix to set as the member value.
    template <typename T>
    void set_list(const std::string &member_name,
                  const std::vector<std::vector<T>> &matrix);


    /// Get the value of the member of the given name, if it exists and agrees
    /// with the type of the requested value.
    ///
    /// @param  member_name  The name of the member.
    /// @param  value  The value of the member of the given name.
    /// @return  True if the member exists and has a value of the requested
    ///          type.
    template <typename T>
    bool try_member_value(const std::string &member_name, T &value) const;


    /// Get the number of elements in a list.
    ///
    /// @param  list_name  The name of the list.
    /// @return  The number of elements in the list, or 0 if it does not exist.
    size_t list_size(const std::string &list_name) const;


    /// Get the value of the list member of the given name at the given index.
    /// The list must exist: use `has_member()` to test for its existence before
    /// calling this method.
    /// The value must be convertible to the given type.
    ///
    /// @param  list_name  The name of the list.
    /// @param  index  The index of the list member to retrieve.
    /// @param  value  The value of the list member of the given name and index.
    template <typename T>
    void get_list_value(const std::string &list_name, int index, T &value) const;


    /// Populate the given set with the values of the list of the given name.
    /// The list must exist: use `has_member()` to test for its existence before
    /// calling this function.
    ///
    /// @param  list_name  The name of the list.
    /// @param  value  The set to populate with the values of the list.
    template <typename T>
    void get_list_values(const std::string &list_name, std::set<T> &value) const;


    /// Get the value of the member of a list of the given name at the given
    /// index, if it exists and agrees with the type of the requested value.
    ///
    /// @param  list_name  The name of the list.
    /// @param  index  The index of the list member to retrieve.
    /// @param  value  The value of the list member of the given name and index.
    /// @return  True if the member exists and has a value of the requested
    ///          type.
    template <typename T>
    bool try_list_value(const std::string &list_name, int index, T &value) const;


    /// Test whether a list of properties has a member of the given name and
    /// value.
    ///
    /// @param  list_name  The name of the list of properties.
    /// @param  member_name  The name of the member.
    /// @param  member_value  The value of interest of the member.
    bool list_has_member(const std::string &list_name,
                         const std::string &member_name,
                         const std::string &member_value) const;


    /// Get the member of a list of properties which has a member with the given
    /// name and value. The list and member must exist, and must contain a
    /// property with the given member and value: use `list_has_member()` to
    /// test for their existence before calling this method.
    ///
    /// @param  list_name  The name of the list of properties.
    /// @param  member_name  The name of the member.
    /// @param  member_value  The value of interest of the member.
    /// @return  The property from the list which has a member with the given
    ///          name and value.
    const Navigator &list_get_member(const std::string &list_name,
                                     const std::string &member_name,
                                     const std::string &member_value) const;


    /// Get the value (as a string) of the member of the given name.  The member
    /// must exist: use `has_member()` to test for its existence before calling
    /// this method.
    ///
    /// @param  member_name  The name of the member.
    /// @return  The value of the member as a string.
    const std::string &get_string(const std::string &member_name) const;


    /// Get the value (as an integer index) of the member of the given name.
    /// This will convert the 1-based index value used in a configuration to a
    /// 0-based index for internal use.
    ///
    /// @param  member_name  The name of the member.
    /// @return  The 0-based index represented by the member value.
    int get_index(const std::string &member_name) const;


    /// Get the value (as an integer count) of the member of the given name.
    ///
    /// @param  member_name  The name of the member.
    /// @return  The integer count represented by the member value.
    int get_count(const std::string &member_name) const;


    /// Get the serialized Navigator (ptree/JSON blob)
    ///
    /// @return The string with the serialized JSON
    const std::string serialize() const;
};


} // namespace bosepro
