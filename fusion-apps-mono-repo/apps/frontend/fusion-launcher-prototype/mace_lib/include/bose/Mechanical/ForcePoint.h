#pragma once
#ifndef FORCEPOINT_H
#define FORCEPOINT_H

#include <map>
#include <optional>
#include <utility>
#include "Math/Vector.h"

namespace bosepro::mechanical
{
	class ForcePoint;

	using ForcePoints			= std::vector<ForcePoint>;
	using ForcePointOptional	= std::optional<ForcePoint>;
	using ForcePointMap			= std::map<std::string, ForcePoint>;

	/**
	 * \brief A point in 3D space, with a working load limit. Immutable
	 *  can be used to represent the working load limit of 2 points, as long as they are symmetric along the Y axis
	 */
	class ForcePoint
	{
	public:
		ForcePoint() = default;

		/**
		 * \brief
		 * \param point		: location of point in 3d space
		 * \param kilos		: amount of kilos supported by this point (per item)
		 * \param numItems	: number of points this is representing (e.g. symmetrical left/right points may be represented as a point with 2 items)
		 * \param name		: user identifiable name of the point
		 * \param category	: user identifiable category of the point (e.g. "Center", "Side", "Multipoint")
		 */
		explicit            ForcePoint(math::Vec3 point, const double kilos = 0.0, const int numItems = 1, std::string name = "", std::string category = "")
			: _point{ point }, _kilos{ kilos }, _numItems{ numItems }, _name{ std::move(name) }, _category{ std::move(category) } {}

		/**
		 * \brief gets the total load limit of this point, accounting for number of actual points
		 * \return total load limit in kgs
		 */
		auto                totalLoadLimit()                                        const { return _kilos * _numItems; }

		/**
		 * \brief how many points is this representing? affects total load limit
		 */
		auto                itemCount()                                             const { return _numItems; }

		/**
		 * \brief location of the ForcePoint in 3d space
		 */
		auto                point()                                                 const { return _point; }

		auto                x()                                                     const { return _point.x; }
		auto                y()                                                     const { return _point.y; }
		auto                z()                                                     const { return _point.z; }

		auto				name()													const { return _name; }
		auto				category()												const { return _category; }

        math::Vec3          getPoint()                                              const { return _point; }

		/**
		 * \return returns true if both ForcePoints have the same point, weight limit, number of items, and name
		 */
		friend inline auto	operator==(const ForcePoint& lhs, const ForcePoint& rhs)
							{
								return lhs._numItems	== rhs._numItems && 
										lhs._kilos		== rhs._kilos	 &&    
										lhs._point		== rhs._point	 && 
										lhs._name		== rhs._name	 &&
										lhs._category	== rhs._category;
							}

		friend inline auto	operator!=(const ForcePoint& lhs, const ForcePoint& rhs) { return !(lhs == rhs); }

	protected:
		math::Vec3          _point		{ 0.0, 0.0, 0.0 };
		double              _kilos		{ 0.0 };			// WLL per item
		int                 _numItems	{ 1 };
		std::string			_name		{ "" };
		std::string			_category	{ "" };
	};

	static inline bool operator==(const ForcePoints& lhs, const ForcePoints& rhs)
    {
        bool equal = false;

        if(lhs.size() == rhs.size())
        {
            equal = true;

            for(std::size_t i = 0; i < lhs.size(); ++i)
            {
                if(lhs[i] != rhs[i])
                {
                    equal = false;
                    break;
                }
            }
        }

        return equal;
    }
}

#endif // FORCEPOINT_H
