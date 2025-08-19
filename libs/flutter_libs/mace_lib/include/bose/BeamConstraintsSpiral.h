#pragma once
#ifndef BEAMCONSTRAINTSSPIRAL_H
#define BEAMCONSTRAINTSSPIRAL_H

#include "BeamConstraints.h"

namespace bosepro::acoustics
{
	class BeamConstraintsSpiral : public virtual BeamConstraints
	{
	public:

		virtual math::Vec3              getNearTopPoint() const = 0;
		virtual math::Vec3              getFarTopPoint() const = 0;
		virtual math::Vec3              getFarBottomPoint() const = 0;
		virtual math::Vec3              getNearBottomPoint() const = 0;

		virtual math::Vec3              getTrueNearVerticalTop() const = 0;
		virtual math::Vec3              getTrueNearVerticalBottom() const = 0;

		// Assumes nearTopPoint is 0,0,0 at base of speaker
		virtual bool                    isValid(math::Vec3 testPoint) const = 0;

		// Assumes nearTopPoint is 0,0,0 at base of speaker. Bottom angle is in degrees
		virtual bool                    isValid(math::Angle bottomAngle, double bottomDistance) const = 0;

		// takes the given bottom angle/distance and modifies them to fit into the valid area, if necessary
		virtual void                    closestValidPoint(math::Angle& bottomAngle, double& bottomDistance) const = 0;

		// given the top angle and distance, calculate the 5 vertices for the valid area
		virtual void                    getPointsFromTopValues(math::Angle topAngle, double topDistance,
										math::Vec3& trueNearBottom, math::Vec3& trueNearTop, math::Vec3& farTop,
										math::Vec3& farBottom, math::Vec3& nearBottom) const = 0;
	};
}
#endif