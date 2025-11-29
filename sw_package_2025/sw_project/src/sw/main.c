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

    cleanup_platform();

    return 0;
}
