#pragma once
#ifndef LOUDSPEAKERCLUSTER_H
#define LOUDSPEAKERCLUSTER_H

#include <memory>
#include <optional>
#include <string>
#include <string_view>

#include "Node.h"
#include "HardwareComponent.h"
#include "CompressionStrap.h"
#include "BeamSteer.h"
#include "IPhysicalObject.h"
#include "FilterInterface.h"
#include "ClusterConfig.h"

namespace bosepro::mechanical
{
    class ClusterConfig;
}

namespace bosepro::model
{
    class LoudspeakerCluster;
    using LoudspeakerClusterPtr                 = std::shared_ptr<LoudspeakerCluster>;//TODO //ADB change to std::unique_ptr

	/**
	 * \class		LoudspeakerCluster
	 *
	 * \brief		Represents a collection of one or more loudspeakers that are physically connected together,
	 *				to include any rigging and accessories. This includes stacked subs, ground stacked line arrays,
	 *				flown arrays, installed column arrays and speakers on a stick.
	 * \details		This object will control the Placement of all child components.
	 *				For ease of use, even a single loudspeaker should be housed within a cluster.
	 */
	class LoudspeakerCluster : public Placement,
                                public Node, // was protected but... one then can't use this easily in a Node container.  Well you kinda can but you'd have to std::reinterpret_pointer_cast both in and out of the Node container.
								public hardware::IPhysicalObject,
                                public acoustics::FilterInterface
    {
    public:
                                                //Factory method
        static LoudspeakerClusterPtr            create();

        virtual                                 ~LoudspeakerCluster()                                       noexcept    = default;
                                                LoudspeakerCluster()                                                    = default;
                                                LoudspeakerCluster(const LoudspeakerCluster&)                           = default;
                                                LoudspeakerCluster(LoudspeakerCluster&&)                    noexcept    = default;
        LoudspeakerCluster&                     operator=(LoudspeakerCluster&&)                             noexcept    = default;
        LoudspeakerCluster&                     operator=(const LoudspeakerCluster&)                                    = default;
                                                //the bypass is to avoid a condition of test for A creating clone B and changing B such that B winds up doing same test and creating clone C which does D and so on.
		LoudspeakerCluster*                     clone(bool permanentlyBypassSafetyForSafetyChecks = false)  const   override    = 0;

                                                //UID
        uint64_t                                getId()                                             const   noexcept    {return Node::getId();}

                                                //Component count
        virtual std::size_t                     getNumComponents()                                  const   noexcept    = 0;

                                                //Component compatibility testing
        virtual bool                            canAddComponent(hardware::HardwareComponentPtr src)           const               = 0;

                                                //Component add
        virtual bool                            addComponent(hardware::HardwareComponentPtr src)                                  = 0;

                                                //Component compatibility testing
        virtual bool                            canRemoveComponent(uint64_t id)                     const                = 0;
        virtual bool                            canRemoveComponent(hardware::HardwareComponentPtr ptr)        const                = 0;
        virtual bool                            canRemoveComponentByIndex(std::size_t index)        const                = 0;

                                                //Component removal
        virtual bool                            removeComponent(uint64_t id)                                            = 0;
        virtual bool                            removeComponent(hardware::HardwareComponentPtr ptr)                               = 0;
        virtual bool                            removeComponentByIndex(std::size_t index)                               = 0;
		virtual void                            removeAllComponents()													= 0;

                                                //Component existence
        inline bool                             hasComponent(uint64_t id)                           const               {return hasChild(id);}

        template <class T = hardware::HardwareComponent>  //Component retrieval by id
        std::shared_ptr<T>                      getComponent(uint64_t id)                           const               {return getChild<T>(id);}

        template <class T = hardware::HardwareComponent>  //Component retrieval by index
        std::shared_ptr<T>                      getComponentByIndex(std::size_t index)              const               {return getChildByIndex<T>(index);}

        template <class T = hardware::HardwareComponent>
        std::size_t                             getChildIndex(const std::shared_ptr<T>& component)       const
        {
            for (std::size_t i = 0 ; i < getNumChildren() ; ++i)
                if (getChildByIndex(i) == component)
                    return i;

            return 0;
        }

        template <class T = hardware::HardwareComponent>  //Components retrieval
		NodePtrsT<T>							getComponents()                                     const               {return getChildren<T>();}
            
        template <class T = hardware::HardwareComponent>  //Component retrieval by subtype
		NodePtrsT<T>							getComponentsBySubtype(hardware::ComponentType type)           const;

                                                //Component ids
        std::vector<uint64_t>                   getComponentIds()                                   const               {return getChildrenIds();}

        virtual std::size_t                     numHWCsBeforeLoudspeaker()                                              = 0;
                                                //Mute
        virtual void                            setMute(bool val)                                                       = 0;
        virtual bool                            getMute()                                           const               = 0;
        inline void                             toggleMute()                                                            {ScopedLock sl(getLock()); setMute(!getMute());}

        virtual bool                            addFilter(acoustics::FilterDataSet) override                            = 0;
        acoustics::FiltersData                  listFilters()                       override                            = 0;
        bool                                    removeFilter(std::string type)      override                            = 0;
        void                                    removeAllFilters()                  override                            = 0;

                                                //Gain in dB
        virtual double                          setGain(double dB)                                                      = 0;
        virtual double                          getGain()                                           const               = 0; //dB
        virtual double                          getHeadroom()                                       const               = 0; //dB
        inline double                           setMaxGain()                                                            {ScopedLock sl(getLock()); return setGain(getGain() + getHeadroom());}

                                                //Delay in ms (positive only)
        virtual double                          setDelay(double ms)                                                     = 0;
        virtual double                          getDelay()                                          const               = 0; //ms

                                                //Beam steering
        virtual bool                            isBeamSteerable()                                   const               = 0;

        virtual bool                            addBeam(acoustics::BeamSteerPtr beam)                                              = 0;
        virtual bool                            replaceBeam(acoustics::BeamSteerPtr beam, std::size_t index)                       = 0;

        virtual void                            removeBeam(acoustics::BeamSteerPtr beam)                                           = 0;
        virtual void                            removeBeam(std::size_t index)                                           = 0;
        virtual void                            removeAllBeams()                                                        = 0;

        virtual acoustics::BeamSteerPtr         getBeam(std::size_t index)                          const               = 0;
        virtual std::size_t                     getNumBeams()                                       const               = 0;
        virtual std::size_t                     getMaxBeamsAllowed()                                const               = 0;

        virtual std::size_t                     getNumArrivals()                                    const               = 0;

        virtual acoustics::BeamAlgorithms       getAlgorithmTypes()                                 const               = 0;

                                                //Combined bill of materials of all components
        virtual model::BOM						getBom()                                            const   noexcept    = 0;

                                                //Physical attributes
        virtual double                          getRunningMass(std::size_t index)                   const               = 0;
        virtual double                          getReverseRunningMass(std::size_t index)            const               = 0;

                                                //Rigging
        virtual hardware::HardwareComponentPtr	getPullbackBar()                                    const               = 0;
        virtual bool                            hasPullbackBar()                                    const               = 0;
        virtual hardware::HardwareComponentPtr	getGrid()                                           const               = 0;
        virtual bool                            hasGrid()                                           const               = 0;
        virtual hardware::HardwareComponentPtr	getBracket()                                        const               = 0;
        virtual bool                            hasBracket()                                        const               = 0;
        virtual hardware::CompressionStrapPtr	getCompressionStrap()                               const               = 0;
		virtual bool                            hasCompressionStrap()                               const               = 0;
        virtual hardware::HardwareComponentPtr	getSlider()                                         const               = 0;
        virtual bool                            hasSlider()                                         const               = 0;

        virtual math::Vec3                      getClusterCenterOfGravity()                         const               = 0;

                                                //Mechanical safety check
        virtual bool                            isItSafe()                                          const               = 0;

        virtual math::Angle                     getTotalAngle()                                     const               = 0;
        virtual math::Angle						getMaxTotalAngle()									const               = 0;
        virtual math::Angle						getMinTotalAngle()									const               = 0;
        virtual math::Angle						getBottomAngle()									const               = 0;
        virtual math::Angle						getTopAngle()										const               = 0;

        virtual bosepro::mechanical::ClusterConfig*   getConfigPtr()                                                    = 0;
        virtual bool                            setConfigurationName(std::string_view szName)                           = 0;
        virtual std::string_view                getConfigurationName()                              const               = 0;
        virtual bool                            updateConfig(uint64_t ca, std::optional<math::Angle> pitch = std::nullopt, std::vector<std::string> pickpoints = {}) = 0;

        virtual void                            updateOriginToPickPoint()                                               = 0;
    };
}//bosepro

#endif //LOUDSPEAKERCLUSTER_H
