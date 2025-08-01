#pragma once
#ifndef XYZ_H
#define XYZ_H

#include <utility>

#include "FuzzyCompare.h"

namespace bosepro::math
{
    /**
     * \class       XYZ
     *
     * \brief       Template for simple xyz triplet
     *
     * \details     For when a Vector3T doesn't make sense and everything else is ambiguous and error prone
     */
    template <typename T>
    class XYZ
    {
    public:
        virtual ~XYZ() {}

        XYZ(T xv = T(0), T yv = T(0), T zv = T(0))  : x(xv), y(yv), z(zv)
        {}

        XYZ(const XYZ& other) : XYZ(other.x, other.y, other.z)
        {}

        XYZ(XYZ&& other) noexcept : x(std::move(other.x)), y(std::move(other.y)), z(std::move(other.z))
        {}

        XYZ&  operator=(const XYZ& other)
        {
            if (this != &other)
            {
                x = other.x;
                y = other.y;
                z = other.z;
            }

            return *this;
        }

        XYZ&  operator=(XYZ&& other) noexcept
        {
            if (this != &other)
            {
                x = std::move(other.x);
                y = std::move(other.y);
                z = std::move(other.z);
            }

            return *this;
        }

        constexpr friend bool   operator!=(const XYZ& lhs, const XYZ& rhs) {return !(lhs == rhs);}
        constexpr friend bool   operator==(const XYZ& lhs, const XYZ& rhs) {return isApproximatelyEqual(lhs.x, rhs.x) &&
                                                            isApproximatelyEqual(lhs.y, rhs.y) && 
                                                            isApproximatelyEqual(lhs.z, rhs.z);}

        union {T x; T roll;};
        union {T y; T pitch;};
        union {T z; T yaw;};             
    };
}

#endif //XYZ_H