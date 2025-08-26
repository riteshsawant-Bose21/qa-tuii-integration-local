#pragma once
#ifndef LOUDSPEAKER_H
#define LOUDSPEAKER_H

#include <memory>
#include <unordered_map>
#include "HardwareComponent.h"
#include "BeamSteer.h"
#include "Math/Ray.h"
#include "Math/Vector.h"
#include "FilterInterface.h"

namespace bosepro::hardware
{
    class Loudspeaker;
    using LoudspeakerPtr        = std::shared_ptr<Loudspeaker>;
    using LoudspeakerWeakPtr    = std::weak_ptr<Loudspeaker>;

    using RayOptional = std::optional<math::Ray>;

    using AmpChanTransducerLocs = std::unordered_map<std::string, math::Vec3s>;

    /**
     * \class       Loudspeaker
     *
     * \brief       Interface that represents a single instance of loudspeaker
     *
     * \details     Concrete object is guaranteed to be thread safe
     */
    class Loudspeaker : public virtual HardwareComponent,
                        public acoustics::FilterInterface
    {
    public:
        virtual                         ~Loudspeaker()                                              = default;
										Loudspeaker()										        = default;
										Loudspeaker(const Loudspeaker&)				                = default;
										Loudspeaker(Loudspeaker&&)			               noexcept = default;
        Loudspeaker&					operator=(Loudspeaker&&)					       noexcept = default;
        Loudspeaker&					operator=(const Loudspeaker&)						        = default;

                                        //Relative to parent 
        virtual unsigned int            getIndex()                                          const   = 0;

                                        //Mute
        virtual void                    setMute(bool val)                                           = 0;
        virtual bool                    getMute()                                           const   = 0;
        virtual void                    toggleMute()                                                = 0;

        virtual bool                    setBasicFilter(double gain, double delay) = 0;
        virtual bool                    getBasicFilterValues(double& gain, double& delay) = 0;

        virtual bool                    addFilter(acoustics::FilterDataSet)                         = 0;
        acoustics::FiltersData          listFilters()                                               = 0;
        bool                            removeFilter(std::string type)                              = 0;
        void                            removeAllFilters()                                          = 0;


        virtual bool                    isBeamSteerable()                                   const   = 0;
        virtual unsigned int            getMaxBeamsAllowed()                                const   = 0;
        virtual const acoustics::BeamAlgorithms&   getAlgorithmTypes()                      const   = 0;
        virtual double                  getEffectiveEQPowerRatio()                          const   = 0;

										// the fixed, mechanical angles of the loudspeaker's 
                                        //coverage. e.g. "SM5/70" has a vertical angle of 5 
                                        //and horizontal angle of 70
		virtual void		            setVerticalCoverageAngle(math::Angle angle)		            = 0;
		virtual void		            setHorizontalCoverageAngle(math::Angle angle)	            = 0;
        virtual math::Angle             getVerticalCoverageAngle()                          const   = 0;
        virtual math::Angle             getHorizontalCoverageAngle()                        const   = 0;

                                        // Splay is the angle between top of box and horizontal
		virtual void                    resetSplay()                                                = 0;
        virtual bool                    canSplay(bool inUseConnectionsOnly = true)          const   = 0;
        virtual bool                    setSplayAngle(math::Angle angle)                            = 0;
        virtual bool                    setClosestSplayAngle(math::Angle angle)                     = 0;
        virtual math::Angle             getNextSplayValue(bool up = true)                           = 0;
        virtual bool                    setSplayAngle(const std::string& angle)                     = 0;
		virtual void                    setSplayAngleOptions(AngleMap angles)                       = 0;
		virtual AngleMap                getSplayAngleOptions()                              const	= 0;
        virtual math::Angle             getMinSplayAngleValue()                             const   = 0;
        virtual math::Angle             getMaxSplayAngleValue()                             const   = 0;
		virtual math::Angle             getSplayValue()                                     const	= 0;
        virtual math::Ray               getAxialRay()                                       const   = 0;
        virtual AmpChanTransducerLocs   getTransducerLocsPerAmpChan()                       const   = 0;

        								// get/set the user-friendly display splay angle 
		virtual std::string             getSplayAngle()							            const   = 0;
        virtual bool                    hasSplayAngle()                                     const   = 0;

        virtual bool                    isFullyLoaded()                                     const   = 0;
    };
}//bosepro::hardware

#endif //LOUDSPEAKER_H
