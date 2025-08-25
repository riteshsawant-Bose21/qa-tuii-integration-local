#pragma once
#ifndef MATH_UTILS_H
#define MATH_UTILS_H

#include <cmath>
#include <cassert>
#include <type_traits>
#include <limits>
#include <iterator>
#include "MathConstants.h"

namespace bosepro
{
	namespace math
	{
        template<typename T> constexpr bool Between(T val, T start, T end) { return val >= start && val <= end; }
		//Radians/Degrees conversions
		template<typename T> constexpr T    ConvertRadiansToDegrees(T angle) { return angle * RadToDeg<T>; static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }
		template<typename T> constexpr T    ConvertDegreesToRadians(T angle) { return angle * DegToRad<T>; static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Clamp a value to a value between lower and upper limit (std::clamp is C++17)
		template<typename T> constexpr T    Clamp(T value, T lowerLimit, T upperLimit) { return value < lowerLimit ? lowerLimit : (value > upperLimit ? upperLimit : value); /*no type check : valid for non numerics*/ }

		//Tests for zero and returns the smallest finite value instead of zero
		template<typename T> constexpr T    SafeZero(T value) { return std::abs(value) != T(0) ? value : std::numeric_limits<T>::min(); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Division with zero protection. If divisor or dividend is zero will return zero
		template<typename T> constexpr T    SafeDivide(T dividend, T divisor) { return dividend == T(0) ? T(0) : (divisor == T(0) ? T(0) : dividend / divisor); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Log10 with negative and zero protection.
		template<typename T> constexpr T    SafeLog10(T value) { return std::log10(std::fabs(SafeZero(value))); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic point type required"); }

		//Sqrt with negative and zero protection. Returns zero if input is <= zero
		template<typename T> constexpr T    SafeSqrt(T value) { return value <= T(0) ? T(0) : std::sqrt(value); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Sqrt reciprocal with negative and zero protection. Returns zero if input is <= zero
		template<typename T> constexpr T    SafeInverseSqrt(T value) { return SafeDivide(T(1), SafeSqrt(value)); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic point type required"); }

		//Rounding
		template<typename T> constexpr T    RoundToTenths(T value) { return std::floor(value * T(10.0) + T(0.5)) * T(0.1);  static_assert(std::is_floating_point<T>(), "Error: floating point type required"); }
		template<typename T> constexpr T    RoundToHundreths(T value) { return std::floor(value * T(100.0) + T(0.5)) * T(0.01); static_assert(std::is_floating_point<T>(), "Error: floating point type required"); }

		//Calculate the % of value within the range of lower and upper. With zero protection.
		template<typename T> constexpr T    PercentageOfRange(T value, T lower, T upper) { return upper == lower ? T(0) : SafeDivide((value - lower), (upper - lower)); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Conditional swap of two values based on result of less than comparison
		template<typename T> constexpr bool SwapIf(T& lhs, T& rhs, bool bIsLower = true) { if (bIsLower == lhs < rhs) { std::swap(lhs, rhs); return true; } return false; /*no type check : valid for non numerics*/ }

		//Real number parts (significand.exponent) Example: RealPart(3.14) returns sig = 3.0 and exp = 0.14
		template<typename T> void		    RealPart(T value, T& sig, T& exp) { exp = std::modf(value, &sig); static_assert(std::is_floating_point<T>(), "Error: floating point type required"); }
		template<typename T> T			    RealPartSignificand(T value) { T sig; T exp; RealPart(value, sig, exp); return sig; static_assert(std::is_floating_point<T>(), "Error: floating point type required"); }
		template<typename T> T			    RealPartExponent(T value) { T sig; T exp; RealPart(value, sig, exp); return exp; static_assert(std::is_floating_point<T>(), "Error: floating point type required"); }

		//Determine which of two targets {t1, t2} a value (val) is nearest to
		template<typename T> constexpr T    Nearest(T t1, T t2, T val) { auto delta2 = val < t2 ? t2 - val : val - t2; auto delta1 = val > t1 ? val - t1 : t1 - val; return (delta1 < delta2) ? t1 : t2; /*no type check : valid for non numerics*/ }

		//Returns true if value is a multiple of a number or ZERO
		template<typename T> constexpr bool IsMultipleOf(T value, T testAgainst, T tolerance = 0.00001) { auto r = std::fabs(std::fmod(value, testAgainst)); return (r < tolerance) || (testAgainst - r < tolerance); static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Lbs/Kgs conversion
		template<typename T> constexpr T    ConvertLbsToKgs(T lbs) { return lbs * 0.45359237;    static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }
		template<typename T> constexpr T    ConvertKgsToLbs(T kgs) { return kgs * 2.20462262185; static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required"); }

		//Negative aware modulus that returns a value r in 0 <= r < |b| (NOTE: C/C++ return remainders < 0 for some combinations of negative inputs)
		template<typename T> constexpr auto PositiveMod(T a, T b)
		{
			static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required");

			auto c = T(0);

			assert(b != 0);

			if (b < 0) b = -b;

			if constexpr (std::is_floating_point_v<T>)
			{
				c = std::fmod(std::fmod(a, b) + b, b);
			}
			else if constexpr (std::is_integral_v<T>)
			{
				c = ((a % b) + b) % b;
			}

			return c;
		}

		// compute the triangular number that results for (N + N - 1 + N - 2 ...)
		template<typename T> constexpr T    TriangularNumber(const T& value) noexcept { return value >= 0 ? (value * (value + 1)) >> 1 : 0; static_assert(std::is_integral<T>(), "Error: Integral type required"); } // NOTE: for connections using pairs, pass value - 1.  See https://en.wikipedia.org/wiki/Triangular_number and https://stackoverflow.com/questions/2483918/what-is-the-proof-of-of-n-1-n-2-n-3-1-nn-1-2

		// Given a common sequence (1, 2, 3... or 3, 5, 7..., or 99, 98, 97... etc. compute the partial sum at any point of the sequence with any N of terms given the first term and the common dif (+1, -2, +3, etc.).)
		template<typename T> constexpr T	PartialSumOfSequence(const T& firstTerm, const std::size_t& n, const T& commonDif) noexcept // see https://www.dummies.com/education/math/calculus/how-to-find-the-partial-sum-of-an-arithmetic-sequence/ for a good example
		{
			static_assert(std::is_arithmetic<T>(), "Error: Arithmetic type required");

			// typically given by k/2(a1 + ak)
			// but we need the first term and the common difference to find the kth term of the sequence.
			// that is: kn = k1 + (k-1)d
			T kthTermInSequence = firstTerm + static_cast<T>(n - 1)* commonDif;
			T kthSum = static_cast<T> ((n * .5) * (firstTerm + kthTermInSequence));
			return kthSum;
		}

		//Determine if number is power of 2
		template<typename T> constexpr bool	isPowerOf2(T value) {return value > 0 && ((value & (value - 1)) == 0); static_assert(std::is_integral<T>(), "Error: Integral type required");}

		//Get next power of 2 
		template<typename T> constexpr T	nextPowerOf2(T value)
											{
												if(value > 0)
												{
													value -= 1;

													value |= value >> 1;
													value |= value >> 2;
													value |= value >> 4;
													value |= value >> 8;
													value |= value >> 16;

													value += 1;
												}

												return value;

												static_assert(std::is_integral<T>(), "Error: Integral type required"); 
											}

											//Get index of min element, ignores NaN's
		template<class ForwardIt> auto		indexOfMinElement(ForwardIt first, ForwardIt last)
											{
												//Can not use std::min_element 
												//https://stackoverflow.com/questions/55153210/do-stdmin0-0-1-0-and-stdmax0-0-1-0-yield-undefined-behavior

												std::size_t idx = 0;

												if(first != nullptr && last != nullptr && first != last)
												{
													auto min = std::numeric_limits<typename std::iterator_traits<ForwardIt>::value_type>::max();

													for(std::size_t i = 0; first != last; ++first, ++i)
													{
														//VS > 16.4.6 errors w/C2668 without the cast
														if(min > *first && !std::isnan(static_cast<double>(*first)))
														{
															idx = i;
															min = *first;
														}
													}
												}

												return idx;
											}

											//Get index of max element, ignores NaN's
		template<class ForwardIt> auto		indexOfMaxElement(ForwardIt first, ForwardIt last)
											{
												//Can not use std::max_element 
												//https://stackoverflow.com/questions/55153210/do-stdmin0-0-1-0-and-stdmax0-0-1-0-yield-undefined-behavior

												std::size_t idx = 0;

												if(first != nullptr && last != nullptr && first != last)
												{
													auto max = std::numeric_limits<typename std::iterator_traits<ForwardIt>::value_type>::min();

													for(std::size_t i = 0; first != last; ++first, ++i)
													{
														//VS > 16.4.6 errors w/C2668 without the cast
														if(max < *first && !std::isnan(static_cast<double>(*first)))
														{
															idx = i;
															max = *first;
														}
													}
												}

												return idx;
											}
	}
} // namespace

#endif // MATH_UTILS_H
