#pragma once
#ifndef CHANGEASPECT_H
#define CHANGEASPECT_H

#include <cstddef>
#include "Enum.h"

namespace bosepro
{
    /**
     * \class       ChangeAspect
     *
     * \brief       Simple object used for explicit (hint/mask based) ChangeMsg registration/handling. 
     * 			 See also ChangeMsg.
     *
     * \details     A defaulted static const instance is provided for scenarios where this level of abstraction 
     * 			 is not necessary. Using the default is highly efficient and avoids memory thrashing.
     * 			 ChangeAspect::DefaultChangeAspect()'s hint is ChangeAspect::hintAll (all bits enabled)
     */
    class ChangeAspect
    {
    public:
        virtual                     ~ChangeAspect()                                                             = default;

                                    ChangeAspect(std::size_t uiHint = enumToUnderlying(ChangeAspect::Hints::hintAll))        :  _hint{ uiHint } {}

                                    ChangeAspect(const ChangeAspect&)                                           = default;
                                    ChangeAspect(ChangeAspect&&)                                                = default;
        ChangeAspect&               operator=(const ChangeAspect&)                                              = default;
        ChangeAspect&               operator=(ChangeAspect&&)                                                   = default;

        //Hint/bit mask
        auto                        GetHint() const                                                             { return _hint; }
        void						SetHint(const std::size_t uiHint)                                           { _hint = uiHint; }

        //Primary comparison        
        virtual bool				Matches(const ChangeAspect& other) const                                    { return *this & other; }

        //Alt comparison            
        friend bool				    operator& (const ChangeAspect& lhs, const ChangeAspect& rhs)                { return (lhs.GetHint() & rhs.GetHint()) != 0; }
        friend auto				    operator| (const ChangeAspect& lhs, const ChangeAspect& rhs)                { return (lhs.GetHint() | rhs.GetHint()) != 0; }
                                    
        friend auto				    operator==(const ChangeAspect& lhs, const ChangeAspect& rhs)                { return lhs.GetHint() == rhs.GetHint(); }
        friend auto				    operator!=(const ChangeAspect& lhs, const ChangeAspect& rhs)                { return !(lhs == rhs); }               

        bool						operator! ()    const                                                       { return _hint == 0; }
        explicit					operator bool() const                                                       { return _hint != 0; }

        //Efficient default (All)
        static ChangeAspect         DefaultChangeAspect()
                                    {
                                        
                                        static const ChangeAspect   defaultChangeAspect;
                                        return defaultChangeAspect;
                                    }

        //All bits enabled
        enum class Hints : std::size_t          { hintAll = std::numeric_limits<std::size_t>::max() };        

    protected:
        std::size_t                 _hint;
    };
}

#endif //CHANGEASPECT_H
