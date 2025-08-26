#pragma once
#ifndef COMPRESSIONSTRAP_H
#define COMPRESSIONSTRAP_H

#include <memory>
#include <list>
#include "HardwareComponent.h"

namespace bosepro::hardware
{
	class CompressionStrap;
	using CompressionStrapPtr = std::shared_ptr<CompressionStrap>;

	/**
	 * \brief Interface that represents a single compression strap component
	 */
	class CompressionStrap : public virtual HardwareComponent
	{
	public:
		virtual						~CompressionStrap()					= default;

		virtual double				getForceCapacity()					const = 0;
		virtual double           	getMaxForce()       			        	const = 0;
		virtual double				getCoGLength()					    const = 0;
        virtual double              getExpForceFraction()               const = 0;
        virtual double              getExpForceAdder()                  const = 0;

	protected:
		CompressionStrap() = default;
	};
}

#endif //COMPRESSIONSTRAP_H
