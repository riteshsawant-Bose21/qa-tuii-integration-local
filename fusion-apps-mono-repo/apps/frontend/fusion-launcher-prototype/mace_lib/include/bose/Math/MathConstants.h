#pragma once
#ifndef MATH_CONSTANTS_H
#define MATH_CONSTANTS_H

namespace bosepro
{
    namespace math
    {
        // place for math constants needed by math library

        //Real type alias
        using RealType = double;

        //Pi with variable precision up to double double
        template<typename T = RealType> constexpr T piT         = T(3.1415926535897932384626433832795);
        template<typename T = RealType> constexpr T eT          = T(2.7182818284590452353602874713526);

        //Common piT'ness
        template<typename T = RealType> constexpr T HalfPi      = piT<T> * T(0.5);
        template<typename T = RealType> constexpr T QuarterPi   = piT<T> * T(0.25);
        template<typename T = RealType> constexpr T DoublePi    = piT<T> * T(2.0);
        template<typename T = RealType> constexpr T OneOverPi   = T(1.0) / piT<T>;
        template<typename T = RealType> constexpr T TwoOverPi   = T(2.0) / piT<T>;

        //Degrees mnemonic for common piT'ness
        template<typename T = RealType> constexpr T rad45       = QuarterPi<T>;
        template<typename T = RealType> constexpr T rad90       = HalfPi<T>;
        template<typename T = RealType> constexpr T rad180      = piT<T>;
        template<typename T = RealType> constexpr T rad360      = DoublePi<T>;

        //Conversion constants
        template<typename T = RealType> constexpr T RadToDeg    = T(180.0) / piT<T>;
        template<typename T = RealType> constexpr T DegToRad    = piT<T> / T(180.0);

        //gravity of Earth constant
        template<typename T = RealType> constexpr T gravityT    = T(9.80665);

        //Helper so callers don't have to use piT<>; The brackets are required even if type is defaulted unfortunately
        constexpr auto pi                                       = piT<RealType>;
        constexpr auto e                                        = eT<RealType>;
        constexpr auto gravity                                  = gravityT<RealType>;
    }
} // namespace

#endif // MATH_CONSTANTS_H
