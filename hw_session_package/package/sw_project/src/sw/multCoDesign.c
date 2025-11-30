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

void montMul_HW(const uint32_t *a, const uint32_t *b, const uint32_t *m, uint32_t *res) {
  volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;

  // Hardware Register Mapping (matches ecdsa.v)
  #define COMMAND         0 // rin0
  #define ADDR_TABLE_BASE 1 // rin1
  #define ARGC            2 // rin2
  #define RES_ADDR        3 // rin3 (dma_tx_address)

  #define STATUS          0 // rout0

  alignas(128) uint32_t addr_table[32];

  // The hardware reads from these buffers via DMA. Flush cache to ensure
  // it gets the latest data from CPU.
  Xil_DCacheFlushRange((UINTPTR)a, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)b, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)m, 32 * sizeof(uint32_t));

  // Populate the address table with the *base addresses* of the operand arrays.
  addr_table[31] = (uint32_t)a;
  addr_table[30] = (uint32_t)b;
  addr_table[29] = (uint32_t)m;

  // Flush the address table itself so the hardware can read it via DMA.
  Xil_DCacheFlushRange((UINTPTR)addr_table, sizeof(addr_table));
  
  // The hardware will write to the 'res' buffer. We must invalidate it before
  // the operation to discard any stale cache lines.
  Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));

  // --- Send commands to Hardware ---
  HWreg[ADDR_TABLE_BASE] = (uint32_t)addr_table;
  HWreg[ARGC] = 3;
  HWreg[RES_ADDR] = (uint32_t)res;

  HWreg[COMMAND] = MONTGOMERY_START; // Start operation

  // Wait until FPGA is done
  while(!(HWreg[STATUS] & 1));

  HWreg[COMMAND] = IDLE;

  // The hardware wrote to 'res', so invalidate the cache again to make sure
  // the CPU reads the new data from DRAM.
  Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));
  
  printf("MONTGOMERY STATUS 0 %08X | Done %d | Idle %d | Error %d \n\r", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
  printf("STATUS: %08X\n\r", (unsigned int)HWreg[STATUS]);
  xil_printf("HW rout1(addr_buff 0): %08X\n\r", (unsigned int)HWreg[1]);
  xil_printf("HW rout2(addr_buff 1): %08X\n\r", (unsigned int)HWreg[2]);
  xil_printf("HW rout3(addr_buff 2): %08X\n\r", (unsigned int)HWreg[3]);
  xil_printf("HW rout4(value_buff 0): %08X\n\r", (unsigned int)HWreg[4]);
  xil_printf("HW rout5(value_buff 1): %08X\n\r", (unsigned int)HWreg[5]);
  xil_printf("HW rout6(value_buff 2): %08X\n\r", (unsigned int)HWreg[6]);
  xil_printf("HW rout7(mont_mult_result): %08X\n\r", (unsigned int)HWreg[7]);
  
  print_array_contents("a", a);
  print_array_contents("b", b);
  print_array_contents("result", res);
  
  xil_printf("&a: 	%08X \n\r", a);
  xil_printf("&b: 	%08X \n\r", b);
  xil_printf("&m: 	%08X \n\r", m);
  xil_printf("&res: 	%08X \n\r", res);
}

// void EC_add_HW(EC_point_t *P, EC_point_t *Q, EC_point_t *R) {
//   volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;

//   // Hardware Register Mapping (matches ecdsa.v)
//   #define COMMAND         0 // rin0
//   #define ADDR_TABLE_BASE 1 // rin1
//   #define ARGC            2 // rin2
//   #define RES_ADDR        3 // rin3 (dma_tx_address)

//   #define STATUS          0 // rout0

//   alignas(128) uint32_t addr_table[32];

//   // The hardware reads from these buffers via DMA. Flush cache to ensure
//   // it gets the latest data from CPU.
//   Xil_DCacheFlushRange((UINTPTR)P->X, 32 * sizeof(uint32_t));
//   Xil_DCacheFlushRange((UINTPTR)P->Y, 32 * sizeof(uint32_t));
//   Xil_DCacheFlushRange((UINTPTR)P->Z, 32 * sizeof(uint32_t));
//   Xil_DCacheFlushRange((UINTPTR)Q->X, 32 * sizeof(uint32_t));
//   Xil_DCacheFlushRange((UINTPTR)Q->Y, 32 * sizeof(uint32_t));
//   Xil_DCacheFlushRange((UINTPTR)Q->Z, 32 * sizeof(uint32_t));

//   // Populate the address table with the *base addresses* of the operand arrays.
//   addr_table[29] = (uint32_t)a;
//   addr_table[30] = (uint32_t)b;
//   addr_table[31] = (uint32_t)m;

//   // Flush the address table itself so the hardware can read it via DMA.
//   Xil_DCacheFlushRange((UINTPTR)addr_table, sizeof(addr_table));
  
//   // The hardware will write to the 'res' buffer. We must invalidate it before
//   // the operation to discard any stale cache lines.
//   Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));

//   // --- Send commands to Hardware ---
//   HWreg[ADDR_TABLE_BASE] = (uint32_t)addr_table;
//   HWreg[ARGC] = 3;
//   HWreg[RES_ADDR] = (uint32_t)res;

//   HWreg[COMMAND] = MONTGOMERY_START; // Start operation

//   // Wait until FPGA is done
//   while(!(HWreg[STATUS] & 1));

//   HWreg[COMMAND] = IDLE;

//   // The hardware wrote to 'res', so invalidate the cache again to make sure
//   // the CPU reads the new data from DRAM.
//   Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));
  
//   printf("MONTGOMERY STATUS 0 %08X | Done %d | Idle %d | Error %d \n\r", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
//   printf("STATUS: %08X\n\r", (unsigned int)HWreg[STATUS]);
//   xil_printf("HW rout1(addr_buff 0): %08X\n\r", (unsigned int)HWreg[1]);
//   xil_printf("HW rout2(addr_buff 1): %08X\n\r", (unsigned int)HWreg[2]);
//   xil_printf("HW rout3(addr_buff 2): %08X\n\r", (unsigned int)HWreg[3]);
//   xil_printf("HW rout4(value_buff 0): %08X\n\r", (unsigned int)HWreg[4]);
//   xil_printf("HW rout5(value_buff 1): %08X\n\r", (unsigned int)HWreg[5]);
//   xil_printf("HW rout6(value_buff 2): %08X\n\r", (unsigned int)HWreg[6]);
//   xil_printf("HW rout7(mont_mult_result): %08X\n\r", (unsigned int)HWreg[7]);
  
//   print_array_contents("a", a);
//   print_array_contents("b", b);
//   print_array_contents("result", res);
  
//   xil_printf("&a: 	%08X \n\r", a);
//   xil_printf("&b: 	%08X \n\r", b);
//   xil_printf("&m: 	%08X \n\r", m);
//   xil_printf("&res: 	%08X \n\r", res);
// }