#pragma once

#include <spdlog/spdlog.h>

#include <map>
#include <string>


namespace bosepro {


/// A registry of objects, indexed by name.
template <typename T>
class ObjectRegistry {
public:
    /// Get an object from the registry, given its name.
    ///
    /// \param  name  The name of the object to get.
    /// \return  A pointer to the object, or `nullptr` if no object with that
    ///             name is registered.
    static T *get_object(const std::string &name)
    {
        auto it = get_registry().find(name);

        if (it != get_registry().end())
        {
            return it->second;
        }
        else
        {
            SPDLOG_ERROR("Object '{}' not registered.", name);
            return nullptr;
        }
    }


    /// Register an object with the registry.
    ///
    /// \param  name  The name of the object to register.
    /// \param  object  A pointer to the object to register.
    static void register_object(const std::string &name, T *object)
    {
        auto it = get_registry().find(name);

        if (it == get_registry().end())
        {
            get_registry()[name] = object;
        }
        else
        {
            SPDLOG_ERROR("Object '{}' already registered.", name);
        }
    }


private:
    static std::map<std::string, T *> &get_registry()
    {
        static std::map<std::string, T *> registry;
        return registry;
    }
};


} // namespace bosepro
