#include <stdint.h>
#include "softfloat.h"

#ifdef __cplusplus
extern "C" {
#endif

uint32_t sf_f32_add(uint32_t a, uint32_t b) {
    float32_t fa;
    float32_t fb;
    float32_t fy;

    fa.v = a;
    fb.v = b;
    fy = f32_add(fa, fb);
    return fy.v;
}

uint32_t sf_f32_sub(uint32_t a, uint32_t b) {
    float32_t fa;
    float32_t fb;
    float32_t fy;

    fa.v = a;
    fb.v = b;
    fy = f32_sub(fa, fb);
    return fy.v;
}

uint32_t sf_f32_mul(uint32_t a, uint32_t b) {
    float32_t fa;
    float32_t fb;
    float32_t fy;

    fa.v = a;
    fb.v = b;
    fy = f32_mul(fa, fb);
    return fy.v;
}

#ifdef __cplusplus
}
#endif
