#pragma once
#ifndef FIELDPOINT_H
#define FIELDPOINT_H

#include "Math/Vector.h"
#include "Math/MathUtils.h"
#include <atomic>

namespace bosepro::simulation
{
	/**
	 * \class			FieldPoint
	 *
	 * \brief			A field point represents a point in 3d space
	 *					Primarily used for input.  Associated data will be in FieldPointData
	 *					and the collection of points is in FieldPoints.	 	 
	 *
	 * \details			We ultimately need to pass a vector of these to getArrivals
	 *					Vec3 class was Final not to be derived from. Going for efficiency, removed that.
	 */
	class FieldPoint : public math::Vec3
	{
	public:                        

											FieldPoint(bosepro::math::Vec3 pt) : math::Vec3(pt), m_id(getNextId()) {}
											FieldPoint(double x, double y, double z)                : FieldPoint(math::Vec3(x, y, z)){}

                                            ~FieldPoint()                                           = default;
                                            FieldPoint(const FieldPoint&)                           = default;
                                            FieldPoint(FieldPoint&&)                                = default;
                                                
        FieldPoint&                         operator=(FieldPoint&&)                                 = default;
        FieldPoint&                         operator=(const FieldPoint&)                            = default;

               								//Equality operators
//            friend bool							operator==(const FieldPoint& lhs, const FieldPoint& rhs) { return lhs.m_point == rhs.m_point; }
        friend bool							operator!=(const FieldPoint& lhs, const FieldPoint& rhs) { return !(lhs == rhs); }
                                                            

		// immutable sample point (but only immutable with respect to the implicit this ptr.)
        // caller can happily assign a copy and modify.                                                
		const math::Vec3&                   point() const { return *this; }
        uint64_t                            id() const { return m_id; }

	private:
        static uint64_t                     getNextId()
                                            {
                                                static std::atomic<uint64_t> id{ 0 };
                                                return id++;
                                            }
            
    	uint64_t                            m_id;    	                
	};        
} // bosepro::simulation
#endif // FIELDPOINT_H
