#pragma once
#ifndef HEADER3D_VECTOR_H
#define HEADER3D_VECTOR_H

#include <cmath>
#include <type_traits>
#include <algorithm>
#include <optional>
#include <vector>
#include "Angle.h"
#include "FuzzyCompare.h"
#include "MathUtils.h"


namespace bosepro::math
{
	/**
	 * \class       Vector3T
	 *
	 * \brief       template for a 3d vector
	 *
	 * \details     This object is immutable sans cctor/mmtor and operator=
	 */
	template <typename T>
	class Vector3T //can't be final because of a needed optimization, wherein FieldPoint is a child
	{
	public:
                                    ~Vector3T()                                               noexcept = default; //Can't be virtual, because of the constexpr ctor's
		constexpr                   Vector3T(T x = 0, T y = 0, T z = 0)                       noexcept : x(x), y(y), z(z){}
        constexpr                   Vector3T(const Vector3T& other)                           noexcept = default;
		constexpr                   Vector3T(Vector3T&& other)                                noexcept = default;

		template <typename U>       //Converting ctor
		constexpr explicit          Vector3T(const Vector3T<U>& other)                        noexcept : Vector3T(static_cast<T>(other.x), static_cast<T>(other.y), static_cast<T>(other.z)) {}

        Vector3T<T>&                operator=(const Vector3T<T>& other)                       noexcept = default;
		Vector3T<T>&                operator=(Vector3T<T>&& other)                            noexcept = default;

        bool                        operator== (const Vector3T& v)                      const noexcept {return isApproximatelyEqual(x, v.x) && isApproximatelyEqual(y, v.y) && isApproximatelyEqual(z, v.z);}
		bool                        operator!=(const Vector3T& v)                       const noexcept {return !(*this == v);}

		constexpr Vector3T          operator+()                                         const noexcept {return *this;}//nop
		constexpr Vector3T          operator-()                                         const noexcept {return Vector3T(-x, -y, -z);}

        constexpr friend Vector3T   operator+(Vector3T lhs, Vector3T rhs)                     noexcept {return Vector3T(lhs.x + rhs.x, lhs.y + rhs.y, lhs.z + rhs.z);}
        constexpr friend Vector3T   operator-(Vector3T lhs, Vector3T rhs)                     noexcept {return Vector3T(lhs.x - rhs.x, lhs.y - rhs.y, lhs.z - rhs.z);}
        constexpr friend Vector3T   operator*(Vector3T lhs, Vector3T rhs)                     noexcept {return Vector3T(lhs.x * rhs.x, lhs.y * rhs.y, lhs.z * rhs.z);}
            
                                    //Mult by scalar
        constexpr friend Vector3T   operator*(Vector3T lhs, T rhs)                            noexcept {return rhs * lhs;}
		constexpr friend Vector3T   operator*(T lhs, Vector3T rhs)                            noexcept {return Vector3T(lhs * rhs.x, lhs * rhs.y, lhs * rhs.z);}

                                    //Div by scalar
        constexpr friend Vector3T   operator/(Vector3T lhs, T rhs)                            noexcept {return Vector3T(SafeDivide(lhs.x, rhs), SafeDivide(lhs.y, rhs), SafeDivide(lhs.z, rhs));}

                                    //True if all components are exactly zero
        constexpr bool              isZero()                                            const noexcept {return x == T(0) && y == T(0) && z == T(0);}

			                        //Standard Euclidean length squared 
		constexpr T                 lengthSquared()                                     const noexcept {return x * x + y * y + z * z;}

			                        //Standard Euclidean length (or norm)
        double                      length()                                            const {auto sq = lengthSquared(); return isApproximatelyZero(sq) ? 0.0 : std::sqrt(sq);} 

			                        //Normalized vector
		Vector3T                    normalized()                                        const noexcept {return Vector3T(*this / length()); }

        Angle                       directionToAzimuth() const noexcept
                                    {
                                        Angle azimuth(0.0);
                                        if (!math::isApproximatelyZero(length()))
                                        {
                                            auto adjY = math::isApproximatelyZero(y) ? 0.0 : y;
                                            auto adjX = math::isApproximatelyZero(x) ? 0.0 : x;
                                            // NOTE: atan2 relies on signs for quadrant detection so if you need -0 for that, then update accordingly.
                                            // see https://en.cppreference.com/w/cpp/numeric/math/atan2 for error handling behavior
                                            // This centrally deals with a tiny negative # causing problems when calculating splay angles especially in the slighly
                                            // different behavior between Mac/Win where Win had +0 value and Mac had -0.0000000000000001267893
                                            azimuth = Angle(std::atan2(adjY, adjX)); // phi
                                        }
                                        return azimuth;
                                    }

        Angle                       directionToInclinationOrElevation(bool xAxisIs0 = false) const
                                    {
                                        Angle angle(0.0);
                                        if (!math::isApproximatelyZero(length()))
                                        {
                                            auto adjZ = math::isApproximatelyZero(z) ? 0.0 : z; // if you need -0 then update accordingly.  similar error avoidance as directionToAzimuth
                                            auto zOverRadius = math::SafeDivide<long double>(static_cast<long double>(adjZ), length());
                                            if (xAxisIs0)
                                            {
                                                angle = Angle(static_cast<double>(std::asin(zOverRadius))); // theta, e.g. elevation
                                            }
                                            else
                                            {
                                                angle = Angle(static_cast<double>(std::acos(zOverRadius))); // theta
                                            }
                                        }
                                        return angle;
                                    }

        bool                        directionToSphericalCoordinates(T& r, std::optional<Angle>& azimuth, std::optional<Angle>& inclination, bool xAxisIs0 = false) const noexcept
                                    {
                                        // See § Cartesian coordinates in https://en.wikipedia.org/wiki/Spherical_coordinate_system#Cartesian_coordinates
                                        // vec3 is a direction vector
                                        auto ret = false;
                                        r = length();
                                        if (!math::isApproximatelyZero(r))
                                        {
                                            // Get the Spherical coordinates (r,azimuth,inclination) from the direction vector.                                                
                                            azimuth = directionToAzimuth();
                                            inclination = directionToInclinationOrElevation(xAxisIs0);
                                            ret = true;
                                        }
                                        return ret;
                                    }

        static Vector3T             sphericalToUnitDirection(Angle azimuth, Angle inclination, double radius = 1.0, bool xAxisIs0 = false) noexcept
                                    {
                                        Vector3T direction;
                                        // make a unit direction vector from the provided angles. (pitch and yaw in other words)
                                        if (xAxisIs0) // this is what we want for clusters where default 0 is on X axis.
                                        {
                                            direction = Vector3T(radius * std::cos(inclination.radians()) * std::cos(azimuth.radians()), radius * std::cos(inclination.radians()) * std::sin(azimuth.radians()), radius * std::sin(inclination.radians()));
                                        }
                                        else // z axis is 0
                                        {
                                            direction = Vector3T(radius * std::sin(inclination.radians()) * std::cos(azimuth.radians()), radius * std::sin(inclination.radians()) * std::sin(azimuth.radians()), radius * std::cos(inclination.radians()));
                                        }

                                        return direction.normalized();
                                    }


			                        //Dot product of two vectors
		constexpr static T          dot(Vector3T lhs, Vector3T rhs)                           noexcept {return lhs.x * rhs.x + lhs.y * rhs.y + lhs.z * rhs.z;}

			                        //Cross product of two vectors
		constexpr static Vector3T   cross(Vector3T lhs, Vector3T rhs)                         noexcept {return Vector3T(lhs.y * rhs.z - lhs.z * rhs.y, lhs.z * rhs.x - lhs.x * rhs.z, lhs.x * rhs.y - lhs.y * rhs.x);}

			                        //Distance between vectors treated as points
		constexpr static auto       distance(Vector3T left, Vector3T right)                   noexcept {return (left - right).length();}

			                        //Calculate the angle between two vectors
		constexpr static Angle      angleBetween(Vector3T from, Vector3T to)                           {return Angle(std::acos(SafeDivide(dot(from, to), from.length() * to.length())));}

			                        //Linear interpolation: as t goes 0 to 1, lerp goes a to b
		constexpr static Vector3T   lerp(Vector3T a, Vector3T b, T t)                         noexcept {return a + (b - a) * t;}

                                    //Min/max value
        T                           min()                                               const noexcept {return std::min(std::min(x, y), z);}
        T                           max()                                               const noexcept {return std::max(std::max(x, y), z);}

                                    //Min x, y, z values of this and rhs
        Vector3T                    min(Vector3T rhs)                                   const noexcept {return min(*this, rhs);} 
        Vector3T                    max(Vector3T rhs)                                   const noexcept {return max(*this, rhs);}

                                    //Min/max x, y, z values of lhs and rhs
        constexpr static Vector3T   min(Vector3T lhs, Vector3T rhs)                           noexcept {return Vector3T(std::min(lhs.x, rhs.x), std::min(lhs.y, rhs.y), std::min(lhs.z, rhs.z));}
        constexpr static Vector3T   max(Vector3T lhs, Vector3T rhs)                           noexcept {return Vector3T(std::max(lhs.x, rhs.x), std::max(lhs.y, rhs.y), std::max(lhs.z, rhs.z));}

        constexpr        bool       isXMax()                                            const noexcept { return std::abs(x) > std::abs(y) && std::abs(x) > std::abs(z); }
        constexpr        bool       isYMax()                                            const noexcept { return std::abs(y) > std::abs(x) && std::abs(y) > std::abs(z); }
        constexpr        bool       isZMax()                                            const noexcept { return std::abs(z) > std::abs(y) && std::abs(z) > std::abs(x); }

        constexpr        bool       isNear(Vector3T other, double tolerance=1e-12)      const noexcept { return std::abs(x - other.x) < tolerance && std::abs(y - other.y) < tolerance && std::abs(z - other.z) < tolerance; }


                                    //Rare exception to members must be private
        T                           x;
		T                           y;
		T                           z;

        //Want signed numbers
		static_assert(std::is_signed<T>::value, "Error: Vector3T type must be signed");
	};

    using Vec3 = Vector3T<double>;
    using Vec3s = std::vector<math::Vec3>;
} // namespace

#endif // HEADER3D_VECTOR_H
