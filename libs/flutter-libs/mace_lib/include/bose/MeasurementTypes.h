#pragma once
#ifndef BOSEPRO_MEASUREMENT_TYPES_H__
#define BOSEPRO_MEASUREMENT_TYPES_H__

namespace bosepro
{
	/**
	* \class          MeasurementType
	*
	* \brief          Enum for measurement type designations
	*/
	enum class					MeasurementType : unsigned int
	{
		CoverageMap = 0,
		LevelOverDistance = 1,
		FrequencyResponse = 2,
        // TimeResponse = 3, // ultimately this would be useful once the algorithm for arrival times is determined.
        Raw = 3
	};

}
#endif // !BOSEPRO_MEASUREMENT_TYPES_H__
