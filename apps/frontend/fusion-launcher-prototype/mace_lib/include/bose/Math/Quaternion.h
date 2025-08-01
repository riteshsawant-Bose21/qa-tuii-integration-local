#ifndef HEADER3D_QUATERNION_H
#define HEADER3D_QUATERNION_H

#include <cmath>
#include <cassert>
#include <type_traits>
#include "Vector.h"
#include "Matrix.h"
#include "XYZ.h"
#include "FuzzyCompare.h"

namespace bosepro
{
    namespace math
    {
        /**
         * \class       QuaternionT
         *
         * \brief       template for a quaternion
         *
         * \details     This object is immutable sans cctor/mmtor and operator=
         *               T as an integral type is supported but makes little practical sense; avoid.
         */
        template<typename T>
        class QuaternionT final
        {
        public:
                                            ~QuaternionT()                                          noexcept = default;
            constexpr                       QuaternionT(T a_ = T(1), T b_ = 0, T c_ = 0, T d_ = 0)  noexcept   : a(a_), b(b_), c(c_), d(d_) {}
            constexpr                       QuaternionT(const QuaternionT& q)                       noexcept = default;
            constexpr                       QuaternionT(QuaternionT&& q)                            noexcept = default;
           
            template <typename U>           //Convert ctor
            constexpr explicit              QuaternionT(const QuaternionT<U>& q)                    noexcept : QuaternionT(static_cast<T>(q.a),
                                                                                                                           static_cast<T>(q.b),
                                                                                                                           static_cast<T>(q.c),
                                                                                                                           static_cast<T>(q.d)) {}

            QuaternionT&                    operator=(const QuaternionT& q)                         noexcept = default;
            QuaternionT&                    operator=(QuaternionT&& q)                              noexcept = default;

                                            //Convert to Vector : see also toAxisAngle()
            explicit                        operator Vector3T<T>() const noexcept
                                            {
                                                Vector3T<T> axis;
                                                T angle;
                                                toAxisAngle(axis, angle);
                                                return axis;
                                            }

                                            //Convert to Matrix : see also toMatrix()
            explicit                        operator Matrix4x4T<T>() const noexcept 
                                            {
                                                const auto u = normalized();
                                                return Matrix4x4T<T>(1 - 2 * u.y * u.y - 2 * u.z * u.z  , 2 * u.x * u.y - 2 * u.z * u.w     , 2 * u.x * u.z + 2 * u.y * u.w     , 0,
                                                                     2 * u.x * u.y + 2 * u.z * u.w      , 1 - 2 * u.x * u.x - 2 * u.z * u.z , 2 * u.y * u.z - 2 * u.x * u.w     , 0,
                                                                     2 * u.x * u.z - 2 * u.y * u.w      , 2 * u.y * u.z + 2 * u.x * u.w     , 1 - 2 * u.x * u.x - 2 * u.y * u.y , 0,
                                                                     0                                  , 0                                 , 0                                 , 1);
                                            }

                                            //Equality
            friend bool                     operator!=(const QuaternionT& q1, const QuaternionT& q2) noexcept {return !(q1 == q2);}
            friend bool                     operator==(const QuaternionT& q1, const QuaternionT& q2)
                                            {
                                                // NOTES: 
                                                // 1. Cannot simply compare angles, since they may differ yet represent the same orientation
                                                // 2. Cannot easily convert to Euler angles and check, since the numerics of the edge cases are terribly complex.
                                                //    First, if one angle is 180-eps and one is -180+eps, these should be the same, but differ by ~2pi
                                                //    Second, the angles near +- 90 on the limited range have large angle jumps required to normalize, making many cases
                                                //    Basically the parametrization is very nonuniform along boundaries, making numerics bad.
                                                // 3. Most robust is to check q1 ~ q2 or q1 ~ -q2
                                                const auto d1 = (q1 - q2).length();
                                                const auto d2 = (q1 + q2).length();
                                                constexpr const auto tolerance = 0.000001; // isFuzzyZero likely too tight here
                                                return d1 < tolerance || d2 < tolerance;
                                            }


            constexpr QuaternionT           operator+()                             const noexcept {return *this;}//nop
            constexpr QuaternionT           operator-()                             const noexcept {return QuaternionT(-a, -b, -c, -d);}

            constexpr friend QuaternionT    operator/(QuaternionT lhs, QuaternionT rhs)   noexcept {return lhs * rhs.inverse();}
            constexpr friend QuaternionT    operator+(QuaternionT lhs, QuaternionT rhs)   noexcept {return QuaternionT(lhs.a + rhs.a, lhs.b + rhs.b, lhs.c + rhs.c, lhs.d + rhs.d);}  
            constexpr friend QuaternionT    operator-(QuaternionT lhs, QuaternionT rhs)   noexcept {return QuaternionT(lhs.a - rhs.a, lhs.b - rhs.b, lhs.c - rhs.c, lhs.d - rhs.d);}
            constexpr friend QuaternionT    operator*(QuaternionT lhs, QuaternionT rhs)   noexcept {return QuaternionT(lhs.a * rhs.a - lhs.b * rhs.b - lhs.c * rhs.c - lhs.d * rhs.d,
                                                                                                                       lhs.a * rhs.b + lhs.b * rhs.a + lhs.c * rhs.d - lhs.d * rhs.c,
                                                                                                                       lhs.a * rhs.c + lhs.c * rhs.a + lhs.d * rhs.b - lhs.b * rhs.d,
                                                                                                                       lhs.a * rhs.d + lhs.d * rhs.a + lhs.b * rhs.c - lhs.c * rhs.b);}
            constexpr friend QuaternionT    operator*(T lhs, QuaternionT rhs)             noexcept {return rhs * lhs;}
            constexpr friend QuaternionT    operator*(QuaternionT lhs, T rhs)             noexcept {return QuaternionT(rhs * lhs.a, rhs * lhs.b, rhs * lhs.c, rhs * lhs.d);}
            constexpr friend QuaternionT    operator/(QuaternionT lhs, T rhs)             noexcept {return lhs * SafeDivide(T(1), rhs);}

                                            //Standard Euclidean 4D length squared
            constexpr T                     lengthSquared()                         const noexcept {return a * a + b * b + c * c + d * d;}

                                            //Standard Euclidean 4D length (or norm)
            double                          length()                                const noexcept {auto ls = lengthSquared(); return isApproximatelyZero(ls) ? 0.0 : std::sqrt(ls);}

                                            //Normalized quaternion
            QuaternionT                     normalized()                            const noexcept {return *this / length(); }

                                            //Inverse
            constexpr QuaternionT           inverse()                               const noexcept {return conjugate() / lengthSquared();}

                                            //Conjugate
            constexpr QuaternionT           conjugate()                             const noexcept {return QuaternionT(a, -b, -c, -d);}

                                            //Rotate vectpr
            constexpr Vector3T<T>           rotate(Vector3T<T> v)                   const noexcept 
                                            {
                                                const QuaternionT qv(0, v.x, v.y, v.z);
                                                const QuaternionT qm = (*this) * qv * inverse();
                                                return Vector3T<T>(qm.b, qm.c, qm.d);
                                            }

                                            //Exponent
            QuaternionT                     exp() const noexcept
                                            {
                                                const auto vnorm = SafeSqrt(b * b + c * c + d * d);
                                                const auto scale = SafeDivide(std::sin(vnorm), vnorm);
                                                return QuaternionT(std::cos(vnorm), scale * b, scale * c, scale * d) * std::exp(a);
                                            }

                                            //Natural log
            QuaternionT                     log() const noexcept
                                            {
                                                const auto qnorm = length();
                                                const auto vnorm = SafeSqrt(b * b + c * c + d * d);
                                                const auto scale = SafeDivide(std::acos(SafeDivide(a, qnorm)), vnorm);
                                                return QuaternionT(std::log(qnorm), scale * b, scale * c, scale * d);
                                            }

                                            // Spherical linear interpolation of unit quaternions : as parameter t goes 0 -> 1, value goes startQ to endQ
            static QuaternionT              slerp(const QuaternionT& startQuat, const QuaternionT& endQuat, T t) noexcept
                                            {
                                                QuaternionT result;

                                                QuaternionT startQ = startQuat.normalized();
                                                QuaternionT endQ   = endQuat.normalized();

                                                auto cosOmega = startQ.x * endQ.x + startQ.y * endQ.y + startQ.z * endQ.z + startQ.w * endQ.w;

                                                //if dot product is negative, take the shorter path
                                                if(cosOmega < 0)
                                                {
                                                    cosOmega = -cosOmega;
                                                    startQ   = -startQ;
                                                }

                                                constexpr static double dotThreshold = 0.9995;

                                                if(cosOmega > dotThreshold) 
                                                {
                                                    // If the inputs are too close for comfort, linearly interpolate and normalize the result
                                                    result = startQ + t * (endQ - startQ);
                                                    result = result.normalized();
                                                }
                                                else
                                                {
                                                    // Since dot is in range [0, DOT_THRESHOLD], acos is safe
                                                    const double theta_0     = std::acos(cosOmega); //angle between input vectors
                                                    const double theta       = theta_0 * t;         //angle between v0 and result
                                                    const double sin_theta   = std::sin(theta);
                                                    const double sin_theta_0 = std::sin(theta_0);
                                                    const double s0          = std::cos(theta) - SafeDivide(cosOmega * sin_theta, sin_theta_0); 
                                                    const double s1          = SafeDivide(sin_theta, sin_theta_0);

                                                    result = (s0 * startQ) + (s1 * endQ);
                                                }

                                                return result;
                                            }

                                            // fromAxisAngle:  make a quaternion given an axis and an angle : rotation is counter-clockwise when rotation vector is pointing to viewer
            static QuaternionT              fromAxisAngle(Vector3T<T> axis, Angle angle) noexcept
                                            {
                                                const auto ha = angle * Angle(0.5);

                                                axis = axis.normalized() * ha.sin<double>();
                                                
                                                return QuaternionT(ha.cos<double>(), axis.x, axis.y, axis.z);
                                            }

                                            //Cconvert quaternion to an axis and angle : rotation is counter-clockwise when rotation vector is pointing to viewer
            void                            toAxisAngle(Vector3T<T>& axis, Angle& angle) const noexcept
                                            {
                                                const double length = SafeSqrt(b * b + c * c + d * d);

                                                if(isApproximatelyEqual(length, 0.0))
                                                {
                                                    axis  = {0, 0, 1};
                                                    angle = {0};
                                                }
                                                else
                                                {
                                                    axis  = {x, y, z};
                                                    axis  = axis / length;
                                                    angle = {2 * std::acos(a)};
                                                }
                                            }

                                            //Create quaternion rotating vector v1 into v2 around a perpendicular axis
            constexpr static QuaternionT    rotateBetween(Vector3T<T> v1, Vector3T<T> v2) noexcept
                                            {
                                                QuaternionT result;

                                                v1 = v1.normalized();
                                                v2 = v2.normalized();

                                                //Cross product to get unit rotation axis perpendicular to v1,v2
                                                auto axis = Vector3T<T>::cross(v1, v2);

                                                //to get angle between vectors, note
                                                //| v1 X v2 | = |v1||v2|sin(theta)
                                                auto sinAngle = axis.length();

                                                //Clamp in case of numerical error
                                                if(sinAngle > 1.0)
                                                {
                                                    sinAngle = 1.0;
                                                }

                                                //Get rotation angle. Note sinAngle in [0,1] => theta in [0,pi/2]
                                                auto theta      = std::asin(sinAngle);
                                                auto otherTheta = static_cast<T>(pi) - theta;

                                                //if cos(theta) < 0, use other theta as rotation angle.
                                                if(Vector3T<T>::dot(v1, v2) < 0)
                                                {
                                                    theta = otherTheta;
                                                    otherTheta = static_cast<T>(pi) - theta;
                                                }

                                                if(!isApproximatelyEqual(theta, 0.0)) 
                                                {
                                                    if(isApproximatelyEqual(otherTheta, 0.0))
                                                    { 
                                                        // v1 = -v2, select one perpendicular vector
                                                        // v1 and v2 are ~ opposites. Rotate on any fixed perpendicular
                                                        if(!isApproximatelyEqual((v1.y * v1.y + v1.z * v1.z), 0.0))
                                                        { 
                                                            // first try x-axis if v1 not parallel
                                                            axis.x = 0;
                                                            axis.y = v1.z;
                                                            axis.z = -v1.y;
                                                        }
                                                        else
                                                        { 
                                                            // v1 parallel to x-axis. Use z-axis for rotation
                                                            axis.x = axis.y = 0;
                                                            axis.z = 1.0;
                                                        }
                                                    }

                                                    result = QuaternionT::fromAxisAngle(axis.normalized(), theta).normalized();
                                                }

                                                return result;
                                            }

                                            //Create a quaternion from a roll, pitch, yaw.
                                            //Often called Euler angles or Tait-Bryan angles, which is incorrect, as each of those has multiple non-equivalent formulations
                                            //Uses convention from https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
                                            //Thus yaw applied, then pitch in the new system, then roll in the final system
                                            //This corresponds to right handed coord system, right handed angles, Tait-Bryan intrinsic active z-y′-x″  yaw, pitch, roll
            static QuaternionT              fromRollPitchYaw(XYZ<Angle> a)                       noexcept {return fromRollPitchYaw(a.roll, a.pitch, a.yaw);}
            static QuaternionT              fromRollPitchYaw(Angle roll, Angle pitch, Angle yaw) noexcept 
                                            {
                                                const T cy = (yaw   * 0.5).cos<T>();
                                                const T sy = (yaw   * 0.5).sin<T>();
                                                const T cr = (roll  * 0.5).cos<T>();
                                                const T sr = (roll  * 0.5).sin<T>();
                                                const T cp = (pitch * 0.5).cos<T>();
                                                const T sp = (pitch * 0.5).sin<T>();

                                                return QuaternionT(cy * cr * cp + sy * sr * sp,
                                                                   cy * sr * cp - sy * cr * sp,
                                                                   cy * cr * sp + sy * sr * cp,
                                                                   sy * cr * cp - cy * sr * sp);
                                            }

                                            //Create a a roll, pitch, and yaw from a nonzero quaternion
                                            //Often called Euler angles or Tait-Bryan angles, which is incorrect, as each of those has multiple non-equivalent formulations
                                            //Uses convention from https://en.wikipedia.org/wiki/Conversion_between_quaternions_and_Euler_angles
                                            //Thus yaw applied, then pitch, then roll
                                            //roll in range [-pi,pi], pitch in [-pi/2,pi/2], yaw in [-pi,pi]
            XYZ<Angle>                      toRollPitchYaw()                                      const noexcept {XYZ<Angle> ea; toRollPitchYaw(ea.roll, ea.pitch, ea.yaw); return ea;}
            void                            toRollPitchYaw(Angle& roll, Angle& pitch, Angle& yaw) const noexcept            
                                            {
                                                //roll (x-axis rotation)
                                                const T sinr = static_cast<T>(2.0 * (a * b + c * d));
                                                const T cosr = static_cast<T>(1.0 - 2.0 * (b * b + c * c));

                                                const bool sinrZero = isApproximatelyZero(sinr);
                                                const bool cosrZero = isApproximatelyZero(cosr);

                                                if(sinrZero && cosrZero) assert(0 && "Invalid QuaternionT : domain error");

                                                roll = (sinrZero && cosrZero) ? 0 : static_cast<T>(std::atan2(sinr, cosr));

                                                //pitch (y-axis rotation)
                                                const T sinp = static_cast<T>(+2.0 * (a * c - d * b));

                                                pitch = (std::fabs(sinp) < 1) ? std::asin(sinp) : std::copysign(math::pi / 2, sinp);// use 90 degrees if out of range

                                                //yaw (z-axis rotation)
                                                const T siny = static_cast<T>(+2.0 * (a * d + b * c));
                                                const T cosy = static_cast<T>(+1.0 - 2.0 * (c * c + d * d));

                                                const bool sinyZero = isApproximatelyZero(siny);
                                                const bool cosyZero = isApproximatelyZero(cosy);

                                                if(sinyZero && cosyZero) assert(0 && "Invalid QuaternionT : domain error");

                                                yaw = (sinyZero && cosyZero) ? 0 : atan2(siny, cosy);
                                            }

                                            //Convert quaternion to rotation matrix
            constexpr                       Matrix4x4T<T> toMatrix() const
                                            {
                                                return static_cast<Matrix4x4T<T>>(*this);
                                            }

                                            //Extract the rotation component of the matrix transform : assumes orthogonal and no scaling
            static QuaternionT              getRotation(const Matrix4x4T<T>& m)
                                            {
                                                const auto m00 = m(0, 0), m01 = m(0, 1), m02 = m(0, 2);
                                                const auto m10 = m(1, 0), m11 = m(1, 1), m12 = m(1, 2);
                                                const auto m20 = m(2, 0), m21 = m(2, 1), m22 = m(2, 2);

                                                T t;
                                                QuaternionT q;

                                                if(m22 < 0) // iff x^2+y^2 > 1/2
                                                {
                                                    if(m00 > m11) // x^2 > y^2
                                                    {
                                                        t = 1 + m00 - m11 - m22; // 4x^2
                                                        q = QuaternionT(m21 - m12, t, m01 + m10, m20 + m02);
                                                    }
                                                    else // work with y as divisor
                                                    {
                                                        t = 1 - m00 + m11 - m22; // 4y^2
                                                        q = QuaternionT(m02 - m20, m01 + m10, t, m12 + m21);
                                                    }
                                                }
                                                else // z^2+w^2 > 1/2
                                                {
                                                    if(m00 < -m11)
                                                    {
                                                        t = 1 - m00 - m11 + m22;  // 4z^2
                                                        q = QuaternionT(m10 - m01, m20 + m02, m12 + m21, t);
                                                    }
                                                    else
                                                    {
                                                        t = 1 + m00 + m11 + m22; // 4-4(x^2+y^2+z^2)=4w^2
                                                        q = QuaternionT(t, m21 - m12, m02 - m20, m10 - m01);
                                                    }
                                                }

                                                return (q * 0.5 / SafeSqrt(t)).normalized();
                                            }

            // a,b,c,d are the coefficients of the standard quaternion basis 1,i,j,k respectively
            // w,x,y,z are used often in axis angle thinking
            union {T a; T w;};
            union {T b; T x;};
            union {T c; T y;};
            union {T d; T z;};

            static_assert(std::is_signed<T>::value, "Error: QuaternionT type must be signed");
        };

        using Quat = QuaternionT<double>;

    }//math
}//bosepro

#endif // HEADER3D_QUATERNION_H
