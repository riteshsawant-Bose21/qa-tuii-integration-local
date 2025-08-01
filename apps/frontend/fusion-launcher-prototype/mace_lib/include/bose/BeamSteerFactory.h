#pragma once
#ifndef BEAMSTEERFACTORY_H
#define BEAMSTEERFACTORY_H
#include "BeamSteer.h"

namespace bosepro::acoustics
{
	/**
	 * \brief Factory singleton for creating beam steer objects. Thread-safe.
	 */
	class BeamSteerFactory
	{
	public:

		static BeamSteerFactory& instance();

		BeamSteerPtr				createBeam(const BeamSteer::BeamAlgorithm algorithm) const;

									~BeamSteerFactory() = default;
									BeamSteerFactory(const BeamSteerFactory&) = delete;
		BeamSteerFactory&			operator=(const BeamSteerFactory&) = delete;
									BeamSteerFactory(BeamSteerFactory&&) = delete;
		BeamSteerFactory&			operator=(BeamSteerFactory&&) = delete;

	private:
		explicit                    BeamSteerFactory() = default;
	};
}

#endif //BEAMSTEERFACTORY_H
