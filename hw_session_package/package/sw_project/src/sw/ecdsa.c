#include "ecdsa.h"
#include "EC_mult.h"
#include "EC_add.h"
#include "CoDesign.h"
#include <string.h>
#include <stdlib.h>

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

uint32_t verify_ecdsa(const uint32_t message[32], const signature_t *signature, const EC_point_t *public_key, const EC_point_t *G, uint32_t K_X_Modn[32], const uint32_t modulus[32]) {
    EC_point_t *Q = malloc(sizeof(EC_point_t));
    EC_point_t *L = malloc(sizeof(EC_point_t));
    EC_point_t *C = malloc(sizeof(EC_point_t));
    EC_point_t *C_prime = malloc(sizeof(EC_point_t));
    
    // Check for allocation failures
    if (!Q || !L || !C || !C_prime) {
        if (Q) free(Q);
        if (L) free(L);
        if (C) free(C);
        if (C_prime) free(C_prime);
        return -1;
    }

    EC_mult((EC_point_t*)G, (uint32_t*)message, Q, modulus);
    EC_mult((EC_point_t*)public_key, K_X_Modn, L, modulus);
    EC_add_HW_ASM(Q, L, C, (uint32_t*)modulus);
    EC_mult((EC_point_t*)&signature->K, (uint32_t*)signature->s, C_prime, modulus);

    // Compare C and C_prime
    uint32_t LHS[32];
    uint32_t RHS[32];
    montMul_HW_ASM(C->Z, C_prime->X, modulus, LHS);
    montMul_HW_ASM(C_prime->Z, C->X, modulus, RHS);
    
    uint8_t result = compare_bignum(LHS, RHS, 32);

    // Free the allocated memory before returning
    free(Q);
    free(L);
    free(C);
    free(C_prime);

    return (result == 0); // Return 1 for valid, 0 for invalid
}