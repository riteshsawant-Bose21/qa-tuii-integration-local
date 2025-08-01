#pragma once
#ifndef FORCEVECTOR_H
#define FORCEVECTOR_H

#include "Math/Angle.h"
#include "Math/Vector.h"

namespace bosepro::mechanical
{
	/**
	 * \brief A force in 3D space, with direction and magnitude. Immutable
	 */
	class ForceVector
	{
	public:
						ForceVector()												= default;
						ForceVector(const double x, const double y, const double z) : ForceVector{{x,y,z}}			{}
		explicit        ForceVector(const math::Vec3 forceVec)						: _force{ forceVec }			{}

		 /**
		 * \brief gets the magnitude (length) of the force vector
		 */
		auto            magnitude()													const { return _force.length(); }

		 /**
		 * \brief gets the angle measured in the x-z plane, the positive x-axis being 0.
		 * \return the angle can vary from -180 to +180 degrees
		 */
		auto            angle()														const
						{
							math::Angle angle;
							if (_force.z >= 0)
								angle = -std::acos(math::SafeDivide(_force.x, magnitude()));
							else
								angle = std::acos(math::SafeDivide(_force.x, magnitude()));

							return angle;
						}

		auto            forceVector()												const { return _force; }
		auto            x()															const { return _force.x; }
		auto            y()															const { return _force.y; }
		auto            z()															const { return _force.z; }

	private:
		math::Vec3      _force{ 0.0,0.0,0.0 };
	};
}
#endif // FORCEVECTOR_H