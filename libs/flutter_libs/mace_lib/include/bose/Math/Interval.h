#pragma once
#ifndef MATH_INTERVAL_H
#define MATH_INTERVAL_H

#include <cmath>
#include <type_traits>
#include "MathUtils.h"
#include "FuzzyCompare.h"

namespace bosepro
{
    namespace math
    {
        /**
         * \class       IntervalT
         *
         * \brief       template for a 1d interval [a,b]
         *
         * \details     This object is immutable sans cctor/mmtor and operator=
         */
        template <typename T>
        class IntervalT final
        {
        public:
                                        ~IntervalT()                            noexcept = default; //Can't be virtual, because of the constexpr ctor's
            constexpr                   IntervalT(T av = 0, T bv = 0)           noexcept : a_(av), b_(bv){}
            constexpr                   IntervalT(const IntervalT& other)       noexcept = default;
            constexpr                   IntervalT(IntervalT&& other)            noexcept = default;

            template <typename R>       //Converting ctor
            constexpr explicit          IntervalT(const IntervalT<R> & other)   noexcept : IntervalT(static_cast<T>(other.a_) , static_cast<T>(other.b_)){}

            IntervalT<T>&               operator=(const IntervalT<T>& other)    noexcept = default;
            IntervalT<T>&               operator=(IntervalT<T>&& other)         noexcept = default;

            constexpr bool              operator==(const IntervalT& rhs)  const noexcept {return isApproximatelyEqual(a_, rhs.a_) && isApproximatelyEqual(b_, rhs.b_);}
            constexpr bool              operator!=(const IntervalT& rhs)  const noexcept {return !(*this == rhs);}

            constexpr IntervalT         operator+()                       const noexcept {return *this;}             //nop
            constexpr IntervalT         operator-()                       const noexcept {return IntervalT(-b_, -a_);} // unary negation sends [a,b] to [-b,-a]

            constexpr friend IntervalT  operator*(IntervalT lhs, T rhs)         noexcept {return rhs * lhs;}
            constexpr friend IntervalT  operator*(T lhs, IntervalT rhs)         noexcept {return IntervalT(lhs * rhs.a_, lhs * rhs.b_);}
            constexpr friend IntervalT  operator/(IntervalT lhs, T rhs)         noexcept {return IntervalT(SafeDivide(lhs.a_, rhs), SafeDivide(lhs.b_, rhs));}

                                        //Standard Euclidean length squared
            constexpr T                 lengthSquared()                   const noexcept {auto d = a_ - b_; return d * d;}

                                        //Standard Euclidean length (or norm)
            T                           length()                          const noexcept {return std::abs(a_ - b_);}

                                        //Linear interpolation
            constexpr static T          lerp(IntervalT inv, double t)           noexcept {return lerp(inv.a_, inv.b_, t);}

                                        //Linear interpolation
            constexpr static T          lerp(T a, T b, double t)                noexcept {return static_cast<T>(a + (b - a) * t);}

                                        // linear interpolation: as t goes ax to bx, lerp(t) goes ay to by
                                        // t < ax gives ay, bx < t gives by
            constexpr static T          lerp(T ax, T ay, T bx, T by, T t)
                                        {
                                            T result = 0;
                                            // NOTE: this does NOT do extrapolation when you are outside the endpoints of a/b, if you need that, use GeometryTools GetLinearFunctionY instead.
                                            if(t < ax)
                                            {
                                                result = ay;
                                            }
                                            else if(bx < t)
                                            {
                                                result = by;
                                            }
                                            else if(isApproximatelyEqual(bx, ax))
                                            {
                                                result = (ay + by) * 0.5;
                                            }
                                            else 
                                            {
                                                result = (by - ay) * (t - ax) / (bx - ax) + ay;
                                            }

                                            return result;
                                        }

            constexpr T                 a() const noexcept {return a_;}
            constexpr T                 b() const noexcept {return b_;}

        private:
            T a_;
            T b_;

            static_assert(std::is_signed<T>::value, "Error: IntervalT type must be signed");
        };

        using IntInterval = IntervalT<int>;
        using DblInterval = IntervalT<double>;
    }
} // namespace

#endif // MATH_INTERVAL_H
