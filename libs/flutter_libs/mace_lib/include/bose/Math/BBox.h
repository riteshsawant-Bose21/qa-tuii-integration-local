#pragma once
#ifndef BBOX_H
#define BBOX_H

#include <cassert>
#include "Vector.h"
#include "MathUtils.h"
#include "Matrix.h"


namespace bosepro
{
    namespace math
    {
        /**
         * \class       BBoxT
         *
         * \brief       Template for a 3D bounding box
         *
         * \details     This object is immutable sans cctor/mmtor and operator=
         */
        template <typename T>
        class BBoxT
        {
        public:
            constexpr               BBoxT(T minx = T(0), T miny = T(0), T minz = T(0), T maxx = T(0), T maxy = T(0), T maxz = T(0))
                                        : BBoxT(Vector3T<T>(minx, miny, minz), Vector3T<T>(maxx, maxy, maxz))
                                    {
                                    }

            constexpr               BBoxT(const Vector3T<T>& m_Min, const Vector3T<T>& m_Max)
                                        : m_Min(m_Min), m_Max(m_Max)
                                    {
                                        normalize();
                                        assert(!isNotNormal());
                                    }

                                    BBoxT(const BBoxT&)         = default;
            BBoxT&                  operator=(const BBoxT&)     = default;
                                    BBoxT(BBoxT&&)              = default;
            BBoxT&                  operator=(BBoxT&&)          = default;
            virtual                 ~BBoxT()                    = default;

            friend bool             operator==(const BBoxT& lhs, const BBoxT& rhs)          {return (lhs.getMin() == rhs.getMin()) && (lhs.getMax() == rhs.getMax());}
            friend bool             operator!=(const BBoxT& lhs, const BBoxT& rhs)          {return !(lhs == rhs);}

            friend BBoxT            operator+(const BBoxT& lhs, const Vector3T<T>& rhs)     {return BBoxT(lhs.getMin() + rhs, lhs.getMax() + rhs);}
            friend BBoxT            operator-(const BBoxT& lhs, const Vector3T<T>& rhs)     {return lhs + -rhs; }
            friend BBoxT            operator*(const BBoxT& lhs, const Matrix4x4T<T>& rhs)   {return lhs.transformed(rhs);}
            
            inline Vector3T<T>      getMin() const {return m_Min;}
            inline Vector3T<T>      getMax() const {return m_Max;}

                                    //Test empty with all values being zero
            inline bool             isZero()  const { return isZero(m_Min) && isZero(m_Max); }

                                    //Test empty with all values being non zero
            inline bool             isEmpty() const { return isApproximatelyEqual(m_Min.x, m_Max.x) && isApproximatelyEqual(m_Min.y, m_Max.y) && isApproximatelyEqual(m_Min.z, m_Max.z); }

                                    //Test empty with all zero or non zero
            inline bool             isEmptyOrZero() const { return isEmpty() || isZero(); }

                                    //Center of bbox
            inline Vector3T<T>      getCenter() const { return Vector3T<T>((m_Min.x + m_Max.x) * 0.5, (m_Min.y + m_Max.y) * 0.5, (m_Min.z + m_Max.z) * 0.5); }

                                    //Dimensions
            inline T                getDimensionX() const {return m_Max.x - m_Min.x;}
            inline T                getDimensionY() const {return m_Max.y - m_Min.y;}
            inline T                getDimensionZ() const {return m_Max.z - m_Min.z;}

                                    //Offset
            inline BBoxT            offset(const Vector3T<T>& val) const { return *this + val; }

                                    //Transformed
            inline BBoxT            transformed(const Matrix4x4T<T>& mat) const 
                                    {
                                        //Transform 8 cube vertices individually
                                        std::vector<Vector3T<T>> v(8);

                                        v[0] = mat * Vector3T<T>(m_Min.x, m_Min.y, m_Min.z);
                                        v[1] = mat * Vector3T<T>(m_Min.x, m_Min.y, m_Max.z);
                                        v[2] = mat * Vector3T<T>(m_Min.x, m_Max.y, m_Min.z);
                                        v[3] = mat * Vector3T<T>(m_Min.x, m_Max.y, m_Max.z);
                                        v[4] = mat * Vector3T<T>(m_Max.x, m_Min.y, m_Min.z);
                                        v[5] = mat * Vector3T<T>(m_Max.x, m_Min.y, m_Max.z);
                                        v[6] = mat * Vector3T<T>(m_Max.x, m_Max.y, m_Min.z);
                                        v[7] = mat * Vector3T<T>(m_Max.x, m_Max.y, m_Max.z);
                                        
                                        return fromPoints(v);
                                    }

                                    //Intersect bbox check
            inline bool             intersects(const BBoxT& b) const
                                    {
                                        assert(!isNotNormal());
                                        assert(!b.isNotNormal());

                                        return !(b.m_Min.x > m_Max.x || b.m_Max.x < m_Min.x ||
                                                 b.m_Min.y > m_Max.y || b.m_Max.y < m_Min.y ||
                                                 b.m_Min.z > m_Max.z || b.m_Max.z < m_Min.z);
                                    }

                                    //Intersect point check
            inline bool             intersects(const Vector3T<T>& v) const
                                    {
                                        assert(!isNotNormal());

                                        return !(m_Min.x > v.x || v.x > m_Max.x ||
                                                 m_Min.y > v.y || v.y > m_Max.y ||
                                                 m_Min.z > v.z || v.z > m_Max.z);
                                    }

                                    //Union with another bbox
            inline BBoxT            unionWith(const BBoxT& b) const
                                    {
                                        assert(!isNotNormal());
                                        assert(!b.isNotNormal());

                                        BBoxT box;

                                        if(isZero())
                                        {
                                            box = b;
                                        }
                                        else
                                        {
                                            box = BBoxT(m_Min.min(b.m_Min), m_Max.max(b.m_Max));
                                        }

                                        return box;
                                    }

                                    //Union with a point
            inline BBoxT            unionWith(const Vector3T<T>& v) const
                                    {
                                        assert(!isNotNormal());

                                        BBoxT box;

                                        if(isZero())
                                        {
                                            box = BBoxT(v, v);
                                        }
                                        else
                                        {
                                            box = BBoxT(m_Min.min(v), m_Max.max(v));
                                        }
                                        
                                        return box;
                                    }

                                    //Creation from collection of points
            static BBoxT<T>         fromPoints(const std::vector<Vector3T<T>>& pts)
                                    {
                                        BBoxT box;

                                        for(auto const& pt : pts)
                                        {
                                            box = box.unionWith(pt);
                                        }

                                        return box;
                                    }

        protected:
                                    //Ensure m_Min < m_Max
            inline void             normalize() { SwapIf(m_Max.x, m_Min.x); SwapIf(m_Max.y, m_Min.y); SwapIf(m_Max.z, m_Min.z); }

                                    //Test for m_Min > m_Max
            inline bool             isNotNormal() const { return m_Min.x > m_Max.x || m_Min.y > m_Max.y || m_Min.z > m_Max.z; }

            static bool             isZero(const Vector3T<T>& v) { return !(!isApproximatelyZero(v.x) || !isApproximatelyZero(v.y) || !isApproximatelyZero(v.z)); }

        private:
            Vector3T<T>             m_Min;
            Vector3T<T>             m_Max;

            static_assert(std::is_signed<T>::value, "Error: BBoxT type must be signed");
        };

        //Type alias
        using BBox = BBoxT<double>;

    }//math
}//bosepro

#endif //BBOX_H
