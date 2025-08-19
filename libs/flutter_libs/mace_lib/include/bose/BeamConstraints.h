#ifndef BEAMCONSTRAINTS_H
#define BEAMCONSTRAINTS_H

#include <memory>
#include "Math/Angle.h"
#include "Math/Vector.h"

namespace bosepro::acoustics
{
    class BeamConstraints;
    using BeamConstraintsPtr = std::shared_ptr<BeamConstraints>;

    /**
     * \brief Represents a set of constraints (angles, distances) of a beam
     */
    class BeamConstraints
    {
    public:

        virtual                         ~BeamConstraints() = default;
        BeamConstraints() = default;
        BeamConstraints(const BeamConstraints&) = delete;
        BeamConstraints& operator=(const BeamConstraints&) = delete;
        BeamConstraints(BeamConstraints&&) = delete;
        BeamConstraints& operator=(BeamConstraints&&) = delete;

        // Steer/Spread limits defined in UI§3.1.1
        static const math::Angle& SpreadLimitOneMode() { static math::Angle a{ 30.0, math::Angle::Units::Degrees }; return a; }
        static const math::Angle& SpreadLimitTwoMod() { static math::Angle a{ 40.0, math::Angle::Units::Degrees }; return a; }
        static const math::Angle& SpreadLimitThreeMod() { static math::Angle a{ 40.0, math::Angle::Units::Degrees }; return a; }

        // Minimum distance the throw line can be from the speaker - see UI§2.1.2
        static double                   distanceMinimum() { return 1.4; }

        static const math::Angle& steerMaximum() { static math::Angle a(20.0, math::Angle::Units::Degrees); return a; }
        static const math::Angle& steerMinimum() { static math::Angle a(-20.0, math::Angle::Units::Degrees); return a; }

        static std::size_t				moduleCountMinimum() { return 1u; }
        static std::size_t				moduleCountMaximum() { return 3u; }

        static const math::Angle& spreadMinimum() { static math::Angle a(0.0, math::Angle::Units::Degrees); return a; }

        virtual math::Angle             spreadMaximum()			const = 0;

        virtual double                  bottomDistanceMinimum() const = 0;
        virtual double                  topDistanceMinimum()	const = 0;

        virtual math::Angle             getMaxTopAngle()		const = 0;
        virtual math::Angle             getMinTopAngle()		const = 0;
        virtual math::Angle             getMaxBottomAngle()		const = 0;
        virtual math::Angle             getMinBottomAngle()		const = 0;

        virtual void                    getSteerSpreadFromAngles(math::Angle topAngle, double topDistance,
            math::Angle botAngle, double bottomDistance,
            math::Angle& steering, math::Angle& spreading)		const = 0;

        // checks
        virtual bool                    isValidSteer(math::Angle steer)												const = 0;
        virtual bool                    isValidSpread(math::Angle steer)											const = 0;

        // getters
        virtual std::size_t				moduleCount()			const = 0;

        virtual bool                    hasSteering()			const = 0;
        virtual bool                    hasSpreading()			const = 0;
        virtual bool                    hasSmoothing()			const = 0;

        virtual math::Angle             steering()				const = 0;
        virtual math::Angle             spreading()				const = 0;
        virtual bool                    smoothing()				const = 0;

        virtual math::Angle             topAngle()				const = 0;
        virtual math::Angle             bottomAngle()			const = 0;

        virtual double                  bottomDistance()		const = 0;
        virtual double                  topDistance()			const = 0;

        virtual math::Vec3              getTopPoint()			const = 0;
        virtual math::Vec3              getBottomPoint()		const = 0;

        virtual bool                    setModuleCount(std::size_t count) = 0;

        virtual void                    setSmoothing(bool value) = 0;

        virtual bool                    setSteering(math::Angle& value) = 0;
        virtual bool                    setSteering(math::Angle& value, math::Angle& topAngle, math::Angle& botAngle) = 0;

        virtual bool                    setSpreading(math::Angle& value) = 0;
        virtual bool                    setSpreading(math::Angle& value, math::Angle& topAngle, math::Angle& botAngle) = 0;

        virtual bool                    setTopValues(math::Angle& value, double& distance) = 0;
        virtual bool                    setTopValues(math::Angle& value, double& distance, math::Angle& steer, math::Angle& spread) = 0;
        virtual bool                    setBottomValues(math::Angle& value, double& distance) = 0;
        virtual bool                    setBottomValues(math::Angle& value, double& distance, math::Angle& steer, math::Angle& spread) = 0;

        virtual bool                    setTopAngle(math::Angle& value) = 0;
        virtual bool                    setTopAngle(math::Angle& value, math::Angle& steer, math::Angle& spread) = 0;

        virtual bool                    setBottomAngle(math::Angle& value) = 0;
        virtual bool                    setBottomAngle(math::Angle& value, math::Angle& steer, math::Angle& spread) = 0;

        virtual bool                    setTopDistance(double value) = 0;
        virtual bool                    setBottomDistance(double value) = 0;

        virtual double                  getCombinedModuleHeight() const = 0;

        virtual void                    initialize() = 0;

        virtual void                    loadValues(math::Angle topAngle, double topDistance, math::Angle botAngle, double botDistance) = 0;
    };
}
#endif //BEAMCONSTRAINTS_H