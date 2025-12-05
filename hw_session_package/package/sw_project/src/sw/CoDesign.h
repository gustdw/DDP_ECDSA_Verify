#include <stdint.h>
void print_array_contents(const char* name, const uint32_t* src);

void montMul_HW(const uint32_t *a, const uint32_t *b, const uint32_t *m, uint32_t *res);
void EC_add_HW(EC_point_t *P, EC_point_t *Q, EC_point_t *R, uint32_t *M);