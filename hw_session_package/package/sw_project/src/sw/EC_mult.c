#include "EC_mult.h"
#include "EC_add_HW_ASM.h"
#include <string.h>

/* Optimized EC_mult 
   - Uses __builtin_clz for O(1) bit detection
   - Uses "Warm Start" to skip identity operations
   - Uses bitmasks to avoid repetitive shifting
   - Caches memory values in registers
*/
void EC_mult(EC_point_t *P, uint32_t s[32], EC_point_t *R) {
    int32_t i;
    uint32_t word;
    int32_t start_bit;

    // ---------------------------------------------------------
    // STEP 1: Fast Scan (Find the MSB)
    // ---------------------------------------------------------
    
    // Find the first non-zero word (scanning high to low)
    for (i = 28; i >= 20; i--) {
        if (s[i] != 0) break;
    }

    // Edge Case: If scalar is 0 (point at infinity)
    if (i < 20) {
        // Only memset if strictly necessary (rare case)
        memset(R, 0, sizeof(EC_point_t)); 
        R->Y[20] = (1 << 3); 
        return;
    }

    // Use Hardware CLZ to find the exact bit index instantly
    // __builtin_clz returns number of leading zeros (0..31)
    word = s[i];
    start_bit = 31 - __builtin_clz(word);

    int32_t current_bit = start_bit;

    // Initialize R to infinity
    memset(R, 0, sizeof(EC_point_t)); 
    R->Y[20] = (1 << 3);

    // ---------------------------------------------------------
    // STEP 2: Optimized Dispatch Loop
    // ---------------------------------------------------------

    // PHASE A: Finish the remaining bits of the first word
    if (current_bit >= 0) {
        // Create a mask starting just below the MSB
        uint32_t mask = (1 << current_bit);
        
        while (mask) {
            EC_add_HW_ASM(R, R, R); // Always Double
            
            if (word & mask) {      // Bitwise check (fast)
                EC_add_HW_ASM(R, P, R);
            }
            mask >>= 1;             // Shift mask instead of recalculating index
        }
    }

    // PHASE B: Process all subsequent words (full 32 bits)
    for (i--; i >= 21; i--) {
        word = s[i];                // Cache s[i] in a register
        uint32_t mask = 0x80000000; // Start at bit 31
        
        while (mask) {
            EC_add_HW_ASM(R, R, R); // Double
            
            if (word & mask) {
                EC_add_HW_ASM(R, P, R); // Add
            }
            
            mask >>= 1;             // Simple logical shift
        }
    }

    // PHASE C: Process the last word (only 29 bits)
    word = s[20];
    uint32_t mask = 0x80000000; // Start at bit 31
    int bits_to_process = 29;   // Only 29 bits in the last word (0..28)

    while (bits_to_process > 0) {
        EC_add_HW_ASM(R, R, R); // Double
        
        if (word & mask) {
            EC_add_HW_ASM(R, P, R); // Add
        }
        
        mask >>= 1;             // Simple logical shift
        bits_to_process--;
    }
}