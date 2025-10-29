/******************************************************************
 * This is the main file for the Software Sessions
 *
 */

#include <stdint.h>
#include <inttypes.h>
#include <string.h>

#include "common.h"

// Uncomment for Session SW1
// extern void warmup();

// Uncomment for Session SW2 onwards
#include "mp_arith.h"
#include "montgomery.h"
#include "asm_func.h"


int main()
{
    init_platform();
    init_performance_counters(1);

    // Hello World template
    //----------------------
    xil_printf("Begin\n\r");

    xil_printf("Hello World!\n\r");

	xil_printf("End\n\r");

    uint32_t size = 32;

    uint32_t a[32]         = { 0xdbb7cf01, 0x893bb05a, 0x081cf6a9, 0xd662b3b8, 0x27f0a7ed, 0xfc802f42, 0xd48946a3, 0xe5c03b49, 0x7e6f2837, 0x6b69efb8, 0xf68b8db3, 0x7327b5e0, 0x26194661, 0x2ac08b73, 0xdb3aa464, 0x009d07c8, 0x0afc7d82, 0x2a30a776, 0x36b71b43, 0xc5da963d, 0x8513bbc9, 0xba37ed96, 0x276857c7, 0xda73e6d5, 0x50e85b3d, 0x87360fa9, 0x6b8d17e5, 0x22d8268e, 0x1d08210e, 0x14aa7141, 0x2b4446da, 0x9a81722d };
    uint32_t b[32]         = { 0x16a76b1f, 0x1a7710cc, 0xf4a35c61, 0xd5c1d270, 0x7d96a773, 0x1b60c8a9, 0x38cfed5f, 0xb8a151cc, 0xf7b49b29, 0xe26f0760, 0x1e76d7c6, 0x6c402f0b, 0x40a530be, 0x3dff1b2f, 0xd76abde9, 0xf01fae7a, 0xb37ba136, 0x16ea845c, 0xd529c587, 0xa2a5bec3, 0x68e857ea, 0x76738dc5, 0x90fd6006, 0xa77a4869, 0x2cf403e5, 0xaf118a0c, 0xba4080e0, 0x54b859cd, 0x937bfe59, 0x837fb500, 0xda66bfd1, 0x8e3dbc92 };
    uint32_t n[32]         = { 0x3e2f45f5, 0x452ad0e8, 0x677fde03, 0x3f8eb8d4, 0x3221ca48, 0xa2ec8644, 0xdcdf4eb5, 0x8684489a, 0x225dbf12, 0x064ab43b, 0x0b1f8357, 0x8d67e83c, 0xf4a4bc7f, 0xd0753167, 0x31b2aacf, 0xc6ee42ce, 0x5c2e04d1, 0xa945c284, 0xbf33a9e5, 0x64d22cd1, 0x8169d97f, 0xb6c4e5a3, 0x1a436c47, 0xc6e438e3, 0xfecea9e2, 0x23b8b961, 0xa4809d2f, 0x8a98bd7d, 0x4dac96c0, 0x7448a711, 0x344a1298, 0xacb9027a };
    uint32_t n_prime[32]   = { 0x114e81a3, 0x55b76f06, 0x7f0c56d8, 0xb70c7e15, 0xaf05827b, 0x24234957, 0xe2954af3, 0x868f173f, 0x375eb157, 0x8c3fbbbc, 0x5b5a8d17, 0xfc286172, 0x58b1a0af, 0x7d158b51, 0x8dc6fa22, 0x77225374, 0x5fbe7944, 0x9aa6f55e, 0xa272ed91, 0xb717f577, 0xd22e08ed, 0x7ac4bbb1, 0x9195f30c, 0x5cc169b8, 0xbbb0cecd, 0x2070ec9c, 0x6aa80649, 0xdad010a1, 0x69a2b7dd, 0x6b42f344, 0x23faad97, 0xdd773fcc };
    uint32_t expected_res[32]       = { 0xae0dda17, 0xe56b7b63, 0xf08ceb34, 0xd357d5c3, 0x1a52b782, 0x2c41466b, 0x9b6adb27, 0xae25a35f, 0x3c751add, 0x084c78a1, 0xacacced5, 0x2cbe6ae4, 0x964da7cd, 0x8d63e860, 0xf6bb434c, 0x20daa53f, 0x96e10261, 0x80638756, 0x97692934, 0x78d9e8ce, 0x8584d534, 0x023007d2, 0xe25920bc, 0x22e4f5f6, 0xa98cc175, 0x7724ce10, 0x006899b0, 0xfcc32320, 0xe18ec375, 0x5fd0bdaf, 0x71369cef, 0x617b2737 };

    uint32_t res[33] = {0};


START_TIMING
    montMulOpt(a, b, n, n_prime, res, size);
    // montMul(a, b, n, n_prime, res, size);
STOP_TIMING

    if (memcmp(res, expected_res, 32*sizeof(uint32_t)) == 0) {
        xil_printf("Montgomery multiplication passed!\n\r");
    } else {
        xil_printf("Montgomery multiplication failed!\n\r");
        xil_printf("Expected: \n\r");
        for (int i = size; i > 0; --i) {
            xil_printf("%08x", expected_res[i-1]);
        }
        xil_printf("\n\r");
        xil_printf("Calculated: \n\r");
        for (int i = size; i > 0; --i) {
            xil_printf("%08x", res[i-1]);
        }
        xil_printf("\n\r");
    }
    xil_printf("\n\r");

    cleanup_platform();

    return 0;
}
