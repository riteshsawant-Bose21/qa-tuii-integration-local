#pragma once
#ifndef HARDWARECOMPONENTTYPES_H
#define HARDWARECOMPONENTTYPES_H

#include <string>

namespace bosepro::hardware
{
	/**
	 * \brief  Enum for component type designations
	 */
	enum class ComponentType : unsigned int
	{
		Unknown = 0,
		MidHigh = 1,
		Sub = 2,
		Grid = 3,
		Pullback = 4,
		Bracket = 5,
		CompressionStrap = 6,
		Slider = 7,
        GroundComponent = 8 // lies on the ground
	};

	/**
	 * \brief Get string from component type enum value
	 */
	static inline std::string componentTypeToString(ComponentType ct)
	{
		std::string str;

		switch (ct)
		{
		case ComponentType::MidHigh:
            str = "MidHigh";
            break;
		case ComponentType::Sub:
            str = "Sub";
            break;
		case ComponentType::Grid:
            str = "Grid";
            break;
		case ComponentType::Pullback:
            str = "Pullback";
            break;
		case ComponentType::Bracket:
            str = "Bracket";
            break;
		case ComponentType::CompressionStrap:
            str = "CompressionStrap";
            break;
		case ComponentType::Slider:
            str = "Slider";
            break;
        case ComponentType::GroundComponent:
            str = "Ground";
            break;
        case ComponentType::Unknown:
        default:
            str = "Unknown";
            break;
		}

		return str;
	}

	/**
	 * \brief Get component type enum value from string
	 */
	static inline ComponentType componentTypeFromString(const std::string& str)
	{
		ComponentType ct = ComponentType::Unknown;

		if (str == "Unknown")				ct = ComponentType::Unknown;
		else if (str == "MidHigh")			ct = ComponentType::MidHigh;
		else if (str == "Sub")				ct = ComponentType::Sub;
		else if (str == "Grid")				ct = ComponentType::Grid;
		else if (str == "Pullback")			ct = ComponentType::Pullback;
		else if (str == "Bracket")			ct = ComponentType::Bracket;
		else if (str == "CompressionStrap") ct = ComponentType::CompressionStrap;
		else if (str == "Slider")			ct = ComponentType::Slider;
        else if (str == "Ground")           ct = ComponentType::GroundComponent;

		return ct;
	}
}
#endif //HARDWARECOMPONENTTYPES_H
