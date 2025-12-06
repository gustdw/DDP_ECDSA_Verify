#include "EC_mult.h"
#include "EC_add_HW_ASM.h"
#include <string.h>

#define ISBITSET(WORD,BIT) ( (WORD & (1<<BIT)) ? 1 : 0 )

void EC_mult(EC_point_t *P, uint32_t s[32], EC_point_t *R) {
    memset(R, 0, sizeof(EC_point_t));
    R->Y[20] = (1 << 3); // Set R = point at infinity in projective coords

    // How far off a perfect shift is <<643 when working with 32-bit words?
    // 643 = 20*32 + 3, so it's off by 3 bits. This means that 3 of the 256 bits are in word 28
    // all other bits are in words 20 - 27

    uint8_t first_word_index, first_bit_index;

    // First, we need to determine at what index the first '1' bit occurs in s (shortcut to not have to calculate log2(s))
    for (int32_t i = 28; i >= 20; i--) {
        if (s[i] != 0) {
            for (int32_t j = 31; j >= 0; j--) {
                if (ISBITSET(s[i], j)) {
                    // Found the highest set bit at index (i*32 + j)
                    // We can start processing from the next bit
                    first_word_index = i;
                    first_bit_index = j;
                    goto highest_bit_found;
                }
            }
        }
    }

highest_bit_found:
    for (int32_t i = first_word_index; i >= 20; i--) {
        for (int32_t j = (i == first_word_index) ? first_bit_index : 31; j >= 0; j--) {
            EC_add_HW_ASM(R, R, R); // R = R + R
            if (ISBITSET(s[i], j)) {
                EC_add_HW_ASM(R, P, R); // R = R + P
            }
        }
    }
}
