#ifndef ECDSA_TYPES_H
#define ECDSA_TYPES_H

#include <stdint.h>

typedef struct EC_point {
    uint32_t X[32];
    uint32_t Y[32];
    uint32_t Z[32];
} EC_point_t;

typedef struct signature {
    EC_point_t K;
    uint32_t s[32];
} signature_t;

#endif
