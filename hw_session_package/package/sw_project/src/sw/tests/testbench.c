#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdalign.h>

#include "xil_printf.h"
#include "../ecdsa_types.h"
#include "../ecdsa.h"

// Include the generated test vectors
// Ensure testvector_multi.c is in the same directory or include path
#include "testvector_multi.h"

// Helper to copy data from the generated 2D arrays into EC_point_t components
void load_point(EC_point_t *point, uint32_t src_x[32], uint32_t src_y[32], uint32_t src_z[32]) {
    memcpy(point->X, src_x, 32 * sizeof(uint32_t));
    memcpy(point->Y, src_y, 32 * sizeof(uint32_t));
    memcpy(point->Z, src_z, 32 * sizeof(uint32_t));
}

int test_ecdsa_verification_many() {
    xil_printf("Starting Multi-Vector ECDSA Testbench\n\r");
    xil_printf("Total Vectors: %d\n\r", NUM_TEST_VECTORS);

    int passed_count = 0;
    int failed_count = 0;

    // Buffers for Hardware Inputs
    alignas(128) EC_point_t PublicKey;
    alignas(128) uint32_t Msg_Hash[32];
    alignas(128) signature_t Signature;

    // Constant: Generator Point G (Loaded once as it is static)
    alignas(128) EC_point_t Gen_Point;
    load_point(&Gen_Point, G_X, G_Y, G_Z);
    for (int i = 0; i < NUM_TEST_VECTORS; i++) {
        xil_printf("Running Vector %d... ", i);

        // ---------------------------------------------------------
        // 1. Load Inputs for this iteration
        // ---------------------------------------------------------
        
        // Load Public Key
        load_point(&PublicKey, Public_X[i], Public_Y[i], Public_Z[i]);

        // Load Message Hash
        memcpy(Msg_Hash, message[i], 32 * sizeof(uint32_t));

        // Load Signature s
        memcpy(&Signature.s, s[i], 32 * sizeof(uint32_t));

        // Load K point (if required by your HW interface)
        load_point(&Signature.K, K_X[i], K_Y[i], K_Z[i]);

        // ---------------------------------------------------------
        // 2. CALL HARDWARE FUNCTION
        // ---------------------------------------------------------
        uint8_t result = verify_ecdsa(Msg_Hash, &Signature, &PublicKey, &Gen_Point, K_X_Modn[i]);

        // ---------------------------------------------------------
        // 3. Verify Results
        // ---------------------------------------------------------
        if (result) {
            xil_printf("PASSED Test %d/%d\n\r", i, NUM_TEST_VECTORS);
            passed_count++;
        } else {
            xil_printf("FAILED Test %d/%d\n\r", i, NUM_TEST_VECTORS);
            failed_count++;
        }
    }

    xil_printf("\n\rTest Summary:\n\r");
    xil_printf("Passed: %d\n\r", passed_count);
    xil_printf("Failed: %d\n\r", failed_count);

    return 0;
}