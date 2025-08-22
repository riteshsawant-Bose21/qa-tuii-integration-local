#pragma once
#ifndef ASSERTHELPERS_H
#define ASSERTHELPERS_H

#include <gtest/gtest.h>
#include <gmock/gmock.h>
#include "ExtraTraits.h"

// Improvement list:
// * seems weird to have these IS_ and NO_ methods when they are front ends for EXPECT.  They should probably be called EXPECT_IS_CTOR, etc.


#define DEFAULT_TOLERANCE 0.00001f

#define STATIC_ASSERT_EQ(val1, val2) static_assert(val1 == val2, #val1 " != " #val2); SUCCEED()
#define STATIC_ASSERT_NE(val1, val2) static_assert(val1 != val2, #val1 " == " #val2); SUCCEED()

#define ASSERT_NOT_NULL(object) ASSERT_FALSE(nullptr == object)
#define EXPECT_NOT_NULL(object) EXPECT_FALSE(nullptr == object)

#define ASSERT_NULL(object) ASSERT_TRUE(nullptr == object);
#define EXPECT_NULL(object) EXPECT_TRUE(nullptr == object);

#define ASSERT_VECTOR_NEAR_TOLERANCE(vec1, vec2, tolerance) \
    ASSERT_NEAR(vec1.x, vec2.x, tolerance); \
    ASSERT_NEAR(vec1.y, vec2.y, tolerance); \
    ASSERT_NEAR(vec1.z, vec2.z, tolerance)

#define EXPECT_VECTOR_NEAR_TOLERANCE(vec1, vec2, tolerance) \
    EXPECT_NEAR(vec1.x, vec2.x, tolerance); \
    EXPECT_NEAR(vec1.y, vec2.y, tolerance); \
    EXPECT_NEAR(vec1.z, vec2.z, tolerance)

#define ASSERT_VECTOR_NEAR(vec1, vec2) ASSERT_VECTOR_NEAR_TOLERANCE(vec1, vec2, DEFAULT_TOLERANCE)
#define EXPECT_VECTOR_NEAR(vec1, vec2) EXPECT_VECTOR_NEAR_TOLERANCE(vec1, vec2, DEFAULT_TOLERANCE)

#define ASSERT_EQ3(val1, val2, val3) \
    ASSERT_EQ(val1, val2); \
    ASSERT_EQ(val1, val3); \
    ASSERT_EQ(val2, val1)

#define EXPECT_EQ3(val1, val2, val3) \
    EXPECT_EQ(val1, val2); \
    EXPECT_EQ(val1, val3); \
    EXPECT_EQ(val2, val1)

#define ASSERT_NO_DEATH(statement) ASSERT_NO_FATAL_FAILURE(ASSERT_NO_THROW(statement))
#define EXPECT_NO_DEATH(statement) EXPECT_NO_FATAL_FAILURE(EXPECT_NO_THROW(statement))

#define ASSERT_CONTAINS(list,object) ASSERT_THAT(list,testing::Contains(object))
#define EXPECT_CONTAINS(list,object) EXPECT_THAT(list,testing::Contains(object))

#define ASSERT_NOT_CONTAINS(list,object) ASSERT_THAT(list,testing::Not(testing::Contains(object)))
#define EXPECT_NOT_CONTAINS(list,object) EXPECT_THAT(list,testing::Not(testing::Contains(object)))



// helpers from LockTest around construction
#define IS_DCTOR(obj)           EXPECT_TRUE((std::is_default_constructible<obj>::value));

#define IS_DTOR(obj)            EXPECT_TRUE((std::is_destructible<obj>::value)); \
                                EXPECT_TRUE((std::is_nothrow_destructible<obj>::value));

#define NO_CCTOR(obj)           EXPECT_FALSE((std::is_copy_constructible<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_copy_constructible<obj>::value)); \
                                EXPECT_FALSE((std::is_trivially_copy_constructible<obj>::value));

#define IS_CCTOR(obj)           EXPECT_TRUE((std::is_copy_constructible<obj>::value)); \
                                EXPECT_TRUE((std::is_nothrow_copy_constructible<obj>::value));                               

#define IS_EXCEPTING_CCTOR(obj) EXPECT_TRUE((std::is_copy_constructible<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_copy_constructible<obj>::value));

#define NO_COPY(obj)            EXPECT_FALSE((std::is_copy_assignable<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_copy_assignable<obj>::value)); \
                                EXPECT_FALSE((std::is_trivially_copy_assignable<obj>::value));

#define IS_COPY(obj)            EXPECT_TRUE((std::is_copy_assignable<obj>::value)); \
                                EXPECT_TRUE((std::is_nothrow_copy_assignable<obj>::value));

#define IS_EXCEPTING_COPY(obj)  EXPECT_TRUE((std::is_copy_assignable<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_copy_assignable<obj>::value));

#define NO_MCTOR(obj)           EXPECT_FALSE((std::is_move_constructible<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_move_constructible<obj>::value)); \
                                EXPECT_FALSE((std::is_trivially_move_constructible<obj>::value));

#define IS_MCTOR(obj)           EXPECT_TRUE((std::is_move_constructible<obj>::value)); \
                                EXPECT_TRUE((std::is_nothrow_move_constructible<obj>::value));

#define IS_EXCEPTING_MCTOR(obj) EXPECT_TRUE((std::is_move_constructible<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_move_constructible<obj>::value));

#define NO_MOVE(obj)            EXPECT_FALSE((std::is_move_assignable<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_move_assignable<obj>::value)); \
                                EXPECT_FALSE((std::is_trivially_move_assignable<obj>::value));

#define IS_MOVE(obj)            EXPECT_TRUE((std::is_move_assignable<obj>::value)); \
                                EXPECT_TRUE((std::is_nothrow_move_assignable<obj>::value));

#define IS_EXCEPTING_MOVE(obj)  EXPECT_TRUE((std::is_move_assignable<obj>::value)); \
                                EXPECT_FALSE((std::is_nothrow_move_assignable<obj>::value));

#define IS_CTOR1(obj, p1)       EXPECT_TRUE((std::is_reference<p1>::value)); \
                                EXPECT_TRUE((std::is_constructible<obj, p1>::value));

#define IS_CTOR2(obj, p1, p2)   EXPECT_TRUE((std::is_reference<p1>::value)); \
                                EXPECT_TRUE((std::is_reference<p2>::value)); \
                                EXPECT_TRUE((std::is_constructible<obj, p1, p2>::value)); 

#define IS_CTOR3(obj, p1, p2, p3)   EXPECT_TRUE((std::is_reference<p1>::value)); \
                                    EXPECT_TRUE((std::is_reference<p2>::value)); \
                                    EXPECT_TRUE((std::is_reference<p3>::value)); \
                                    EXPECT_TRUE((std::is_constructible<obj, p1, p2, p3>::value));

// arithmetic, comparison, bitwise, logical ops

// arithmetic
#define HAS_ARITHMETIC(obj)             EXPECT_TRUE((opTest::has_operator_plus<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_minus<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_multiply<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_divide<obj>::value));
                                        //EXPECT_TRUE((opTest::has_operator_modulus<obj>::value)); \
                                        //EXPECT_TRUE((opTest::has_operator_negate<obj>::value));

#define NO_ARITHMETIC(obj)              EXPECT_FALSE((opTest::has_operator_plus<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_minus<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_multiply<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_divide<obj>::value));
                                        //EXPECT_FALSE((opTest::has_operator_modulus<obj>::value)); \
                                        //EXPECT_FALSE((opTest::has_operator_negate<obj>::value));

#define HAS_PLUS(obj)                   EXPECT_TRUE((opTest::has_operator_plus<obj>::value));
#define HAS_MINUS(obj)                  EXPECT_TRUE((opTest::has_operator_minus<obj>::value));
#define HAS_MULTIPLY(obj)               EXPECT_TRUE((opTest::has_operator_multiply<obj>::value));
#define HAS_DIVIDE(obj)                 EXPECT_TRUE((opTest::has_operator_divide<obj>::value));
#define HAS_MODULUS(obj)                EXPECT_TRUE((opTest::has_operator_modulus<obj>::value));
#define HAS_NEGATE(obj)                 EXPECT_TRUE((opTest::has_operator_negate<obj>::value));

#define NO_PLUS(obj)                    EXPECT_FALSE((opTest::has_operator_plus<obj>::value));
#define NO_MINUS(obj)                   EXPECT_FALSE((opTest::has_operator_minus<obj>::value));
#define NO_MULTIPLY(obj)                EXPECT_FALSE((opTest::has_operator_multiply<obj>::value));
#define NO_DIVIDE(obj)                  EXPECT_FALSE((opTest::has_operator_divide<obj>::value));
#define NO_MODULUS(obj)                 EXPECT_FALSE((opTest::has_operator_modulus<obj>::value));
#define NO_NEGATE(obj)                  EXPECT_FALSE((opTest::has_operator_negate<obj>::value));

// compound assign
#define HAS_ARITHMETIC_ASSIGN(obj)      EXPECT_TRUE((opTest::has_operator_plus_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_minus_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_multiply_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_divide_assign<obj>::value));
                                        //EXPECT_TRUE((opTest::has_operator_modulus_assign<obj>::value));                                    

#define NO_ARITHMETIC_ASSIGN(obj)       EXPECT_FALSE((opTest::has_operator_plus_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_minus_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_multiply_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_divide_assign<obj>::value));
                                        //EXPECT_FALSE((opTest::has_operator_modulus_assign<obj>::value));   

#define HAS_PLUS_ASSIGN(obj)            EXPECT_TRUE((opTest::has_operator_plus_assign<obj>::value));
#define HAS_MINUS_ASSIGN(obj)           EXPECT_TRUE((opTest::has_operator_minus_assign<obj>::value));
#define HAS_MULTIPLY_ASSIGN(obj)        EXPECT_TRUE((opTest::has_operator_multiply_assign<obj>::value));
#define HAS_DIVIDE_ASSIGN(obj)          EXPECT_TRUE((opTest::has_operator_divide_assign<obj>::value));
#define HAS_MODULUS_ASSIGN(obj)         EXPECT_TRUE((opTest::has_operator_modulus_assign<obj>::value));

#define NO_PLUS_ASSIGN(obj)             EXPECT_FALSE((opTest::has_operator_plus_assign<obj>::value));
#define NO_MINUS_ASSIGN(obj)            EXPECT_FALSE((opTest::has_operator_minus_assign<obj>::value));
#define NO_MULTIPLY_ASSIGN(obj)         EXPECT_FALSE((opTest::has_operator_multiply_assign<obj>::value));
#define NO_DIVIDE_ASSIGN(obj)           EXPECT_FALSE((opTest::has_operator_divide_assign<obj>::value));
#define NO_MODULUS_ASSIGN(obj)          EXPECT_FALSE((opTest::has_operator_modulus_assign<obj>::value));

// bit assign
#define HAS_BIT_ASSIGN(obj)             EXPECT_TRUE((opTest::has_operator_bit_and_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_or_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_xor_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_left_shift_assign<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_right_shift_assign<obj>::value));

#define NO_BIT_ASSIGN(obj)              EXPECT_FALSE((opTest::has_operator_bit_and_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_or_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_xor_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_left_shift_assign<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_right_shift_assign<obj>::value));

#define HAS_BIT_AND_ASSIGN(obj)         EXPECT_TRUE((opTest::has_operator_bit_and_assign<obj>::value));
#define HAS_BIT_OR_ASSIGN(obj)          EXPECT_TRUE((opTest::has_operator_bit_or_assign<obj>::value));
#define HAS_BIT_XOR_ASSIGN(obj)         EXPECT_TRUE((opTest::has_operator_bit_xor_assign<obj>::value));
#define HAS_BIT_LEFT_SHIFT_ASSIGN(obj)  EXPECT_TRUE((opTest::has_operator_bit_left_shift_assign<obj>::value));
#define HAS_BIT_RIGHT_SHIFT_ASSIGN(obj) EXPECT_TRUE((opTest::has_operator_bit_right_shift_assign<obj>::value));

#define NO_BIT_AND_ASSIGN(obj)          EXPECT_FALSE((opTest::has_operator_bit_and_assign<obj>::value));
#define NO_BIT_OR_ASSIGN(obj)           EXPECT_FALSE((opTest::has_operator_bit_or_assign<obj>::value));
#define NO_BIT_XOR_ASSIGN(obj)          EXPECT_FALSE((opTest::has_operator_bit_xor_assign<obj>::value));
#define NO_BIT_LEFT_SHIFT_ASSIGN(obj)   EXPECT_FALSE((opTest::has_operator_bit_left_shift_assign<obj>::value));
#define NO_BIT_RIGHT_SHIFT_ASSIGN(obj)  EXPECT_FALSE((opTest::has_operator_bit_right_shift_assign<obj>::value));

// comparisons
#define HAS_COMPARISON(obj)             EXPECT_TRUE((opTest::has_operator_equal<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_not_equal<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_less<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_greater<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_less_equal<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_greater_equal<obj>::value));

#define NO_COMPARISON(obj)              EXPECT_FALSE((opTest::has_operator_equal<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_not_equal<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_less<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_greater<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_less_equal<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_greater_equal<obj>::value));

#define HAS_EQUALITY(obj)               EXPECT_TRUE((opTest::has_operator_equal<obj>::value));
#define HAS_NOT_EQUAL(obj)              EXPECT_TRUE((opTest::has_operator_not_equal<obj>::value));
#define HAS_LESS(obj)                   EXPECT_TRUE((opTest::has_operator_less<obj>::value));
#define HAS_GREATER(obj)                EXPECT_TRUE((opTest::has_operator_greater<obj>::value));
#define HAS_LESS_EQUAL(obj)             EXPECT_TRUE((opTest::has_operator_less_equal<obj>::value));
#define HAS_GREATER_EQUAL(obj)          EXPECT_TRUE((opTest::has_operator_greater_equal<obj>::value));

#define NO_EQUALITY(obj)                EXPECT_FALSE((opTest::has_operator_equal<obj>::value));
#define NO_NOT_EQUAL(obj)               EXPECT_FALSE((opTest::has_operator_not_equal<obj>::value));
#define NO_LESS(obj)                    EXPECT_FALSE((opTest::has_operator_less<obj>::value));
#define NO_GREATER(obj)                 EXPECT_FALSE((opTest::has_operator_greater<obj>::value));
#define NO_LESS_EQUAL(obj)              EXPECT_FALSE((opTest::has_operator_less_equal<obj>::value));
#define NO_GREATER_EQUAL(obj)           EXPECT_FALSE((opTest::has_operator_greater_equal<obj>::value));

// logical
#define HAS_LOGICAL(obj)                EXPECT_TRUE((opTest::has_operator_logical_and<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_logical_or<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_logical_not<obj>::value));

#define NO_LOGICAL(obj)                 EXPECT_FALSE((opTest::has_operator_logical_and<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_logical_or<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_logical_not<obj>::value));

#define HAS_LOGICAL_AND(obj)            EXPECT_TRUE((opTest::has_operator_logical_and<obj>::value));
#define HAS_LOGICAL_OR(obj)             EXPECT_TRUE((opTest::has_operator_logical_or<obj>::value));
#define HAS_LOGICAL_NOT(obj)            EXPECT_TRUE((opTest::has_operator_logical_not<obj>::value));

#define NO_LOGICAL_AND(obj)             EXPECT_FALSE((opTest::has_operator_logical_and<obj>::value));
#define NO_LOGICAL_OR(obj)              EXPECT_FALSE((opTest::has_operator_logical_or<obj>::value));
#define NO_LOGICAL_NOT(obj)             EXPECT_FALSE((opTest::has_operator_logical_not<obj>::value));

// bitwise
#define HAS_BIT_OPS(obj)                EXPECT_TRUE((opTest::has_operator_bit_and<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_or<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_not<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_xor<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_left_shift<obj>::value)); \
                                        EXPECT_TRUE((opTest::has_operator_bit_right_shift<obj>::value));

#define NO_BIT_OPS(obj)                 EXPECT_FALSE((opTest::has_operator_bit_and<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_or<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_not<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_xor<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_left_shift<obj>::value)); \
                                        EXPECT_FALSE((opTest::has_operator_bit_right_shift<obj>::value));

#define HAS_BIT_AND(obj)                EXPECT_TRUE((opTest::has_operator_bit_and<obj>::value));
#define HAS_BIT_OR(obj)                 EXPECT_TRUE((opTest::has_operator_bit_or<obj>::value));
#define HAS_BIT_NOT(obj)                EXPECT_TRUE((opTest::has_operator_bit_not<obj>::value));
#define HAS_BIT_XOR(obj)                EXPECT_TRUE((opTest::has_operator_bit_xor<obj>::value));
#define HAS_BIT_LEFT_SHIFT(obj)         EXPECT_TRUE((opTest::has_operator_bit_left_shift<obj>::value));
#define HAS_BIT_RIGHT_SHIFT(obj)        EXPECT_TRUE((opTest::has_operator_bit_right_shift<obj>::value));

#define NO_BIT_AND(obj)                 EXPECT_FALSE((opTest::has_operator_bit_and<obj>::value));
#define NO_BIT_OR(obj)                  EXPECT_FALSE((opTest::has_operator_bit_or<obj>::value));
#define NO_BIT_NOT(obj)                 EXPECT_FALSE((opTest::has_operator_bit_not<obj>::value));
#define NO_BIT_XOR(obj)                 EXPECT_FALSE((opTest::has_operator_bit_xor<obj>::value));
#define NO_BIT_LEFT_SHIFT(obj)          EXPECT_FALSE((opTest::has_operator_bit_left_shift<obj>::value));
#define NO_BIT_RIGHT_SHIFT(obj)         EXPECT_FALSE((opTest::has_operator_bit_right_shift<obj>::value));

template<typename T>
bool is_nan( const T &value )
{
	// yes this is true, but there is a test available in std.
	// std::isnan()
    // True if NAN
    return value != value;
}

template<typename T>
void ASSERT_NAN(T value)
{
    ASSERT_TRUE(is_nan<T>(value));
}

#endif // ASSERTHELPERS_H
