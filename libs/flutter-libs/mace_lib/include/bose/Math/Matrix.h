#ifndef HEADER3D_MATRIX_H
#define HEADER3D_MATRIX_H

#include <cmath>
#include <type_traits>
#include "Angle.h"
#include "Vector.h"
#include "XYZ.h"
#include "FuzzyCompare.h"

namespace bosepro
{
    namespace math
    {
        //fwd declare quat 
        template<typename T> class QuaternionT;

        /**
         * \class       Matrix4x4T
         *
         * \brief       generic template for 4x4 matrix items
         *
         * \details     Row Major Representation (OpenGL is column major, Matlab is row major)
         *
         *               Right hand rule, right hand angles, rotation is Tait-Bryan intrinsic active z-y′-x″ 
         *               (yaw, pitch, roll) which in a nutshell means that we rotate mz * my * mx order so that
         *               the pitch angle is preserved regardless of yaw; else pitch would change sign based on
         *               yaw, as a function of the resultant quandrant of yaw.
         *
         *               This object is immutable sans cctor/mmtor and operator=
         *
         *               TRS is the mnemonic (Translate, Rotate, Scale) however this is read in right hand order
         *               SRT is the order to keep in mind when doing matrix operations.
         *
         *               T as an integral type is supported but makes little practical sense; avoid.
         */
        template <typename T>
        class Matrix4x4T final
        {
        public:
                                        //Cannot be virtual and have constexpr constructors, thus class is final
                                        ~Matrix4x4T() = default;

                                        //Default to identity matrix
            constexpr                   Matrix4x4T() noexcept
                                            : Matrix4x4T(1, 0, 0, 0,
                                                         0, 1, 0, 0,
                                                         0, 0, 1, 0,
                                                         0, 0, 0, 1)
                                        {
                                        }

            constexpr                   Matrix4x4T(T m00, T m01, T m02, T m03,
                                                   T m10, T m11, T m12, T m13,
                                                   T m20, T m21, T m22, T m23,
                                                   T m30, T m31, T m32, T m33) noexcept
                                                    : mat{m00, m01, m02, m03,
                                                          m10, m11, m12, m13,
                                                          m20, m21, m22, m23,
                                                          m30, m31, m32, m33}
                                        {
                                        }

            template <typename U>       //Converting ctor
            constexpr explicit          Matrix4x4T(const Matrix4x4T<U>& m) noexcept
                                            : Matrix4x4T(static_cast<T>(m(0, 0)), static_cast<T>(m(0, 1)), static_cast<T>(m(0, 2)), static_cast<T>(m(0, 3)),
                                                         static_cast<T>(m(1, 0)), static_cast<T>(m(1, 1)), static_cast<T>(m(1, 2)), static_cast<T>(m(1, 3)),
                                                         static_cast<T>(m(2, 0)), static_cast<T>(m(2, 1)), static_cast<T>(m(2, 2)), static_cast<T>(m(2, 3)),
                                                         static_cast<T>(m(3, 0)), static_cast<T>(m(3, 1)), static_cast<T>(m(3, 2)), static_cast<T>(m(3, 3)))
                                        {
                                        }

            constexpr                   Matrix4x4T(const Matrix4x4T& m) noexcept = default;
            constexpr                   Matrix4x4T(Matrix4x4T&& m)      noexcept = default;

            Matrix4x4T&                 operator=(const Matrix4x4T& m)  noexcept = default;
            Matrix4x4T&                 operator=(Matrix4x4T&& m)       noexcept = default;

                                        //Mathematical matrix notation indexing
            T&                          operator()(std::size_t row, std::size_t col)       noexcept {return operator[](row * 4 + col);}
            constexpr const T&          operator()(std::size_t row, std::size_t col) const noexcept {return operator[](row * 4 + col);}

                                        //Standard indexing 
            T&                          operator[](std::size_t i)       noexcept {return const_cast<T&>(static_cast<const Matrix4x4T<T>&>(*this)[i]);}//calls const version
            constexpr const T&          operator[](std::size_t i) const noexcept
                                        {
                                            if(i >= 16)
                                            {
                                                assert(0 && "Invalid index");
                                                i = 0; //Undefined behavior
                                            }
                                            return mat[i];
                                        }

                                        //Equality
            constexpr bool              operator==(const Matrix4x4T& m) const noexcept {for(auto i = 0; i < 16; ++i) if(!isApproximatelyEqual(mat[i], m.mat[i])) return false; return true;}
            constexpr bool              operator!=(const Matrix4x4T& m) const noexcept {return !(*this == m);}

                                        //Math
            constexpr Matrix4x4T        operator+() const noexcept {return *this;}//nop
            constexpr Matrix4x4T        operator-() const noexcept {Matrix4x4T m; for(auto i = 0; i < 16; ++i) {m.mat[i] = -mat[i];} return m;}

            constexpr friend Matrix4x4T operator+(const Matrix4x4T& lhs, const Matrix4x4T& rhs) noexcept {Matrix4x4T m; for(auto i = 0; i < 16; ++i) {m.mat[i] = lhs.mat[i] + rhs.mat[i];} return m;}
            constexpr friend Matrix4x4T operator-(const Matrix4x4T& lhs, const Matrix4x4T& rhs) noexcept {Matrix4x4T m; for(auto i = 0; i < 16; ++i) {m.mat[i] = lhs.mat[i] - rhs.mat[i];} return m;}
            
            constexpr friend Matrix4x4T operator*(const Matrix4x4T& lhs, const Matrix4x4T& rhs) noexcept
                                        {
                                            return Matrix4x4T(lhs(0, 0) * rhs(0, 0) + lhs(0, 1) * rhs(1, 0) + lhs(0, 2) * rhs(2, 0) + lhs(0, 3) * rhs(3, 0),
					                                          lhs(0, 0) * rhs(0, 1) + lhs(0, 1) * rhs(1, 1) + lhs(0, 2) * rhs(2, 1) + lhs(0, 3) * rhs(3, 1),
					                                          lhs(0, 0) * rhs(0, 2) + lhs(0, 1) * rhs(1, 2) + lhs(0, 2) * rhs(2, 2) + lhs(0, 3) * rhs(3, 2),
					                                          lhs(0, 0) * rhs(0, 3) + lhs(0, 1) * rhs(1, 3) + lhs(0, 2) * rhs(2, 3) + lhs(0, 3) * rhs(3, 3),
					                                          lhs(1, 0) * rhs(0, 0) + lhs(1, 1) * rhs(1, 0) + lhs(1, 2) * rhs(2, 0) + lhs(1, 3) * rhs(3, 0),
					                                          lhs(1, 0) * rhs(0, 1) + lhs(1, 1) * rhs(1, 1) + lhs(1, 2) * rhs(2, 1) + lhs(1, 3) * rhs(3, 1),
					                                          lhs(1, 0) * rhs(0, 2) + lhs(1, 1) * rhs(1, 2) + lhs(1, 2) * rhs(2, 2) + lhs(1, 3) * rhs(3, 2),
					                                          lhs(1, 0) * rhs(0, 3) + lhs(1, 1) * rhs(1, 3) + lhs(1, 2) * rhs(2, 3) + lhs(1, 3) * rhs(3, 3),
					                                          lhs(2, 0) * rhs(0, 0) + lhs(2, 1) * rhs(1, 0) + lhs(2, 2) * rhs(2, 0) + lhs(2, 3) * rhs(3, 0),
					                                          lhs(2, 0) * rhs(0, 1) + lhs(2, 1) * rhs(1, 1) + lhs(2, 2) * rhs(2, 1) + lhs(2, 3) * rhs(3, 1),
					                                          lhs(2, 0) * rhs(0, 2) + lhs(2, 1) * rhs(1, 2) + lhs(2, 2) * rhs(2, 2) + lhs(2, 3) * rhs(3, 2),
					                                          lhs(2, 0) * rhs(0, 3) + lhs(2, 1) * rhs(1, 3) + lhs(2, 2) * rhs(2, 3) + lhs(2, 3) * rhs(3, 3),
					                                          lhs(3, 0) * rhs(0, 0) + lhs(3, 1) * rhs(1, 0) + lhs(3, 2) * rhs(2, 0) + lhs(3, 3) * rhs(3, 0),
					                                          lhs(3, 0) * rhs(0, 1) + lhs(3, 1) * rhs(1, 1) + lhs(3, 2) * rhs(2, 1) + lhs(3, 3) * rhs(3, 1),
					                                          lhs(3, 0) * rhs(0, 2) + lhs(3, 1) * rhs(1, 2) + lhs(3, 2) * rhs(2, 2) + lhs(3, 3) * rhs(3, 2),
					                                          lhs(3, 0) * rhs(0, 3) + lhs(3, 1) * rhs(1, 3) + lhs(3, 2) * rhs(2, 3) + lhs(3, 3) * rhs(3, 3));
                                        }                     

           
                                        //Mult by scalar
            constexpr friend Matrix4x4T operator*(const T& rhs, const Matrix4x4T& lhs) noexcept {return lhs * rhs;}
            constexpr friend Matrix4x4T operator*(const Matrix4x4T& lhs, const T& rhs) noexcept
                                        {
                                            return Matrix4x4T(lhs(0, 0) * rhs, lhs(0, 1) * rhs, lhs(0, 2) * rhs, lhs(0, 3) * rhs, 
                                                              lhs(1, 0) * rhs, lhs(1, 1) * rhs, lhs(1, 2) * rhs, lhs(1, 3) * rhs, 
                                                              lhs(2, 0) * rhs, lhs(2, 1) * rhs, lhs(2, 2) * rhs, lhs(2, 3) * rhs,
                                                              lhs(3, 0) * rhs, lhs(3, 1) * rhs, lhs(3, 2) * rhs, lhs(3, 3) * rhs);
                                        }

                                        //Div by scalar
            constexpr friend Matrix4x4T operator/(const Matrix4x4T& lhs, const T& rhs) noexcept {return lhs * (std::isnormal(rhs) ? T(1) / rhs : T(0));}

                                        //Product of 4x4 matrix and 3x1 vector : vector projected homogeneously into 3D from 4D
            constexpr friend Vector3T<T> operator*(const Matrix4x4T& m, Vector3T<T> v) noexcept
                                        {
                                            auto d = (m(3, 0) * v.x + m(3, 1) * v.y + m(3, 2) * v.z + m(3, 3));//Bottom row
                                            auto w = SafeDivide(1.0, d);                                       //Length of bottom row

                                            return Vector3T<T>((m(0, 0) * v.x + m(0, 1) * v.y + m(0, 2) * v.z + m(0, 3)) * w,
                                                               (m(1, 0) * v.x + m(1, 1) * v.y + m(1, 2) * v.z + m(1, 3)) * w,
                                                               (m(2, 0) * v.x + m(2, 1) * v.y + m(2, 2) * v.z + m(2, 3)) * w);
                                        }

                                        //Zero matrix
            static constexpr Matrix4x4T zero()                                 noexcept {return Matrix4x4T(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);}
            constexpr bool              isZero()                         const noexcept {for(const auto& m : mat)if(m != T(0)) return false; return true;}

                                        //Identity matrix
            static constexpr Matrix4x4T identity()                             noexcept {return Matrix4x4T();}
            constexpr bool              isIdentity()                     const noexcept {return *this == Matrix4x4T();}

                                        //Translation matrix
            static constexpr Matrix4x4T translation(Vector3T<T> t)             noexcept {return translation(t.x, t.y, t.z);}
            static constexpr Matrix4x4T translation(T tx, T ty, T tz)          noexcept {return Matrix4x4T(1,  0,  0, tx,
                                                                                                           0,  1,  0, ty,
                                                                                                           0,  0,  1, tz,
                                                                                                           0,  0,  0,  1);}
                                        //Tanslation matrix prepend
            constexpr Matrix4x4T        translated(T tx, T ty, T tz)     const noexcept {return translation(tx, ty, tz) * *this;}                            
            constexpr Matrix4x4T        translated(Vector3T<T> t)        const noexcept {return translated(t.x, t.y, t.z);}
            constexpr Matrix4x4T        translatedX(T tx)                const noexcept {return translated( tx,   0,   0);}
            constexpr Matrix4x4T        translatedY(T ty)                const noexcept {return translated(  0,  ty,   0);}
            constexpr Matrix4x4T        translatedZ(T tz)                const noexcept {return translated(  0,   0,  tz);}

                                        //Extract translation
            constexpr Vector3T<T>       getTranslation()                 const noexcept {return getColumn(3) / (*this)(3,3);}

                                        //Scaling matrix
            static constexpr Matrix4x4T scaling(XYZ<T> s)                      noexcept {return scaling(s.x, s.y, s.z);}
            static constexpr Matrix4x4T scaling(T sx, T sy, T sz)              noexcept {return Matrix4x4T(sx,  0,  0,  0,
                                                                                                            0, sy,  0,  0,
                                                                                                            0,  0, sz,  0,
                                                                                                            0,  0,  0,  1);}
                                        //Scaling matrix prepend
            constexpr Matrix4x4T        scaled(T sx, T sy, T sz)         const noexcept {return scaling(sx, sy, sz) * *this;}
            constexpr Matrix4x4T        scaled(XYZ<T> s)                 const noexcept {return scaled(s.x, s.y, s.z);}
            constexpr Matrix4x4T        scaledX(T sx)                    const noexcept {return scaled( sx,   1,   1);}
            constexpr Matrix4x4T        scaledY(T sy)                    const noexcept {return scaled(  1,  sy,   1);}
            constexpr Matrix4x4T        scaledZ(T sz)                    const noexcept {return scaled(  1,   1,  sz);}

                                        //Extract scaling
            XYZ<T>                      getScaling()                     const noexcept {return XYZ{getColumn(0).length(), getColumn(1).length(), getColumn(2).length()};}


                                        //Rotation matrix (right handed coord system, right handed angles, Tait-Bryan intrinsic active z-y′-x″ : yaw, pitch and roll)
            static Matrix4x4T           rotation(XYZ<Angle> r)                      noexcept {return rotation(r.x, r.y, r.z);}
            static Matrix4x4T           rotation(Angle rx, Angle ry, Angle rz)      noexcept {const auto cx = rx.cos<T>(); const auto sx = rx.sin<T>();
                                                                                              const auto cy = ry.cos<T>(); const auto sy = ry.sin<T>();
                                                                                              const auto cz = rz.cos<T>(); const auto sz = rz.sin<T>();
                                                                                              
                                                                                              return Matrix4x4T(cy * cz,  sx * sy * cz - cx * sz,  cx * sy * cz + sx * sz,  0,
                                                                                                                cy * sz,  sx * sy * sz + cx * cz,  cx * sy * sz - sx * cz,  0,
                                                                                                                    -sy,  sx * cy               ,  cx * cy               ,  0, 
                                                                                                                      0,                       0,                       0,  1);}
                                        //Rotation matrix prepend (right hand rule : counterclockwise)
            Matrix4x4T                  rotated(Angle rx, Angle ry, Angle rz) const noexcept {return rotation(rx, ry, rz) * *this;}
            Matrix4x4T                  rotated(XYZ<Angle> r)                 const noexcept {return rotated(r.x, r.y, r.z);}
            Matrix4x4T                  rotatedX(Angle rx)                    const noexcept {return rotated( rx,   0,   0);}
            Matrix4x4T                  rotatedY(Angle ry)                    const noexcept {return rotated(  0,  ry,   0);}
            Matrix4x4T                  rotatedZ(Angle rz)                    const noexcept {return rotated(  0,   0,  rz);}

                                        //Extract rotation
            XYZ<Angle>                  getRotation()                         const noexcept;

                                        //Rotation matrix from Euler (identical to Matrix4x4T::rotation, exist for clarity & legacy porpoises)
            static constexpr Matrix4x4T fromRollPitchYaw(Angle roll, Angle pitch, Angle yaw) noexcept {return rotation(roll, pitch, yaw);}
                                        

                                        //The transpose of matrix A is denoted as Aᵀ
                   constexpr Matrix4x4T transpose()                     const noexcept {return transpose(*this);}
            static constexpr Matrix4x4T transpose(const Matrix4x4T& m)        noexcept
                                        {
                                            return Matrix4x4T(m(0, 0), m(1, 0), m(2, 0), m(3, 0), 
                                                              m(0, 1), m(1, 1), m(2, 1), m(3, 1), 
                                                              m(0, 2), m(1, 2), m(2, 2), m(3, 2), 
                                                              m(0, 3), m(1, 3), m(2, 3), m(3, 3));
                                        }

                                        //The inverse of matrix A is denoted by A⁻¹ : Computed using Cramer's rule
                   constexpr Matrix4x4T inverse()                    const noexcept {return inverse(*this);}
            static constexpr Matrix4x4T inverse(const Matrix4x4T& m)       noexcept {return SafeDivide(T(1), m.determinant()) * m.adjugate();}

                                        //The transpose of the cofactor matrix
                   constexpr Matrix4x4T adjugate()                      const noexcept {return adjugate(*this);}
            static constexpr Matrix4x4T adjugate(const Matrix4x4T& m)         noexcept
                                        {
	                                        const T n00 = m(0, 0);
	                                        const T n01 = m(0, 1);
	                                        const T n02 = m(0, 2);
	                                        const T n03 = m(0, 3);
	                                        const T n10 = m(1, 0);
	                                        const T n11 = m(1, 1);
	                                        const T n12 = m(1, 2);
	                                        const T n13 = m(1, 3);
	                                        const T n20 = m(2, 0);
	                                        const T n21 = m(2, 1);
	                                        const T n22 = m(2, 2);
	                                        const T n23 = m(2, 3);
	                                        const T n30 = m(3, 0);
	                                        const T n31 = m(3, 1);
	                                        const T n32 = m(3, 2);
	                                        const T n33 = m(3, 3);
	                                        
	                                        return Matrix4x4T(n11 * (n22 * n33 - n23 * n32) + n12 * (n23 * n31 - n21 * n33) + n13 * (n21 * n32 - n22 * n31),
					                                          n01 * (n23 * n32 - n22 * n33) + n02 * (n21 * n33 - n23 * n31) + n03 * (n22 * n31 - n21 * n32),
					                                          n01 * (n12 * n33 - n13 * n32) + n02 * (n13 * n31 - n11 * n33) + n03 * (n11 * n32 - n12 * n31),
					                                          n01 * (n13 * n22 - n12 * n23) + n02 * (n11 * n23 - n13 * n21) + n03 * (n12 * n21 - n11 * n22),
					                                          n10 * (n23 * n32 - n22 * n33) + n12 * (n20 * n33 - n23 * n30) + n13 * (n22 * n30 - n20 * n32),
					                                          n00 * (n22 * n33 - n23 * n32) + n02 * (n23 * n30 - n20 * n33) + n03 * (n20 * n32 - n22 * n30),
					                                          n00 * (n13 * n32 - n12 * n33) + n02 * (n10 * n33 - n13 * n30) + n03 * (n12 * n30 - n10 * n32),
					                                          n00 * (n12 * n23 - n13 * n22) + n02 * (n13 * n20 - n10 * n23) + n03 * (n10 * n22 - n12 * n20),
					                                          n10 * (n21 * n33 - n23 * n31) + n11 * (n23 * n30 - n20 * n33) + n13 * (n20 * n31 - n21 * n30),
					                                          n00 * (n23 * n31 - n21 * n33) + n01 * (n20 * n33 - n23 * n30) + n03 * (n21 * n30 - n20 * n31),
					                                          n00 * (n11 * n33 - n13 * n31) + n01 * (n13 * n30 - n10 * n33) + n03 * (n10 * n31 - n11 * n30),
					                                          n00 * (n13 * n21 - n11 * n23) + n01 * (n10 * n23 - n13 * n20) + n03 * (n11 * n20 - n10 * n21),
					                                          n10 * (n22 * n31 - n21 * n32) + n11 * (n20 * n32 - n22 * n30) + n12 * (n21 * n30 - n20 * n31),
					                                          n00 * (n21 * n32 - n22 * n31) + n01 * (n22 * n30 - n20 * n32) + n02 * (n20 * n31 - n21 * n30),
					                                          n00 * (n12 * n31 - n11 * n32) + n01 * (n10 * n32 - n12 * n30) + n02 * (n11 * n30 - n10 * n31),
					                                          n00 * (n11 * n22 - n12 * n21) + n01 * (n12 * n20 - n10 * n22) + n02 * (n10 * n21 - n11 * n20));
                                        }

                                        //The determinant of a matrix A is denoted det, det A, or |A|
                   constexpr T          determinant()                    const noexcept {return determinant(*this);}
            static constexpr T          determinant(const Matrix4x4T& m)       noexcept
                                        {
                                            return m(0, 3) * m(1, 2) * m(2, 1) * m(3, 0) - m(0, 2) * m(1, 3) * m(2, 1) * m(3, 0) -
                                                   m(0, 3) * m(1, 1) * m(2, 2) * m(3, 0) + m(0, 1) * m(1, 3) * m(2, 2) * m(3, 0) +
                                                   m(0, 2) * m(1, 1) * m(2, 3) * m(3, 0) - m(0, 1) * m(1, 2) * m(2, 3) * m(3, 0) -
                                                   m(0, 3) * m(1, 2) * m(2, 0) * m(3, 1) + m(0, 2) * m(1, 3) * m(2, 0) * m(3, 1) +
                                                   m(0, 3) * m(1, 0) * m(2, 2) * m(3, 1) - m(0, 0) * m(1, 3) * m(2, 2) * m(3, 1) -
                                                   m(0, 2) * m(1, 0) * m(2, 3) * m(3, 1) + m(0, 0) * m(1, 2) * m(2, 3) * m(3, 1) +
                                                   m(0, 3) * m(1, 1) * m(2, 0) * m(3, 2) - m(0, 1) * m(1, 3) * m(2, 0) * m(3, 2) -
                                                   m(0, 3) * m(1, 0) * m(2, 1) * m(3, 2) + m(0, 0) * m(1, 3) * m(2, 1) * m(3, 2) +
                                                   m(0, 1) * m(1, 0) * m(2, 3) * m(3, 2) - m(0, 0) * m(1, 1) * m(2, 3) * m(3, 2) -
                                                   m(0, 2) * m(1, 1) * m(2, 0) * m(3, 3) + m(0, 1) * m(1, 2) * m(2, 0) * m(3, 3) +
                                                   m(0, 2) * m(1, 0) * m(2, 1) * m(3, 3) - m(0, 0) * m(1, 2) * m(2, 1) * m(3, 3) -
                                                   m(0, 1) * m(1, 0) * m(2, 2) * m(3, 3) + m(0, 0) * m(1, 1) * m(2, 2) * m(3, 3);
                                        }

                                        //Create a basis matrix 
            static constexpr Matrix4x4T basis(Vector3T<T> xAxis, Vector3T<T> yAxis, Vector3T<T> zAxis) noexcept {return fromColumns(xAxis, yAxis, zAxis, {0, 0, 0});}
            
        protected:
                                        //Helper to get column
            constexpr Vector3T<T>       getColumn(std::size_t i) const {assert(i < 4); return i < 4 ? Vector3T<T>((*this)(0, i), (*this)(1, i), (*this)(2, i)) : Vector3T<T>();}

                                        //Helper to create matrix from columns
            static constexpr Matrix4x4T fromColumns(const Vector3T<T>& c0, const Vector3T<T>& c1, const Vector3T<T>& c2, const Vector3T<T>& c3) noexcept
                                        {
                                            return Matrix4x4T(c0.x, c1.x, c2.x, c3.x,
                                                              c0.y, c1.y, c2.y, c3.y,
                                                              c0.z, c1.z, c2.z, c3.z,
                                                                 0,    0,    0,    1);
                                        }

        private:
            T                           mat[4 * 4];

            // want signed numbers
            static_assert(std::is_signed<T>::value, "Error: Type must be signed");
        };
        

        //Definition can't be with declaration because QuaternionT definition depends on Matrix4x4T
        template <typename T> XYZ<Angle> Matrix4x4T<T>::getRotation() const noexcept 
        {
            //Back out scaling
            const auto s = getScaling();  
            const auto m = fromColumns(getColumn(0) / s.x, getColumn(1) / s.y, getColumn(2) / s.z, Vector3T<T>(0, 0, 0));

            //Use quat to extract rotation as Euler
            return QuaternionT<T>::getRotation(m).toRollPitchYaw();
        }

        using Mat4  = Matrix4x4T<double>;
    }
} // namespace

#endif // HEADER3D_MATRIX_H
