//#include "common.h"
//#include <stdalign.h>
//
//// These variables are defined in the testvector.c
//// that is created by the testvector generator python script
//extern uint32_t modulus[32],
//                message[32],
//                K_X[32],
//                K_Y[32],
//                K_Z[32],
//                Public_X[32],
//                Public_Y[32],
//                Public_Z[32],
//                s[32],
//				G_X[32],
//                G_Y[32],
//                G_Z[32],
//                K_X_Modn[32],
//				C_X[32],
//				C_Y[32],
//				C_Z[32],
//				C_Prime_X[32],
//				C_Prime_Y[32],
//				C_Prime_Z[32],
//				R_381[32],
//				R2_381[32];
//
//#define ISFLAGSET(REG,BIT) ( (REG & (1<<BIT)) ? 1 : 0 )
//
//void print_array_contents(uint32_t* src) {
//  int i;
//  for (i=32-4; i>=20; i-=4)
//    xil_printf("%08x %08x %08x %08x\n\r",
//      src[i+3], src[i+2], src[i+1], src[i]);
//}
//
//int main() {
//
//  init_platform();
//  init_performance_counters(0);
//
//  xil_printf("Begin\n\r");
//
//  // Register file shared with FPGA
//  volatile uint32_t* HWreg = (volatile uint32_t*)0x40400000;
//
//  #define COMMAND 0
//  #define RXADDR  1
//  #define TXADDR  2
//  #define READ_INPUT 3
//
//  #define STATUS  0
//  #define READ_OUTPUT 1
//  #define DMA_DONE 2
//
//  // Aligned input and output memory shared with FPGA
//  alignas(128) uint32_t idata[32];
//  alignas(128) uint32_t a[32];
//  alignas(128) uint32_t b[32];
//  alignas(128) uint32_t m[32];
//  alignas(128) uint32_t odata[32];
//
//  // Initialize odata to all zero's and set a,b,m so only the MSW holds the
//  // small test values (arrays are 32 words; index 31 is the most-significant
//  // word used by the 381-bit values in this project).
//  memset(odata, 0, sizeof(odata));
//  memset(a, 0, sizeof(a));
//  memset(b, 0, sizeof(b));
//  memset(m, 0, sizeof(m));
//
//  a[20] = 2;
//  b[20] = 3;
//  m[20] = 5;
//
//
//  for (int i=0; i<32; i++) {
//    idata[i] = i+1;
//  }
//
//  HWreg[RXADDR] = (uint32_t)&idata; // store address idata in reg1
//  HWreg[TXADDR] = (uint32_t)&odata; // store address odata in reg2
//
//  printf("RXADDR %08X\r\n", (unsigned int)HWreg[RXADDR]);
//  printf("TXADDR %08X\r\n", (unsigned int)HWreg[TXADDR]);
//
//  printf("STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);
//  printf("REG[3] %08X\r\n", (unsigned int)HWreg[3]);
//  printf("REG[4] %08X\r\n", (unsigned int)HWreg[4]);
//
//START_TIMING
//  HWreg[COMMAND] = 0x01;
//  HWreg[READ_INPUT] = 0b00000001; // Set read_a
//  HWreg[RXADDR] = (uint32_t)&a[20]; // store address a in reg1
//  xil_printf("After setting read_a, READ_OUTPUT %08X\r\n", (unsigned int)HWreg[READ_OUTPUT]);
//
//  // Wait until a_read is set
//  while((ISFLAGSET(HWreg[STATUS],3)) == 0);
//  // while((HWreg[STATUS] & 0b00001000) == 0);
//  xil_printf("After a_read is set, STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);
//
//  HWreg[RXADDR] = (uint32_t)&b[20]; // store address b in reg1
//  HWreg[READ_INPUT] = 0b00000010; // Set read_b
//  // Wait until b_read is set
//  while((ISFLAGSET(HWreg[STATUS],4)) == 0);
//  xil_printf("After b_read is set, STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);
//
//  HWreg[RXADDR] = (uint32_t)&m[20]; // store address m in reg1
//  HWreg[READ_INPUT] = 0b00000100; // Set read_m
//  // Wait until m_read is set
//  while((ISFLAGSET(HWreg[STATUS],5)) == 0);
//  xil_printf("After m_read is set, STATUS %08X\r\n", (unsigned int)HWreg[STATUS]);
//
//  // Wait until FPGA is done
//  while((ISFLAGSET(HWreg[STATUS],0)) == 0);
//STOP_TIMING
//
//  HWreg[COMMAND] = 0x00;
//
//  printf("STATUS 0 %08X | Done %d | Idle %d | Error %d \r\n", (unsigned int)HWreg[STATUS], ISFLAGSET(HWreg[STATUS],0), ISFLAGSET(HWreg[STATUS],1), ISFLAGSET(HWreg[STATUS],2));
//  printf("STATUS 1 %08X\r\n", (unsigned int)HWreg[1]);
//  printf("STATUS 2 %08X\r\n", (unsigned int)HWreg[2]);
//  printf("STATUS 3 %08X\r\n", (unsigned int)HWreg[3]);
//  printf("STATUS 4 %08X\r\n", (unsigned int)HWreg[4]);
//  printf("STATUS 5 %08X\r\n", (unsigned int)HWreg[5]);
//  printf("STATUS 6 %08X\r\n", (unsigned int)HWreg[6]);
//  printf("STATUS 7 %08X\r\n", (unsigned int)HWreg[7]);
//
//  printf("\r\nI_Data:\r\n"); print_array_contents(idata);
//  printf("\r\nA_Data:\r\n"); print_array_contents(a);
//  printf("\r\nB_Data:\r\n"); print_array_contents(b);
//  printf("\r\nM_Data:\r\n"); print_array_contents(m);
//  printf("\r\nO_Data:\r\n"); print_array_contents(odata);
//
//
//  cleanup_platform();
//
//  return 0;
//}
