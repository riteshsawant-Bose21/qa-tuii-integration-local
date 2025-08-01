#pragma once
#ifndef FUZZY_COMPARE_H
#define FUZZY_COMPARE_H

#include <type_traits>
#include <limits>
#include <cmath>

namespace bosepro
{
	namespace math
	{
		// Sources:
		// Knuth, Semi-numerical Algorithms TAOCP, Section 4.2.2
		// see https://randomascii.wordpress.com/2012/02/25/comparing-floating-point-numbers-2012-edition/ for nuances
		// see https://news.ycombinator.com/item?id=13998564 for discussion of another post

		/**
		 * \brief the default number of epsilons to use to define the acceptable threshold for determining equality between floating point numbers
		 */
		constexpr auto defaultNumEpsilons = 25;

		/**
		 * \brief compares and returns whether the two values are equal.
		 *	      this is the non floating point version of a generic number comparison template class
         *        that will work with integrals or any object with a comparison operator
		 * \tparam Type
		 * \param a	: parameter 1
		 * \param b : parameter 2
		 * \return returns result of a == b
		 */
        template <typename Type> typename std::enable_if<!std::is_floating_point<Type>::value, bool>::type
        constexpr isApproximatelyEqual(const Type& a, const Type& b)
		{
			return a == b;
		}

		/**
		 * \brief compares and returns whether the two floating point values are equal. uses a mix of relative and absolute epsilons
		 *		  to determine equality between floating points.
		 *	      this is the floating point version of a generic number comparison template class
		 * \tparam FloatingType
		 * \param a : floating point parameter 1
		 * \param b : floating point parameter 2
		 * \param numEpsilonTolerance : the number of epsilons to use as a threshold for equality. value of epsilon is based on FloatingType
		 * \return true if approximately equal
		 */
		template <typename FloatingType> typename std::enable_if<std::is_floating_point<FloatingType>::value, bool>::type
        constexpr isApproximatelyEqual(const FloatingType& a, const FloatingType& b, int numEpsilonTolerance = defaultNumEpsilons)
		{
			if (a == b) return true;

			// FLT_EPSILON 1.1920929e-07F
			// DBL_EPSILON 2.2204460492503131e-16
			constexpr auto eps = std::numeric_limits<FloatingType>::epsilon();

			auto diff = std::fabs(a - b);
			auto A = std::fabs(a);
			auto B = std::fabs(b);
			auto greatest = A > B ? A : B;

			// for near-zero comparisons, use absolute epsilon (based on greatest input value)
			if (numEpsilonTolerance * eps > greatest)
				return true;

			// NOTE: Need <= not < here to allow zero to match zero if the abs check above removed
			return  diff <= eps * greatest * numEpsilonTolerance;
		}

        /**
		 * \brief compares the given integral value against zero
		 * \tparam IntegralType
		 * \param a : the integral value to test against zero
		 * \return returns whether the given integral value equals zero
		 */
		template <typename IntegralType> typename std::enable_if<std::is_integral<IntegralType>::value, bool>::type
        constexpr isApproximatelyZero(const IntegralType& a)
		{
			return a == 0;
		}

		/**
		 * \brief compares the given floating point value against zero
		 * \tparam FloatingType
		 * \param a : the floating point value to test against zero
		 * \param numEpsilonTolerance : the number of epsilons to use as a threshold for equality. value of epsilon is based on FloatingType
		 * \return returns whether the given floating point value equals zero
		 */
		template <typename FloatingType> typename std::enable_if<std::is_floating_point<FloatingType>::value, bool>::type
        constexpr isApproximatelyZero(const FloatingType& a, int numEpsilonTolerance = defaultNumEpsilons)
		{
			return isApproximatelyEqual(a, static_cast<FloatingType>(0.0), numEpsilonTolerance);
		}
	}
} // namespace

#endif // FUZZY_COMPARE_H
