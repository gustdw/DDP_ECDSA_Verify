#include "ecdsa.h"
#include "EC_mult.h"
#include "EC_add.h"
#include "multCoDesign.h"
#include <string.h>
#include <stdlib.h>

uint32_t verify_ecdsa(const uint32_t message[32], const signature_t *signature, const EC_point_t *public_key, const EC_point_t *G, uint32_t K_X_Modn[32], const uint32_t modulus[32]) {
    // Allocate memory for EC_point_t structs. Using malloc ensures they are
    // on the heap, avoiding stack overflow with large structs.
    EC_point_t *Q = malloc(sizeof(EC_point_t));
    EC_point_t *L = malloc(sizeof(EC_point_t));
    EC_point_t *C = malloc(sizeof(EC_point_t));
    EC_point_t *C_prime = malloc(sizeof(EC_point_t));
    
    // Check for allocation failures
    if (!Q || !L || !C || !C_prime) {
        // Handle allocation failure
        if (Q) free(Q);
        if (L) free(L);
        if (C) free(C);
        if (C_prime) free(C_prime);
        return -1; // Indicate error
    }

    EC_mult((EC_point_t*)G, (uint32_t*)message, Q, modulus);
    EC_mult((EC_point_t*)public_key, K_X_Modn, L, modulus);
    EC_add_HW(Q, L, C, (uint32_t*)modulus);
    EC_mult((EC_point_t*)&signature->K, (uint32_t*)signature->s, C_prime, modulus);

    // Compare C and C_prime
    uint32_t LHS[32];
    uint32_t RHS[32];
    montMul_HW(C->Z, C_prime->X, modulus, LHS);
    montMul_HW(C_prime->Z, C->X, modulus, RHS);
    
    uint8_t result = memcmp(LHS, RHS, 32 * sizeof(uint32_t));

    // Free the allocated memory before returning
    free(Q);
    free(L);
    free(C);
    free(C_prime);

    return (result == 0); // Return 1 for valid, 0 for invalid
}