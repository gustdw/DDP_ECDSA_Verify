#ifndef EC_ADD_HW_ASM_H_
#define EC_ADD_HW_ASM_H_

#include <stdint.h>
#include "ecdsa_types.h"

void EC_add_HW_ASM(EC_point_t *P, EC_point_t *Q, EC_point_t *R, uint32_t *M);


#endif /* EC_ADD_HW_ASM_H_ */