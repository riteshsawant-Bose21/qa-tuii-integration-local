
#include <bosepro/navigator.h>

#include <boost/property_tree/ptree.hpp>
#include <boost/property_tree/json_parser.hpp>

#include <set>
#include <string>
#include <type_traits>
#include <vector>


namespace bosepro {


Navigator::Navigator(const std::string &filename)
    : boost::property_tree::ptree()
{
    boost::property_tree::ptree &pt = *this;
    boost::property_tree::read_json(filename, pt);
}


Navigator::Navigator(std::stringstream &ss)
    : boost::property_tree::ptree()
{
    boost::property_tree::ptree &pt = *this;
    boost::property_tree::read_json(ss, pt);
}


bool Navigator::has_member(const std::string &member_name) const
{
    return find(member_name) != not_found();
}


const Navigator &Navigator::get_member(const std::string &member_name) const
{
    return (const Navigator &)get_child(member_name);
}


template <typename T>
void Navigator::get_member_value(const std::string &member_name, T &value) const
{
    // If T is not std::vector<std::string>, do the usual single-value read.
    if constexpr (!std::is_same<T, std::vector<std::string>>::value)
    {
        // Just retrieve a single value from the property tree.
        // get<T>() is presumably your wrapper that calls
        // m_ptree.get<T>(member_name)
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


template <typename T>
void Navigator::set_member(const std::string &member_name, const T &value)
{
    put(member_name, value);
}


template <typename T>
void Navigator::set_list(const std::string &member_name,
                         const std::vector<T> &array)
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


template <typename T>
void Navigator::set_list(const std::string &member_name,
                         const std::vector<std::vector<T>> &matrix)
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


template <typename T>
bool Navigator::try_member_value(const std::string &member_name, T &value) const
{
    boost::optional<T> v;

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


size_t Navigator::list_size(const std::string &list_name) const
{
    if (!has_member(list_name))
    {
        return 0;
    }

    return get_child(list_name).size();
}


template <typename T>
void Navigator::get_list_value(const std::string &list_name, int index, T &value) const
{
    int n = 0;

    for (auto a : get_child(list_name))
    {
        if (n == index)
        {
            value = a.second.get_value<T>();
            return;
        }

        n++;
    }

    throw std::runtime_error("List '" + list_name + "' index "
            + std::to_string(index) + " out of range.");
}


template <typename T>
void Navigator::get_list_values(const std::string &list_name, std::set<T> &value) const
{
    for (auto a : get_child(list_name))
    {
        value.insert(a.second.get_value<T>());
    }
}


template <typename T>
bool Navigator::try_list_value(const std::string &list_name, int index, T &value) const
{
    int n = 0;

    for (const auto &a : get_child(list_name))
    {
        if (n == index)
        {
            // Check for int
            if constexpr (std::is_same_v<T, int>)
            {
                auto opt_value = a.second.get_value_optional<int>();
                if (opt_value)
                {
                    value = *opt_value;
                    return true;
                }
            }
            // Check for std::string
            else if constexpr (std::is_same_v<T, std::string>)
            {
                auto opt_value = a.second.get_value_optional<std::string>();
                if (opt_value)
                {
                    // Ensure the value isn't an integer disguised as a string
                    auto int_check = a.second.get_value_optional<int>();
                    if (int_check)
                    {
                        return false;
                    }

                    value = *opt_value;
                    return true;
                }
            }

            throw std::runtime_error("Value of '" + list_name
                    + "' at index " + std::to_string(index)
                    + " is not of expected type.");
        }
        n++;
    }

    throw std::runtime_error("List '" + list_name + "' index "
            + std::to_string(index) + " out of range.");
}


bool Navigator::list_has_member(const std::string &list_name,
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


const Navigator &Navigator::list_get_member(const std::string &list_name,
                                            const std::string &member_name,
                                            const std::string &member_value) const
{
    for (auto &a : get_child(list_name))
    {
        if (a.second.count(member_name) > 0) // Boost ptree check for existing key
        {
            // Compare the value of the member with the target value
            if (a.second.get<std::string>(member_name) == member_value)
            {
                return (const Navigator &)a.second;
            }
        }
    }

    return (const Navigator &)get_child(list_name);
}


const std::string &Navigator::get_string(const std::string &member_name) const
{
    auto it = find(member_name);

    if (it == not_found())
    {
        throw std::runtime_error("Member '" + member_name + "' not found.");
    }

    return it->second.data();
}


int Navigator::get_index(const std::string &member_name) const
{
    int_fast32_t index;
    get_member_value(member_name, index);
    return static_cast<int>(index - 1);
}


int Navigator::get_count(const std::string &member_name) const
{
    int_fast32_t count;
    get_member_value(member_name, count);
    return static_cast<int>(count);
}


const std::string Navigator::serialize() const
{
    std::ostringstream oss;
    // `false` for compact JSON
    boost::property_tree::write_json(oss, *this, false);
    return oss.str();
}


#define DECLARE_TEMPLATE_NAVIGATOR_TYPES \
    X(bool) \
    X(float) \
    X(int_fast32_t) \
    X(uint64_t) \
    X(std::string)
#define X(t) \
    template void Navigator::get_member_value<t>(const std::string &member_name, \
                                                 t &value) const; \
    template void Navigator::set_member<t>(const std::string &member_name, \
                                           const t &value); \
    template void Navigator::set_list<t>(const std::string &member_name, \
                                         const std::vector<t> &array); \
    template void Navigator::set_list<t>(const std::string &member_name, \
                                         const std::vector<std::vector<t>> &matrix); \
    template bool Navigator::try_member_value<t>(const std::string &member_name, \
                                                 t &value) const; \
    template void Navigator::get_list_value<t>(const std::string &list_name, \
                                               int index, t &value) const; \
    template void Navigator::get_list_values<t>(const std::string &list_name, \
                                                std::set<t> &value) const; \
    template bool Navigator::try_list_value<t>(const std::string &list_name, \
                                               int index, t &value) const;
DECLARE_TEMPLATE_NAVIGATOR_TYPES
#undef X

template void Navigator::get_member_value<std::vector<std::string>>(const std::string &member_name, std::vector<std::string> &value) const;


} // namespace bosepro
