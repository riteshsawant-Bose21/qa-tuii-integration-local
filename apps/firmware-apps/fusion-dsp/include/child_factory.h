#pragma once

#include <spdlog/spdlog.h>

#include <map>
#include <string>


namespace bosepro {


template <class Parent, typename ArgType> class ChildCreator;


/// A factory for creating children of a parent class using a string name.
template <class Parent, typename ArgType>
class ChildFactory {
public:
    /// Create a child of the parent class with the given name.
    ///
    /// @param  child_name  The name of the child to create.
    /// @param  arg  The argument to pass to the child's constructor.
    static Parent *create_child(const std::string &child_name, ArgType arg)
    {
        auto it = get_registry().find(child_name);

        if (it != get_registry().end())
        {
            return it->second->create(arg);
        }
        else
        {
            SPDLOG_ERROR("Unknown child name: {}", child_name);
            return nullptr;
        }
    }


    /// Register a child creator with the factory.  This shouldn't be called
    /// directly.  Use `CHILD_FACTORY_REGISTER()` instead.
    ///
    /// @param  child_name  The name of the child to register.
    /// @param  creator  The creator for the child.
    static void register_child(const std::string &child_name,
                               ChildCreator<Parent, ArgType> *creator)
    {
        auto it = get_registry().find(child_name);

        if (it == get_registry().end())
        {
            get_registry()[child_name] = creator;
        }
        else
        {
            SPDLOG_ERROR("Duplicate child name: {}", child_name);
        }
    }

private:
    static std::map<std::string, ChildCreator<Parent, ArgType> *> &get_registry()
    {
        static std::map<std::string, ChildCreator<Parent, ArgType> *> registry;
        return registry;
    }
};


/// A creator for a child of a parent class.  Don't use this directly.  Use
/// `CHILD_FACTORY_DECLARE()` and `CHILD_FACTORY_REGISTER()` instead.
template <class Parent, typename ArgType>
class ChildCreator {
public:
    ChildCreator<Parent, ArgType>(const std::string &child_name)
    {
        ChildFactory<Parent, ArgType>::register_child(child_name, this);
    }

    virtual ~ChildCreator<Parent, ArgType>() = default;

    virtual Parent *create(ArgType arg) const = 0;
};


/// A creator for a child of a parent class.  Don't use this directly.  Use
/// `CHILD_FACTORY_DECLARE()` and `CHILD_FACTORY_REGISTER()` instead.
template <class Parent, class Child, typename ArgType>
class ChildCreatorImpl : public ChildCreator<Parent, ArgType> {
public:
    ChildCreatorImpl<Parent, Child, ArgType>(const std::string &child_name)
        : ChildCreator<Parent, ArgType>(child_name)
    {
    }

    virtual ~ChildCreatorImpl<Parent, Child, ArgType>() = default;

    virtual Parent *create(ArgType arg) const override
    {
        return new Child(arg);
    }
};


/// Declare a child factory for a parent class.  This should be used at the end
/// of the class definition.
///
/// @param  parent  The parent class.
/// @param  child  The child class.
/// @param  argtype  The type of the argument to the child's constructor.
#define CHILD_FACTORY_DECLARE(parent, child, argtype) \
    private: \
        static const bosepro::ChildCreatorImpl<parent, child, argtype> creator


/// Register a child factory for a parent class.  This should appear in the
/// source file for the child class.
///
/// @param  parent  The parent class.
/// @param  child  The child class.
/// @param  argtype  The type of the argument to the child's constructor.
/// @param  child_name  The name of the child that is used to look up the child.
#define CHILD_FACTORY_REGISTER(parent, child, argtype, child_name) \
    const bosepro::ChildCreatorImpl<parent, child, argtype> child::creator(child_name)


} // namespace bosepro
