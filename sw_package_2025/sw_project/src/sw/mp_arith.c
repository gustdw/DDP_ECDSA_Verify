/*
 * mp_arith.c
 *
 */

#include <stdint.h>
#include <string.h>


// Calculates res = a + b.
// a and b represent large integers stored in uint32_t arrays
// a and b are arrays of size elements, res has size+1 elements
void mp_add(uint32_t *a, uint32_t *b, uint32_t *res, uint32_t size)
{
    uint32_t W = 0xFFFFFFFF;
    uint32_t c = 0;
    uint64_t temp;
    for (uint32_t i = 0; i < size; i++) {
        temp = (uint64_t)a[i] + (uint64_t)b[i] + (uint64_t)c;
        if (temp <= W) {
            c = 0;
            res[i] = temp;
        } else {
            c = 1;
            res[i] = temp & W;
        }
    }
    res[size] = c;
}

// Calculates res = a - b.
// a and b represent large integers stored in uint32_t arrays
// a, b and res are arrays of size elements
void mp_sub(uint32_t *a, uint32_t *b, uint32_t *res, uint32_t size)
{
    uint32_t W = 0xFFFFFFFF;
    int32_t c = 0;
    int64_t temp;
    for (uint32_t i = 0; i < size; i++) {
        temp = (int64_t)a[i] - (int64_t)b[i] + (int64_t)c;
        if (temp >= 0) {
            c = 0;
            res[i] = temp;
        } else {
            c = -1;
            res[i] = temp + W + 1;
        }
    }
    res[size] = c;
}

// Calculates res = (a + b) mod N.
// a and b represent operands, N is the modulus. They are large integers stored in uint32_t arrays of size elements
void mod_add(uint32_t *a, uint32_t *b, uint32_t *N, uint32_t *res, uint32_t size)
{
    mp_add(a, b, res, size);
    if (res[size] || memcmp(res, N, size*sizeof(uint32_t)) >= 0) {
        mp_sub(res, N, res, size);
    }
}

// Calculates res = (a - b) mod N.
// a and b represent operands, N is the modulus. They are large integers stored in uint32_t arrays of size elements
void mod_sub(uint32_t *a, uint32_t *b, uint32_t *N, uint32_t *res, uint32_t size)
{   
    if (memcmp(a, b, size*sizeof(uint32_t)) < 0) {  // if a < b
        mp_sub(b, a, res, size);    // res = b - a
        mp_sub(N, res, res, size);  // res = N - (b - a) = a - b mod N
    } else {    // if a >= b
        mp_sub(a, b, res, size);    // res = a - b
    }
}