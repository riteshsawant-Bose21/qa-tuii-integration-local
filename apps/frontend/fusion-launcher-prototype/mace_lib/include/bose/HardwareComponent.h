#pragma once
#ifndef HARDWARECOMPONENT_H
#define HARDWARECOMPONENT_H

#include <memory>
#include <string>

#include "Node.h"
#include "Placement.h"
#include "IPhysicalObject.h"
#include "Mechanical/ForcePoint.h"
#include "DXFFace.h"
#include "Connections.h"
#include "BOM.h"
#include "HardwareComponentTypes.h"

namespace bosepro
{
    // potential names for Point locations
    constexpr std::string_view UpperFrontPoint = "UpperFront";     // type of connection/corner point
    constexpr std::string_view UpperRearPoint  = "UpperRear";      // type of connection/corner point
    constexpr std::string_view LowerFrontPoint = "LowerFront";     // type of connection/corner point
    constexpr std::string_view LowerRearPoint  = "LowerRear";      // type of connection/corner point
    constexpr std::string_view FrontPoint      = "Front";          // type of foot point
    constexpr std::string_view RearPoint       = "Rear";           // type of foot point

    namespace hardware
    {
        //Nominal to Actual angle map
        using AngleMap = std::unordered_map<std::string, math::Angle>;

        class HardwareComponent;
        using HardwareComponentPtr = std::shared_ptr<HardwareComponent>;

        using mechanical::ForcePoints;
        using mechanical::ForcePointOptional;
        using mechanical::ForcePointMap;

        /**
         * \brief Intrinsic data for hardware objects like loudspeakers, flybars and rigging accessories
         */
        class HardwareComponent : public virtual Node,
            public virtual Placement,
            public virtual IPhysicalObject
        {
        public:

            virtual                             ~HardwareComponent()                            noexcept = default;
                                                HardwareComponent()                                      = default;
                                                HardwareComponent(const HardwareComponent&)              = default;
                                                HardwareComponent(HardwareComponent&&)          noexcept = default;
            HardwareComponent&                  operator=(HardwareComponent&&)                  noexcept = default;
            HardwareComponent&                  operator=(const HardwareComponent&) = default;

            HardwareComponent*                  clone(bool flag = false)                  const override = 0;

            //Static text
            virtual const std::string&          getName()                                 const = 0;
            virtual const std::string&          getFamily()                               const = 0;
            virtual const std::string&          getDescription()                          const = 0;
            virtual double                      getVersion()                              const = 0;

            //Type of component                 //todo parent shouldn't know about children
            virtual ComponentType               getComponentType()                        const = 0;

            virtual double                      getConnectionPointDepth()                 const = 0; //meters | depth of component, between connection points

            virtual math::Vec3                  getCenterOfGravity()                      const = 0;

            //3D DXF faces
            virtual const DXFFaces& getDXFFaces()                                         const = 0;

            //Physical connections possible
            virtual mechanical::Connections     getConnections()                          const = 0;
            virtual mechanical::Connections     getConnectionsInUse()                     const = 0;

            //Bill of materials
            virtual const model::BOM& getBOM()                                            const = 0;

            ///Force calculation type
            enum class                          ForceCalcType
            {
                RCN,        // Rear Connection from Normal (old style rdk)
                RDK,        // Rear Direction Known
                BoltCircle  // Bolt Circle joints
            };

            virtual ForceCalcType               getForceCalcType()                        const = 0;

            //Connection points     
            virtual ForcePoints                 getConnectionPoints()                     const = 0;
            virtual ForcePointOptional          getConnectionPoint(std::string_view name) const = 0;
            virtual void                        addConnectionPoint(std::string_view name, mechanical::ForcePoint) = 0;

            //4 corner points
            virtual ForcePointOptional          getUpperFrontCorner()                     const = 0;
            virtual ForcePointOptional          getUpperRearCorner()                      const = 0;
            virtual ForcePointOptional          getLowerFrontCorner()                     const = 0;
            virtual ForcePointOptional          getLowerRearCorner()                      const = 0;
            virtual double                      getFrontChordLength()                     const = 0;

            virtual ForcePointOptional          getFrontFoot()                            const = 0;
            virtual double                      getFrontFootWidth()                       const = 0;

            virtual ForcePointOptional          getRearFoot()                             const = 0;
            virtual double                      getRearFootWidth()                        const = 0;

            //Pick points
            virtual bool                        hasPickPoints()                           const = 0;
            virtual ForcePointMap               getPickPoints()                           const = 0;
            virtual std::vector<std::string>    getDefaultPickpoints()                    const = 0;
            virtual ForcePoints                 getActivePickPoints()                     const = 0;
            virtual void                        clearActivePickPoints() = 0;
            virtual bool                        setPickpointToActive(std::string name) = 0;
            virtual bool                        setPickpointsToActive(std::vector<std::string> names) = 0;
        };
    }
}
#endif //HARDWARECOMPONENT_H