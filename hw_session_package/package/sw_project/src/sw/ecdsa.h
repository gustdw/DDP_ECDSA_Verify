#include "ecdsa_types.h"

uint8_t verify_ecdsa(const uint32_t message[32], const signature_t *signature, const EC_point_t *public_key, const EC_point_t *G, uint32_t K_X_Modn[32]);