#ifndef TESTVECTOR_MULTI_H
#define TESTVECTOR_MULTI_H

#include <stdint.h>

// Define the number of vectors (adjust this number to match your C file)
#define NUM_TEST_VECTORS 100

// Declare that these variables exist in another object file
extern uint32_t message[NUM_TEST_VECTORS][32];
extern uint32_t K_X[NUM_TEST_VECTORS][32];
extern uint32_t K_Y[NUM_TEST_VECTORS][32];
extern uint32_t K_Z[NUM_TEST_VECTORS][32];
extern uint32_t s[NUM_TEST_VECTORS][32];
extern uint32_t Public_X[NUM_TEST_VECTORS][32];
extern uint32_t Public_Y[NUM_TEST_VECTORS][32];
extern uint32_t Public_Z[NUM_TEST_VECTORS][32];
extern uint32_t K_X_Modn[NUM_TEST_VECTORS][32];

// Start Point G (Single instance usually)
extern uint32_t G_X[32];
extern uint32_t G_Y[32];
extern uint32_t G_Z[32];

#endif