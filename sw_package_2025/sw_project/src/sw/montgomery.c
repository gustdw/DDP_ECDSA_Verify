/*
 * montgomery.c
 *
 */

#include "montgomery.h"

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
void montMul(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size)
{

}

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// Optimised ASM version
void montMulOpt(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size)
{

}
