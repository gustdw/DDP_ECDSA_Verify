#include "common.h"
#include <stdalign.h>
#include "multCoDesign.h"
  

#define ISFLAGSET(REG,BIT) ( (REG & (1<<BIT)) ? 1 : 0 )

int main() {

  init_platform();
  init_performance_counters(0);

  xil_printf("Begin\n\r");

  alignas(128) uint32_t a[32];
  alignas(128) uint32_t b[32];
  alignas(128) uint32_t m[32];
  alignas(128) uint32_t res[32];

  memset(a, 0, sizeof(a));
  memset(b, 0, sizeof(b));
  memset(m, 0, sizeof(m));
  memset(res, 0, sizeof(res));

  a[31] = 2;
  b[31] = 3;
  m[31] = 5;

  montMul_HW(a, b, m, res);


  cleanup_platform();

  return 0;
}
