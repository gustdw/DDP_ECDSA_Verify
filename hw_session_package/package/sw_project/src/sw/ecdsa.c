#include "ecdsa.h"
#include "EC_mult.h"
#include "EC_add.h"
#include "CoDesign.h"
#include <string.h>
#include <stdlib.h>
#include <stdalign.h>

// Helper to compare two 1024-bit (32 * 32-bit) arrays
// Returns 1 if equal, 0 if different
uint8_t compare_bignum(uint32_t *a, uint32_t *b, size_t length) {
    for (int i = 0; i < length; i++) {
        if (a[i] != b[i]) {
            printf("ERROR: Mismatch at word %d\n", i);
            printf("  Expected: 0x%08X\n", a[i]);
            printf("  Actual:   0x%08X\n", b[i]);
            return 0; // Fail
        }
    }
    return 1; // Pass
}

uint8_t verify_ecdsa(const uint32_t message[32], const signature_t *signature, const EC_point_t *public_key, const EC_point_t *G, uint32_t K_X_Modn[32]) {
    alignas(128) EC_point_t Q;
    alignas(128) EC_point_t L;
    alignas(128) EC_point_t C;
    alignas(128) EC_point_t C_prime;

    EC_mult((EC_point_t*)G, (uint32_t*)message, (EC_point_t*)&Q);

    EC_mult((EC_point_t*)public_key, (uint32_t*)K_X_Modn, (EC_point_t*)&L);
    EC_add_HW_ASM(&Q, &L, &C);
    EC_mult((EC_point_t*)&signature->K, (uint32_t*)signature->s, (EC_point_t*)&C_prime);

    // Compare C and C_prime
    alignas(128) uint32_t LHS[32];
    alignas(128) uint32_t RHS[32];
    montMul_HW_ASM((uint32_t*)C.Z, (uint32_t*)C_prime.X, (uint32_t*)LHS);
    montMul_HW_ASM((uint32_t*)C_prime.Z, (uint32_t*)C.X, (uint32_t*)RHS);
    
    uint8_t result = compare_bignum(LHS, RHS, 32);

    return (result == 1); // Return 1 for valid, 0 for invalid
}
