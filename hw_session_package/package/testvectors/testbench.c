#include <stdio.h>
#include <string.h>
#include <stdint.h>
#include <stdalign.h>

// Include your platform specific headers
#include "common.h"
#include "ecdsa_types.h"
#include "ecdsa.h"

// Include the generated test vectors
// Ensure testvector_multi.c is in the same directory or include path
#include "testvector_multi.c" 

// Helper to compare two 1024-bit (32 * 32-bit) arrays
// Returns 1 if equal, 0 if different
int compare_bignum(uint32_t *a, uint32_t *b, const char *name, int vector_idx) {
    for (int i = 0; i < 32; i++) {
        if (a[i] != b[i]) {
            printf("ERROR: Vector %d - Mismatch in %s at word %d\n", vector_idx, name, i);
            printf("  Expected: 0x%08X\n", a[i]);
            printf("  Actual:   0x%08X\n", b[i]);
            return 0; // Fail
        }
    }
    return 1; // Pass
}

// Helper to copy data from the generated 2D arrays into EC_point_t components
void load_point(EC_point_t *point, uint32_t src_x[32], uint32_t src_y[32], uint32_t src_z[32]) {
    memcpy(point->X, src_x, 32 * sizeof(uint32_t));
    memcpy(point->Y, src_y, 32 * sizeof(uint32_t));
    memcpy(point->Z, src_z, 32 * sizeof(uint32_t));
}

int main() {
    init_platform();
    init_performance_counters(0);

    printf("Starting Multi-Vector ECDSA Testbench\n");
    printf("Total Vectors: %d\n", NUM_TEST_VECTORS);

    int passed_count = 0;
    int failed_count = 0;

    // Buffers for Hardware Inputs
    alignas(128) EC_point_t PublicKey;
    alignas(128) EC_point_t Signature_K; // If your HW needs K as a point
    alignas(128) uint32_t Msg_Hash[32];
    alignas(128) uint32_t Signature_s[32];

    // Buffers for Hardware Outputs
    alignas(128) EC_point_t HW_Result_Point; // To store result C
    
    // Constant: Generator Point G (Loaded once as it is static)
    alignas(128) EC_point_t Gen_Point;
    load_point(&Gen_Point, G_X, G_Y, G_Z);

    for (int i = 0; i < NUM_TEST_VECTORS; i++) {
        printf("Running Vector %d... ", i);

        // ---------------------------------------------------------
        // 1. Load Inputs for this iteration
        // ---------------------------------------------------------
        
        // Load Public Key
        load_point(&PublicKey, Public_X[i], Public_Y[i], Public_Z[i]);

        // Load Message Hash
        memcpy(Msg_Hash, message[i], 32 * sizeof(uint32_t));

        // Load Signature s
        memcpy(Signature_s, s[i], 32 * sizeof(uint32_t));

        // Load K point (if required by your HW interface)
        load_point(&Signature_K, K_X[i], K_Y[i], K_Z[i]);

        // Reset Output Buffer
        memset(&HW_Result_Point, 0, sizeof(EC_point_t));

        // ---------------------------------------------------------
        // 2. CALL HARDWARE FUNCTION
        // ---------------------------------------------------------
        // TODO: Replace this with your actual hardware driver call.
        // Example: 
        // ECDSA_Verify_HW(&PublicKey, Msg_Hash, Signature_s, &Signature_K, &HW_Result_Point);
        // 
        // For now, we simulate a pass by copying the EXPECTED result into the HW result variable.
        // REMOVE THESE 3 LINES when you add your real HW call:
        memcpy(HW_Result_Point.X, C_X[i], 32 * sizeof(uint32_t));
        memcpy(HW_Result_Point.Y, C_Y[i], 32 * sizeof(uint32_t));
        memcpy(HW_Result_Point.Z, C_Z[i], 32 * sizeof(uint32_t));
        // ---------------------------------------------------------


        // ---------------------------------------------------------
        // 3. Verify Results
        // ---------------------------------------------------------
        // We compare the Hardware Calculated Point (HW_Result_Point) 
        // against the Expected Point (C_X, C_Y, C_Z) from the python script.

        int check_x = compare_bignum(C_X[i], HW_Result_Point.X, "C.X", i);
        int check_y = compare_bignum(C_Y[i], HW_Result_Point.Y, "C.Y", i);
        int check_z = compare_bignum(C_Z[i], HW_Result_Point.Z, "C.Z", i);

        if (check_x && check_y && check_z) {
            printf("PASSED\n");
            passed_count++;
        } else {
            printf("FAILED\n");
            failed_count++;
        }
    }

    printf("\nTest Summary:\n");
    printf("  Passed: %d\n", passed_count);
    printf("  Failed: %d\n", failed_count);

    cleanup_platform();
    return 0;
}