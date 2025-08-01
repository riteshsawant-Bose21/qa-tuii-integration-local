#pragma once
#ifndef BOSEPRO_ACOUSTICS_ISURFACEPLANE_H__
#define BOSEPRO_ACOUSTICS_ISURFACEPLANE_H__

#include "Math/Vector.h"

namespace bosepro::math
{
    /**
     * \class      	ISurfacePlane
     *					
     * \brief      	This interface amis to provide min/max points on a surface on a 
     *                  specific plane (XY, XZ, YZ)
     */
    class ISurfacePlane
    {
    public:
                        ISurfacePlane()                     = default;
        virtual         ~ISurfacePlane()                    = default;
                        ISurfacePlane(const ISurfacePlane&) = default;
                        ISurfacePlane(ISurfacePlane&&)      = default;
        ISurfacePlane&  operator=(const ISurfacePlane&)     = default;
        ISurfacePlane&  operator=(ISurfacePlane&&)          = default;

        virtual inline math::Vec3 getMaxPointOnXY() const = 0;
        virtual inline math::Vec3 getMinPointOnXY() const = 0;

        virtual inline math::Vec3 getMaxPointOnXZ() const = 0;
        virtual inline math::Vec3 getMinPointOnXZ() const = 0;

        virtual inline math::Vec3 getMaxPointOnYZ() const = 0;
        virtual inline math::Vec3 getMinPointOnYZ() const = 0;
    };
}

#endif //BOSEPRO_ACOUSTICS_ISURFACEPLANE_H__