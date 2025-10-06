#include "navigator.h"

namespace bosepro {


/// A configuration or set of configurations.
    class Telemetry_configuration : public Navigator {
        public:
            /// Build the configuration from the given JSON file.  This is used to
            /// load entire configurations from a JSON file.
            ///
            /// @param  filename  The name of a JSON configuration file.
            Telemetry_configuration(const std::string &filename)
                : Navigator(filename)
            {
            }


            /// Build the configuration from the given JSON string.  This is used to
            /// create configurations from single JSON command strings.
            ///
            /// @param  ss  A string stream containing a JSON string.
            Telemetry_configuration(std::stringstream &ss)
                : Navigator(ss)
            {
            }

            bool check_member_present(const std::string &member_name) const
            {
                return has_member(member_name);
            }

            /// Get the value of a property or parameter setting.
            ///
            /// @param  value  The value of this property or parameter setting.
            template <typename T>
                //void get_value(const std::string& search_key, T &value) const
                bool get_value(const std::string& search_key, T &value) const
                {
                    bool ret_val = true;

                    if (has_member(search_key))
                    {
                        get_member_value(search_key, value);
                    }
                    else
                    {
                        SPDLOG_CRITICAL("Member Not Found ({})",search_key);
                        ret_val = false;
                    }
                    return ret_val;
                }

            const Telemetry_configuration& get_parameters() const
            {
                return (const Telemetry_configuration &)get_member("parameters");
            }

            const Telemetry_configuration& get_telemetry_configuration() const
            {
                return (const Telemetry_configuration &)get_member("telemetry_configuration");
            }

            template <typename T>
                bool get_config_value_vector (const std::string& name, std::vector<T>& out) const
                {
                    bool ret_val = true;
                    size_t size = list_size(name);
                    T  read_val;

                    if (has_member(name))
                    {
                        for (uint32_t idx = 0; idx < size; idx++)
                        {
                            get_list_value(name, idx, read_val);
                            out.push_back(read_val);
                        }
                    }
                    else
                    {
                        SPDLOG_CRITICAL("Member Not Found ({})",name);
                        ret_val = false;
                    }

                    return ret_val;
                }

            const std::string serialize_message() const
            {
                return serialize();
            }
};

}
