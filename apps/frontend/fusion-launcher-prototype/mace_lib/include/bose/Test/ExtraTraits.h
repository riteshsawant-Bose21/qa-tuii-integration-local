#pragma once

#ifndef EXTRATRAITS_H
#define EXTRATRAITS_H

#include <type_traits>
#include <utility>

// Copyright 2020 BOSE Corp. Inc.
// author: Keith Albright 9/11/2020 created for expanded AssertHelpers.h to conveniently use in GTests.
// 
//   Now a separate file.  Clients might want to use in static_assert in their classes.
//   e.g. static_assert(nostd::has_operator_plus<foo>::value);
// 
// * For some reason the compound assignment aliases like has_operator_plus_assign and related don't work for primitive types, only classes.  
//   So, doing nostd::has_operator_plus<int>::value will return false!  Maybe expected?
//   but one can write int n = 0, n += 2;  So who implements the compound assign operator?  compiler magic?
// 
//   But, why does has_operator_plus<int> work?

// Template helper for testing if operators implemented in class
// idea from StackOverflow https://stackoverflow.com/questions/6534041/how-to-check-whether-operator-exists
// added missing traits modeled after std instead. (like std::plus) found in <xstddef> and <functional>
namespace nostd
{
    template<class _Ty = void>
    struct bit_left_shift
    {	// functor for operator bit_left_shift
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator << to operands
            return (_Left << _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_left_shift
    template<>
    struct bit_left_shift<void>
    {	// transparent functor for operator <<
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) << static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator << to operands
            return (static_cast<_Ty1&&>(_Left) << static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct bit_right_shift
    {	// functor for operator >>
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator >> to operands
            return (_Left >> _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_right_shift
    template<>
    struct bit_right_shift<void>
    {	// transparent functor for operator >>
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) >> static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator >> to operands
            return (static_cast<_Ty1&&>(_Left) >> static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct plus_assign
    {	// functor for operator+=
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator+= to operands
            return (_Left += _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION plus_assign
    template<>
    struct plus_assign<void>
    {	// transparent functor for operator +=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) += static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator += to operands
            return (static_cast<_Ty1&&>(_Left) += static_cast<_Ty2&&>(_Right));
        }
    };


    template<class _Ty = void>
    struct minus_assign
    {
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator-= to operands
            return (_Left -= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION minus_assign
    template<>
    struct minus_assign<void>
    {	// transparent functor for operator-=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) -= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator-= to operands
            return (static_cast<_Ty1&&>(_Left) -= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct multiplies_assign
    {
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator*= to operands
            return (_Left *= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION multiplies_assign
    template<>
    struct multiplies_assign<void>
    {	// transparent functor for operator*=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) *= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator*= to operands
            return (static_cast<_Ty1&&>(_Left) *= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct divides_assign
    {
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator/= to operands
            return (_Left /= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION divides_assign
    template<>
    struct divides_assign<void>
    {	// transparent functor for operator/=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) /= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator/= to operands
            return (static_cast<_Ty1&&>(_Left) /= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct modulus_assign
    {
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator%= to operands
            return (_Left %= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION modulus_assign
    template<>
    struct modulus_assign<void>
    {	// transparent functor for operator%=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) %= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator%= to operands
            return (static_cast<_Ty1&&>(_Left) %= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct bit_left_shift_assign
    {	// functor for operator bit_left_shift_assign
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator <<= to operands
            return (_Left <<= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_left_shift_assign
    template<>
    struct bit_left_shift_assign<void>
    {	// transparent functor for operator <<=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) <<= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator <<= to operands
            return (static_cast<_Ty1&&>(_Left) <<= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct bit_right_shift_assign
    {	// functor for operator >>=
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator >>= to operands
            return (_Left >>= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_right_shift_assign
    template<>
    struct bit_right_shift_assign<void>
    {	// transparent functor for operator >>=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) >>= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator >>= to operands
            return (static_cast<_Ty1&&>(_Left) >>= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct bit_and_assign
    {	// functor for operator bit_and_assign
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator &= to operands
            return (_Left &= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_and_assign
    template<>
    struct bit_and_assign<void>
    {	// transparent functor for operator &=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) &= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator &= to operands
            return (static_cast<_Ty1&&>(_Left) &= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct bit_or_assign
    {	// functor for operator |=
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator |= to operands
            return (_Left |= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_or_assign
    template<>
    struct bit_or_assign<void>
    {	// transparent functor for operator |=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) |= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator |= to operands
            return (static_cast<_Ty1&&>(_Left) |= static_cast<_Ty2&&>(_Right));
        }
    };

    template<class _Ty = void>
    struct bit_xor_assign
    {	// functor for operator ^=
        constexpr _Ty operator()(const _Ty& _Left, const _Ty& _Right) const
        {	// apply operator ^= to operands
            return (_Left ^= _Right);
        }
    };

    // STRUCT TEMPLATE SPECIALIZATION bit_xor_assign
    template<>
    struct bit_xor_assign<void>
    {	// transparent functor for operator ^=
        typedef int is_transparent;

        template<class _Ty1, class _Ty2>
        constexpr auto operator()(_Ty1&& _Left, _Ty2&& _Right) const
            -> decltype(static_cast<_Ty1&&>(_Left) ^= static_cast<_Ty2&&>(_Right))
        {	// transparently apply operator ^= to operands
            return (static_cast<_Ty1&&>(_Left) ^= static_cast<_Ty2&&>(_Right));
        }
    };
}

namespace opTest
{
    // this apparently uses SFINAE (substitution failure is not an error) in order to test for existence of operators.
    template<class X, class Y, class Op>
    struct op_valid_impl
    {
        template<class U, class L, class R>
        static auto test(int) -> decltype(std::declval<U>()(std::declval<L>(), std::declval<R>()),
            void(), std::true_type());

        template<class U, class L, class R>
        static auto test(...)->std::false_type;

        using type = decltype(test<Op, X, Y>(0));
    };
    template<class X, class Op> using op_valid = typename op_valid_impl<X, X, Op>::type;

    // aliases to make tests easier
    // comparison
    template<class X> using has_operator_equal = op_valid<X, std::equal_to<>>;
    template<class X> using has_operator_not_equal = op_valid<X, std::not_equal_to<>>;
    template<class X> using has_operator_less = op_valid<X, std::less<>>;
    template<class X> using has_operator_less_equal = op_valid<X, std::less_equal<>>;
    template<class X> using has_operator_greater = op_valid<X, std::greater<>>;
    template<class X> using has_operator_greater_equal = op_valid<X, std::greater_equal<>>;

    // arithmetic ops
    template<class X> using has_operator_plus = op_valid<X, std::plus<>>;
    template<class X> using has_operator_minus = op_valid<X, std::minus<>>;
    template<class X> using has_operator_multiply = op_valid<X, std::multiplies<>>;
    template<class X> using has_operator_divide = op_valid<X, std::divides<>>;
    template<class X> using has_operator_modulus = op_valid<X, std::modulus<>>;
    template<class X> using has_operator_negate = op_valid<X, std::negate<>>;

    // logical
    template<class X> using has_operator_logical_and = op_valid<X, std::logical_and<>>;
    template<class X> using has_operator_logical_or = op_valid<X, std::logical_or<>>;
    template<class X> using has_operator_logical_not = op_valid<X, std::logical_not<>>;

    // bitwise
    template<class X> using has_operator_bit_and = op_valid<X, std::bit_and<>>;
    template<class X> using has_operator_bit_or = op_valid<X, std::bit_or<>>;
    template<class X> using has_operator_bit_not = op_valid<X, std::bit_not<>>;
    template<class X> using has_operator_bit_xor = op_valid<X, std::bit_xor<>>;    
    template<class X> using has_operator_bit_left_shift = op_valid<X, nostd::bit_left_shift<>>;
    template<class X> using has_operator_bit_right_shift = op_valid<X, nostd::bit_right_shift<>>;


    // compound arithmetic assign ops
    template<class X> using has_operator_plus_assign = op_valid<X, nostd::plus_assign<>>;
    template<class X> using has_operator_minus_assign = op_valid<X, nostd::minus_assign<>>;
    template<class X> using has_operator_multiply_assign = op_valid<X, nostd::multiplies_assign<>>;
    template<class X> using has_operator_divide_assign = op_valid<X, nostd::divides_assign<>>;
    template<class X> using has_operator_modulus_assign = op_valid<X, nostd::modulus_assign<>>;
    template<class X> using has_operator_bit_left_shift_assign = op_valid<X, nostd::bit_left_shift_assign<>>;
    template<class X> using has_operator_bit_right_shift_assign = op_valid<X, nostd::bit_right_shift_assign<>>;
    template<class X> using has_operator_bit_and_assign = op_valid<X, nostd::bit_and_assign<>>;
    template<class X> using has_operator_bit_or_assign = op_valid<X, nostd::bit_or_assign<>>;
    template<class X> using has_operator_bit_xor_assign = op_valid<X, nostd::bit_xor_assign<>>;
}


#endif