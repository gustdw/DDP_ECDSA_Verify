#include <stdalign.h>
#include <stdint.h>
#include <string.h>
#include "xil_cache.h"
  
#define ISFLAGSET(REG,BIT) ( (REG & (1<<BIT)) ? 1 : 0 )

#define IDLE 0x00
#define MONTGOMERY_START 0x01
#define EC_ADD_START  0x02
#define EC_MULT_START 0x03

void print_array_contents(const char* name, const uint32_t* src) {
  int i;
  xil_printf("--- %s ---\n\r", name);
  for (i=31; i>=20; i--) {
    xil_printf("%08x ", src[i]);
    if ( (31-i+1) % 4 == 0 ) xil_printf("\n\r");
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

  alignas(128) uint32_t addr_table[3];

  // The hardware reads from these buffers via DMA. Flush cache to ensure
  // it gets the latest data from CPU.
  Xil_DCacheFlushRange((UINTPTR)a, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)b, 32 * sizeof(uint32_t));
  Xil_DCacheFlushRange((UINTPTR)m, 32 * sizeof(uint32_t));

  // Populate the address table with the *base addresses* of the operand arrays.
  addr_table[0] = (uint32_t)a;
  addr_table[1] = (uint32_t)b;
  addr_table[2] = (uint32_t)m;

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

  // Wait until FPGA is done, with a timeout
  int timeout = 1000000;
  while(!(HWreg[STATUS] & 1) && --timeout);

  HWreg[COMMAND] = IDLE;

  if (timeout == 0) {
      xil_printf("!!! MONTGOMERY TIMEOUT !!!\n\r");
  }

  // The hardware wrote to 'res', so invalidate the cache again to make sure
  // the CPU reads the new data from DRAM.
  Xil_DCacheInvalidateRange((UINTPTR)res, 32 * sizeof(uint32_t));
  
  printf("MONTGOMERY STATUS 0 %08X | Done %d | Idle %d | Error %d \n\r", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
  printf("STATUS: %08X\n\r", (unsigned int)HWreg[STATUS]);
  xil_printf("HW rout1(addr_buff 0): %08X\n\r", (unsigned int)HWreg[1]);
  xil_printf("HW rout2(addr_buff 1): %08X\n\r", (unsigned int)HWreg[2]);
  xil_printf("HW rout3(addr_buff 2): %08X\n\r", (unsigned int)HWreg[3]);
  
  print_array_contents("a", a);
  print_array_contents("b", b);
  print_array_contents("result", res);
}

// int other() {

//   init_platform();
//   init_performance_counters(0);

//   xil_printf("Begin\n\r");

//   // Register file shared with FPGA
//   volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;

//   #define COMMAND 0
//   #define RXADDR  1
//   #define TXADDR  2
//   #define READ_INPUT 3

//   #define STATUS  0
//   #define READ_OUTPUT 1
//   #define DMA_DONE 2

//   // Aligned input and output memory shared with FPGA
//   alignas(128) uint32_t idata[32];
//   alignas(128) uint32_t a[32];
//   alignas(128) uint32_t b[32];
//   alignas(128) uint32_t m[32];
//   alignas(128) uint32_t odata[32];

//   // Initialize odata to all zero's and set a,b,m so only the MSW holds the
//   // small test values (arrays are 32 words; index 31 is the most-significant
//   // word used by the 381-bit values in this project).
//   memset(odata, 0, sizeof(odata));
//   memset(a, 0, sizeof(a));
//   memset(b, 0, sizeof(b));
//   memset(m, 0, sizeof(m));

//   a[20] = 2;
//   b[20] = 3;
//   m[20] = 5;


//   for (int i=0; i<32; i++) {
//     idata[i] = i+1;
//   }

//   HWreg[RXADDR] = (uint32_t)&idata; // store address idata in reg1
//   HWreg[TXADDR] = (uint32_t)&odata; // store address odata in reg2

//   printf("RXADDR %08X\r\n", (unsigned int)HWreg[RXADDR]);
//   printf("TXADDR %08X\r\n", (unsigned int)HWreg[TXADDR]);

//   printf("STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);
//   printf("REG[3] %08X\r\n", (unsigned int)HWreg[3]);
//   printf("REG[4] %08X\r\n", (unsigned int)HWreg[4]);

// START_TIMING
//   HWreg[COMMAND] = 0x01;
//   HWreg[READ_INPUT] = 0b00000001; // Set read_a
//   HWreg[RXADDR] = (uint32_t)&a[20]; // store address a in reg1
//   xil_printf("After setting read_a, READ_OUTPUT %08X\r\n", (unsigned int)HWreg[READ_OUTPUT]);

//   // Wait until a_read is set
//   while((ISFLAGSET(HWreg[STATUS],3)) == 0);
//   // while((HWreg[STATUS] & 0b00001000) == 0);
//   xil_printf("After a_read is set, STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);

//   HWreg[RXADDR] = (uint32_t)&b[20]; // store address b in reg1
//   HWreg[READ_INPUT] = 0b00000010; // Set read_b
//   // Wait until b_read is set
//   while((ISFLAGSET(HWreg[STATUS],4)) == 0);
//   xil_printf("After b_read is set, STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);

//   HWreg[RXADDR] = (uint32_t)&m[20]; // store address m in reg1  
//   HWreg[READ_INPUT] = 0b00000100; // Set read_m
//   // Wait until m_read is set
//   while((ISFLAGSET(HWreg[STATUS],5)) == 0);
//   xil_printf("After m_read is set, STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);

//   // Wait until FPGA is done
//   while((ISFLAGSET(HWreg[STATUS],0)) == 0);
// STOP_TIMING
  
//   HWreg[COMMAND] = 0x00;

//   printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
//   printf("STATUS 1 %08X\r\n", (unsigned int)HWreg[1]);
//   printf("STATUS 2 %08X\r\n", (unsigned int)HWreg[2]);
//   printf("STATUS 3 %08X\r\n", (unsigned int)HWreg[3]);
//   printf("STATUS 4 %08X\r\n", (unsigned int)HWreg[4]);
//   printf("STATUS 5 %08X\r\n", (unsigned int)HWreg[5]);
//   printf("STATUS 6 %08X\r\n", (unsigned int)HWreg[6]);
//   printf("STATUS 7 %08X\r\n", (unsigned int)HWreg[7]);

//   printf("\r\nI_Data:\r\n"); print_array_contents(idata);
//   printf("\r\nA_Data:\r\n"); print_array_contents(a);
//   printf("\r\nB_Data:\r\n"); print_array_contents(b);
//   printf("\r\nM_Data:\r\n"); print_array_contents(m);
//   printf("\r\nO_Data:\r\n"); print_array_contents(odata);


//   cleanup_platform();

//   return 0;
// }
