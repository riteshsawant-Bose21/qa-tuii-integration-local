#pragma once
 
 /*
 * Define the functions that would have been in arm_neon.h so we can compile
 * for other targets.
 * This works with GCC and allows us to test the real code, but still won't
 * work with LCC (LCC crashes when trying to compile this section).
 */

#ifndef __ARM_NEON
typedef struct
{
    float val[2];
} float32x2_t;

typedef struct
{
    float val[4];
} float32x4_t;

/* 2x SIMD operations */
static float32x2_t vld1_f32(const float *src)
{
    float32x2_t result = { src[0], src[1] };
    return result;
}

static float32x2_t vmul_n_f32(float32x2_t a, float b)
{
    float32x2_t result = { a.val[0]*b, a.val[1]*b };
    return result;
}

static float32x2_t vmul_f32(float32x2_t a, float32x2_t b)
{
    float32x2_t result = { a.val[0]*b.val[0], a.val[1]*b.val[1] };
    return result;
}

static float32x2_t vmla_f32(float32x2_t a, float32x2_t b, float32x2_t c)
{
    float32x2_t result = {
        a.val[0]+b.val[0]*c.val[0],
        a.val[1]+b.val[1]*c.val[1] };
    return result;
}

static float32x2_t vdup_n_f32(float x)
{
    float32x2_t result = { x, x };
    return result;
}

static float vget_lane_f32(float32x2_t a, int n)
{
    return a.val[n];
}

static float32x2_t vadd_f32(float32x2_t a, float32x2_t b)
{
    float32x2_t result = { a.val[0]+b.val[0], a.val[1]+b.val[1] };
    return result;
}

static float32x2_t vsub_f32(float32x2_t a, float32x2_t b)
{
    float32x2_t result = { a.val[0]-b.val[0], a.val[1]-b.val[1] };
    return result;
}

static void vst1_f32(float *dst, float32x2_t x)
{
    dst[0] = x.val[0];
    dst[1] = x.val[1];
}

/* 4x SIMD operations */
static float32x4_t vld1q_f32(const float *src)
{
    float32x4_t result = { src[0], src[1], src[2], src[3] };
    return result;
}

static float32x4_t vmlaq_f32(float32x4_t a, float32x4_t b, float32x4_t c)
{
    float32x4_t result = {
        a.val[0]+b.val[0]*c.val[0],
        a.val[1]+b.val[1]*c.val[1],
        a.val[2]+b.val[2]*c.val[2],
        a.val[3]+b.val[3]*c.val[3] };
    return result;
}

static float32x4_t vmulq_f32(float32x4_t a, float32x4_t b)
{
    float32x4_t result = {
        a.val[0]*b.val[0],
        a.val[1]*b.val[1],
        a.val[2]*b.val[2],
        a.val[3]*b.val[3] };
    return result;
}

static float32x4_t vdupq_n_f32(float x)
{
    float32x4_t result = { x, x, x, x };
    return result;
}

static float vgetq_lane_f32(float32x4_t a, int n)
{
    return a.val[n];
}

static float32x4_t vaddq_f32(float32x4_t a, float32x4_t b)
{
    float32x4_t result = {
        a.val[0]+b.val[0],
        a.val[1]+b.val[1],
        a.val[2]+b.val[2],
        a.val[3]+b.val[3] };
    return result;
}

static float32x4_t vsubq_f32(float32x4_t a, float32x4_t b)
{
    float32x4_t result = {
        a.val[0]-b.val[0],
        a.val[1]-b.val[1],
        a.val[2]-b.val[2],
        a.val[3]-b.val[3] };
    return result;
}

static void vst1q_f32(float *dst, float32x4_t x)
{
    dst[0] = x.val[0];
    dst[1] = x.val[1];
    dst[2] = x.val[2];
    dst[3] = x.val[3];
}
#else 
    #include <arm_neon.h>
#endif // ifndef __ARM_NEON

