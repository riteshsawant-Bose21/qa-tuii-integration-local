#pragma once
#ifndef ANGLE_H
#define ANGLE_H

#include <cassert>
#include "MathUtils.h"
#include "FuzzyCompare.h"

/**
 * \brief	math contains various math related classes as well as 3d geometry classes.
 *
 * \ingroup	math
 */
namespace bosepro::math
{
    /**
        * \class       Angle
        *
        * \brief       Object to represent an angle and ease the typical conversion and unit confusion / angst
        *
        * \details     This object is immutable sans cctor/mmtor and operator=
        */
    class Angle final
    {
    public:
        enum class					Units{Radians, Degrees};

                                    ~Angle()                                                noexcept = default;
        constexpr                   Angle(double val = 0.0, Units ut = Units::Radians)      noexcept : value(toRadians(val, ut)) {}
        constexpr                   Angle(float  val,       Units ut = Units::Radians)      noexcept : Angle(static_cast<double>(val), ut) {}
        constexpr                   Angle(int    val,       Units ut = Units::Radians)      noexcept : Angle(static_cast<double>(val), ut) {}
        constexpr                   Angle(const Angle& other)                               noexcept = default;
        constexpr                   Angle(Angle&& other)                                    noexcept = default;

        Angle&                      operator=(const Angle& other)                           noexcept = default;
        Angle&                      operator=(Angle&& other)                                noexcept = default;

        constexpr Angle             operator-()                                     const   noexcept {return Angle(-value);}

        constexpr friend Angle      operator+(const Angle& lhs, const Angle& rhs)           noexcept {return Angle(lhs.value + rhs.value);}
        constexpr friend Angle      operator-(const Angle& lhs, const Angle& rhs)           noexcept {return Angle(lhs.value - rhs.value);}
        constexpr friend Angle      operator*(const Angle& lhs, const Angle& rhs)           noexcept {return Angle(lhs.value * rhs.value);}
        constexpr friend Angle      operator/(const Angle& lhs, const Angle& rhs)           noexcept {return isApproximatelyZero(lhs.value) || isApproximatelyZero(rhs.value) ? Angle(0.0) : Angle(lhs.value / rhs.value);}

        constexpr friend bool       operator==(const Angle& lhs, const Angle& rhs)          noexcept {return isApproximatelyEqual(lhs.value, rhs.value);}
        constexpr friend bool       operator!=(const Angle& lhs, const Angle& rhs)          noexcept {return !(lhs == rhs);}
        constexpr friend bool       operator< (const Angle& lhs, const Angle& rhs)          noexcept {return lhs.value < rhs.value;}
        constexpr friend bool       operator> (const Angle& lhs, const Angle& rhs)          noexcept {return rhs < lhs;}
        constexpr friend bool       operator<=(const Angle& lhs, const Angle& rhs)          noexcept {return !(lhs > rhs);}
        constexpr friend bool       operator>=(const Angle& lhs, const Angle& rhs)          noexcept {return !(lhs < rhs);}

        constexpr friend int        compare(const Angle& lhs, const Angle& rhs)             noexcept {return lhs.value > rhs.value ? 1 : (lhs.value < rhs.value ? -1 : 0);}

                                    //Underlying type accessor
        constexpr double            radians()                                       const   noexcept {return value;}
        constexpr double            degrees()                                       const   noexcept {return math::ConvertRadiansToDegrees<double>(value);}

        template <typename T> T     radians()                                       const   noexcept {return static_cast<T>(radians()); static_assert(std::is_arithmetic_v<T>);}
        template <typename T> T     degrees()                                       const   noexcept {return static_cast<T>(degrees()); static_assert(std::is_arithmetic_v<T>);}

                                    //Trig helpers
        template <typename T> T     cos()                                           const            {return static_cast<T>(std::cos(value)); static_assert(std::is_arithmetic_v<T>);}
        template <typename T> T     sin()                                           const            {return static_cast<T>(std::sin(value)); static_assert(std::is_arithmetic_v<T>);}
        template <typename T> T     tan()                                           const            {return static_cast<T>(std::tan(value)); static_assert(std::is_arithmetic_v<T>);}

        inline Angle                abs()                                           const   noexcept {return Angle(std::abs(value));}

                                    //Wrapping
        enum class                  Wrap{pi, pi2};

        Angle                       wrap(Wrap to = Wrap::pi2)                       const   noexcept {return Angle(wrap(value, to));}

                                    //Non-wrapping
        Angle						clamp(const Angle& lo, const Angle& hi)         const   noexcept {return math::Clamp(*this, lo, hi);}


                                    //Oiler angles
        enum class                  Euler{Roll, Pitch, Yaw};

                                    //Euler angle constraints
        static void                 getEulerLimits(Euler type, Angle& lo, Angle& hi)
                                    {
                                        switch(type)
                                        {
                                            case Euler::Roll:
                                                lo = Angle(-math::rad180<double>);
                                                hi = Angle( math::rad180<double>);
                                                break;

                                            case Euler::Yaw:
                                                lo = Angle(-math::rad180<double>);
                                                hi = Angle( math::rad180<double>);
                                                break;

                                            case Euler::Pitch:
                                                lo = Angle(-math::rad90<double>);    //The industry uses negative pitch for down and positive pitch for up. 
                                                hi = Angle( math::rad90<double>);    //This is non-standard and is problematic. Thus it is a display function.
                                                break;                               //These values are simply for bounds testing and have no directional context.

                                            default:
                                                assert(0);
                                        }
                                    }

                                    //Validate Euler angle (clamp is non-wrapping)
        static bool                 isValidEuler(Angle& a, Euler type, bool clamp = false)
                                    {
                                        Angle lo, hi;

                                        getEulerLimits(type, lo, hi);

                                        bool valid = lo <= a && a <= hi;

                                        if(!valid && clamp)
                                        {
                                            a = a.clamp(lo, hi);
                                        }

                                        return valid;
                                    }

    protected:
                                    //Wrap to pi or 2pi
        static double               wrap(double radians, Wrap to)
                                    {
                                        if(!std::isnormal(radians))
                                        {
                                            return radians;
                                        }

                                        if(Wrap::pi == to)
                                        {
                                            radians += math::piT<double>;
                                        }

                                        radians = std::fmod(radians, math::DoublePi<double>);

                                        if(radians < 0.0)
                                        {
                                            radians += math::DoublePi<double>;
                                        }

                                        if(Wrap::pi == to)
                                        {
                                            radians -= math::piT<double>;
                                        }

                                        return radians;
                                    }

        static constexpr bool       isRadians(Units ut) {return ut == Units::Radians;}
        static constexpr bool       isDegrees(Units ut) {return ut == Units::Degrees;}

        static constexpr double     toRadians(double angle, Units ut) {return isRadians(ut) ? angle : ConvertDegreesToRadians(angle);}

    private:
        double						value;//Always a double, less or more is right out
    };
}//bosepro::math

#endif //ANGLE_H
