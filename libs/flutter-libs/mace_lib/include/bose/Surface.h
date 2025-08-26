#pragma once
#ifndef SURFACE_H
#define SURFACE_H

#include <memory>
#include <string>
#include "Math/Ray.h"
#include "Collections/SaferVector.h"
#include "Placement.h"
#include "Node.h"
#include "ISurfacePlane.h"
#include "Enum.h"

namespace bosepro::model
{
    class Surface;
    using SurfacePtr			= std::shared_ptr<Surface>;      //TODO: This might be a good candidate for a unique_ptr instead of shared_ptr. 
                                                                //      Related to LoudspeakerClusterImplPtr that might also be a good candidate for unique_ptr.
    using SurfacesVector		= SaferVector<SurfacePtr>;

    enum class SurfaceTypes
    {
        None            = 0,        //0
        ListeningArea   = 1 << 0,   //1
        DontCare        = 1 << 1,   //2
        Obstruction     = 1 << 2    //4
    };
    DEFINE_ENUM_OPERATORS(SurfaceTypes);

	/**
     * \class		Surface
     *
     * \brief		Interface for a single surface
     * \details		We only require hit testing for phase 1
     */
	class Surface : public Placement, 
					public Node,
                    public math::ISurfacePlane
    {
    public:									 
                                Surface(math::Vec3  loc = {0.0, 0.0 ,0.0}, 
                                        Orientation ori = {0.0, 0.0, 0.0},
                                        SurfaceTypes surfaceType = SurfaceTypes::ListeningArea) 
                                    : Placement(loc, ori),
                                    _surfaceType(surfaceType)
                                {
                                }
        virtual					~Surface()                                  = default;
								Surface(const Surface&)                     = default;
        Surface&				operator=(const Surface&)                   = default;
								Surface( Surface&&)                         = default;
        Surface&				operator=(Surface&&)                        = default;

        //ISurfacePlane
        virtual inline math::Vec3 getMaxPointOnXY() const override { return getLocation(); }
        virtual inline math::Vec3 getMinPointOnXY() const override { return getLocation(); }
        virtual inline math::Vec3 getMaxPointOnXZ() const override { return getLocation(); }
        virtual inline math::Vec3 getMinPointOnXZ() const override { return getLocation(); }
        virtual inline math::Vec3 getMaxPointOnYZ() const override { return getLocation(); }
        virtual inline math::Vec3 getMinPointOnYZ() const override { return getLocation(); }

        virtual bool			hitTest(const math::Ray& ray, double segmentLength, std::shared_ptr<math::Vec3> where = nullptr) const = 0;  //KA: we have to supply a segment length when hit testing because we don't want to falsely return that we hit a surface when said surface is PAST the fieldPoint.  e.g. a measurement mic at a console should not say a ray from the cluster hit something and isn't needed because the ray hit the balcony.  
        SurfaceTypes inline     getSurfaceType() const { return _surfaceType; }
        void                    setName(std::string sz) { _surfaceName = sz;}
        std::string             getName() { return _surfaceName; }

    private:
        SurfaceTypes _surfaceType;
        std::string  _surfaceName; // can be used for debugging, engine doesn't really need 

    };
}//bosepro::model

#endif //SURFACE_H