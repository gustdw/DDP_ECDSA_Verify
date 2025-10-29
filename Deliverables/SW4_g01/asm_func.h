#ifndef ASM_FUNC_H_
#define ASM_FUNC_H_

#include <stdint.h>

//Copies array a to array b
uint32_t arr_copy(uint32_t *a, uint32_t *b, uint32_t n);

void montMulOpt_ARM(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size);

#endif /* ASM_FUNC_H_ */
