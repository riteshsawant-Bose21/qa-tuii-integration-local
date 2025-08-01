#pragma once
#ifndef ENUM_H
#define ENUM_H

#include <type_traits>

namespace bosepro
{
    /**
     * \param    Function    : enumToUnderlying
     *
     * \brief       Safely convert a scoped enum to its underlying type
     *
     * \details     
     */
    template <typename T>
    constexpr auto enumToUnderlying(T t) noexcept
    {
        static_assert(std::is_enum<T>::value, "Error: expected enum type");

        return static_cast<std::underlying_type_t<T>>(t);
    }


    /**
     * \param    Macro       : DEFINE_ENUM_OPERATORS
     *
     * \brief       Macro to define bitwise operators for an enum
     *
     * \details     Macro can not be used in class/struct scope 
     *
     *               struct foo
     *               {
     *                   enum class bar{one, two};
     *               
     *                   DEFINE_ENUM_OPERATORS(bar);     //Error!
     *               };
     *               DEFINE_ENUM_OPERATORS(foo::bar);    //Correct!
     */
    #define DEFINE_ENUM_OPERATORS(T) \
    inline constexpr T  operator ~ (T  a)       noexcept {return T(  ~((std::underlying_type_t<T>)a))                                       ;} \
    inline constexpr T  operator | (T  a, T b)  noexcept {return T(   ((std::underlying_type_t<T>)a)    |   ((std::underlying_type_t<T>)b)) ;} \
    inline constexpr T  operator & (T  a, T b)  noexcept {return T(   ((std::underlying_type_t<T>)a)    &   ((std::underlying_type_t<T>)b)) ;} \
    inline constexpr T  operator ^ (T  a, T b)  noexcept {return T(   ((std::underlying_type_t<T>)a)    ^   ((std::underlying_type_t<T>)b)) ;} \
    inline           T& operator |=(T& a, T b)  noexcept {return (T&)(((std::underlying_type_t<T>&)a)   |=  ((std::underlying_type_t<T>)b)) ;} \
    inline           T& operator &=(T& a, T b)  noexcept {return (T&)(((std::underlying_type_t<T>&)a)   &=  ((std::underlying_type_t<T>)b)) ;} \
    inline           T& operator ^=(T& a, T b)  noexcept {return (T&)(((std::underlying_type_t<T>&)a)   ^=  ((std::underlying_type_t<T>)b)) ;} 

}//bosepro

#endif //ENUM_H