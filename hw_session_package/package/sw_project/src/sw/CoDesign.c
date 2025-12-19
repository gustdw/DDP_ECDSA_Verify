#include <stdalign.h>
#include <stdint.h>
#include <string.h>
#include "xil_cache.h"
#include "ecdsa_types.h"
  
#define ISFLAGSET(REG,BIT) ( (REG & (1<<BIT)) ? 1 : 0 )

#define IDLE 0x00
#define MONTGOMERY_START 0x01
#define EC_ADD_START  0x02
#define EC_MULT_START 0x03

void print_array_contents(const char* name, const uint32_t* src) {
  int i;
  xil_printf("--- %s ---\n\r", name);
  for (i=0; i<32; i++) {
    xil_printf("%08x ", src[i]);
    if ( (i+1) % 4 == 0 ) xil_printf("\n\r");
  }
  xil_printf("\n\r");
}

void montMul_HW(const uint32_t *a, const uint32_t *b, uint32_t *res) {
  volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;

  // Hardware Register Mapping (matches ecdsa.v)
  #define COMMAND         0 // rin0
  #define ADDR_TABLE_BASE_I 1 // rin1
  #define ARGC_I            2 // rin2
  #define ADDR_TABLE_BASE_O 3 // rin3
  #define ARGC_O            4 // rin4

  #define STATUS          0 // rout0

  alignas(128) uint32_t addr_table_i[32];
  alignas(128) uint32_t addr_table_o[32];

  // The hardware reads from these buffers via DMA. Flush cache to ensure
  // it gets the latest data from CPU.
  Xil_DCacheFlushRange((UINTPTR)a, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)b, 32 * sizeof(uint32_t));

  // Populate the address table with the *base addresses* of the operand arrays.
  addr_table_i[27] = (uint32_t)a;
  addr_table_i[26] = (uint32_t)b;

  addr_table_o[29] = (uint32_t)res;

  // Flush the address table itself so the hardware can read it via DMA.
  Xil_DCacheFlushRange((UINTPTR)addr_table_i, sizeof(addr_table_i));
  Xil_DCacheFlushRange((UINTPTR)addr_table_o, sizeof(addr_table_o));
  
  // The hardware will write to the 'res' buffer. We must invalidate it before
  // the operation to discard any stale cache lines.
  Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));

  // --- Send commands to Hardware ---
  HWreg[ADDR_TABLE_BASE_I] = (uint32_t)addr_table_i;
  HWreg[ARGC_I] = 2;
  HWreg[ADDR_TABLE_BASE_O] = (uint32_t)addr_table_o;
  HWreg[ARGC_O] = 1;

  HWreg[COMMAND] = MONTGOMERY_START; // Start operation

  // Wait until FPGA is done
  while(!(HWreg[STATUS] & 1));

  HWreg[COMMAND] = IDLE;

  // The hardware wrote to 'res', so invalidate the cache again to make sure
  // the CPU reads the new data from DRAM.
  Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));
}

void EC_add_HW(EC_point_t *P, EC_point_t *Q, EC_point_t *R) {
  volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;

  // Hardware Register Mapping (matches ecdsa.v)
  #define COMMAND         0 // rin0
  #define ADDR_TABLE_BASE_I 1 // rin1
  #define ARGC_I            2 // rin2
  #define ADDR_TABLE_BASE_O  3 // rin3
  #define ARGC_O            4 // rin4

  #define STATUS          0 // rout0

  alignas(128) uint32_t addr_table_i[32];
  alignas(128) uint32_t addr_table_o[32];

  // The hardware reads from these buffers via DMA. Flush cache to ensure
  // it gets the latest data from CPU.
  Xil_DCacheFlushRange((UINTPTR)P->X, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)P->Y, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)P->Z, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)Q->X, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)Q->Y, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)Q->Z, 32 * sizeof(uint32_t));

  // Populate the address table with the *base addresses* of the operand arrays.
  addr_table_i[31] = (uint32_t)P->X;
  addr_table_i[30] = (uint32_t)P->Y;
  addr_table_i[29] = (uint32_t)P->Z;
  addr_table_i[28] = (uint32_t)Q->X;
  addr_table_i[27] = (uint32_t)Q->Y;
  addr_table_i[26] = (uint32_t)Q->Z;

  addr_table_o[31] = (uint32_t)R->Z;
  addr_table_o[30] = (uint32_t)R->Y;
  addr_table_o[29] = (uint32_t)R->X;

  // Flush the address table itself so the hardware can read it via DMA.
  Xil_DCacheFlushRange((UINTPTR)addr_table_i, sizeof(addr_table_i));
  Xil_DCacheFlushRange((UINTPTR)addr_table_o, sizeof(addr_table_o));
  
  // The hardware will write to the 'res' buffer. We must invalidate it before
  // the operation to discard any stale cache lines.
  Xil_DCacheInvalidateRange((UINTPTR)R->X, 32 * sizeof(uint32_t));
  Xil_DCacheInvalidateRange((UINTPTR)R->Y, 32 * sizeof(uint32_t));
  Xil_DCacheInvalidateRange((UINTPTR)R->Z, 32 * sizeof(uint32_t));

  // --- Send commands to Hardware ---
  HWreg[ADDR_TABLE_BASE_I] = (uint32_t)addr_table_i;
  HWreg[ARGC_I] = 6;
  HWreg[ADDR_TABLE_BASE_O] = (uint32_t)addr_table_o;
  HWreg[ARGC_O] = 3;
  HWreg[COMMAND] = EC_ADD_START; // Start operation

  // Wait until FPGA is done
  while(!(HWreg[STATUS] & 1));

  HWreg[COMMAND] = IDLE;

  // The hardware wrote to 'res', so invalidate the cache again to make sure
  // the CPU reads the new data from DRAM.
  Xil_DCacheInvalidateRange((UINTPTR)R->X, 32 * sizeof(uint32_t));
  Xil_DCacheInvalidateRange((UINTPTR)R->Y, 32 * sizeof(uint32_t));
  Xil_DCacheInvalidateRange((UINTPTR)R->Z, 32 * sizeof(uint32_t));
}