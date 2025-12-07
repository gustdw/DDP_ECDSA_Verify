#ifndef ECDSA_TYPES_H
#define ECDSA_TYPES_H

#include <stdint.h>
#include <stdalign.h>

typedef struct EC_point {
    alignas(128) uint32_t X[32];
    alignas(128) uint32_t Y[32];
    alignas(128) uint32_t Z[32];
} EC_point_t;

typedef struct signature {
    alignas(128) EC_point_t K;
    alignas(128) uint32_t s[32];
} signature_t;

#endif
