/*
 * montgomery.c
 *
 */

#include "montgomery.h"
#include "asm_func.h"
#include "common.h"
#include <string.h>

#define WORD_SIZE 32

void add(uint32_t *t, uint32_t i, uint32_t C) {
    uint64_t sum = 0;
    uint32_t S;
    while (C!=0) {
        sum = (uint64_t)t[i] + (uint64_t)C;
        S = (uint32_t)sum;
        C = (uint32_t)(sum >> WORD_SIZE);
        t[i] = S;
        i++;
    }
}

void sub_cond(uint32_t *u, uint32_t *n, uint32_t size) {
    uint32_t B = 0;
    uint32_t t[size+1];
    // memset(t, 0, (size+1)*(sizeof(uint32_t)));
    uint32_t sub = 0;
    for (uint32_t i = 0; i<=size; i++) {
        sub = u[i] - n[i] - B;
        if (u[i] >= n[i] + B) {
            B = 0;
        } else {
            B = 1;
        }
        t[i] = sub;
    }
    if (B == 0) {
        memcpy(u, t, (size-1)*sizeof(uint32_t));
    } else {
        return;
    }
}

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// FIPS
void montMul(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size)
{
    uint32_t t[3] = {0};
    uint64_t sum = 0;
    uint32_t C, S;
    for (uint32_t i = 0; i < size; i++) {
        for (uint32_t j = 0; j<i; j++) {
            sum = (uint64_t)t[0] + (uint64_t)a[j] * (uint64_t)b[i-j];
            S = (uint32_t)sum;
            C = (uint32_t)(sum >> WORD_SIZE);
            add(t, 1, C);
            
            sum = (uint64_t)S + (uint64_t)res[j] * (uint64_t)n[i-j];
            S = (uint32_t)sum;
            C = (uint32_t)(sum >> WORD_SIZE);
            t[0] = S;
            add(t, 1, C);
        }
        sum = (uint64_t)t[0] + (uint64_t)a[i] * (uint64_t)b[0];
        S = (uint32_t)sum;
        C = (uint32_t)(sum >> WORD_SIZE);
        add(t, 1, C);
        res[i] = (uint32_t)(S*(*n_prime));
        
        sum = (uint64_t)S + (uint64_t)res[i] * (uint64_t)n[0];
        S = (uint32_t)sum;
        C = (uint32_t)(sum >> WORD_SIZE);

        add(t, 1, C);
        t[0] = t[1];
        t[1] = t[2];
        t[2] = 0;
    }
    for (uint32_t i = size; i<2*size; i++) {
        for (uint32_t j = i-size+1; j<size; j++) {
            sum = (uint64_t)t[0] + (uint64_t)a[j] * (uint64_t)b[i-j];
            S = (uint32_t)sum;
            C = (uint32_t)(sum >> WORD_SIZE);
            add(t, 1, C);

            sum = (uint64_t)S + (uint64_t)res[j] * (uint64_t)n[i-j];
            S = (uint32_t)sum;
            C = (uint32_t)(sum >> WORD_SIZE);
            t[0] = S;
            add(t, 1, C);
        }
        res[i-size] = t[0];
        t[0] = t[1];
        t[1] = t[2];
        t[2] = 0;
    }
    res[size] = t[0];
    sub_cond(res, n, size);
}

// Calculates res = a * b * r^(-1) mod n.
// a, b, n, n_prime represent operands of size elements
// res has (size+1) elements
// Optimised ASM version
void montMulOpt_ARM(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size);

void montMulOpt(uint32_t *a, uint32_t *b, uint32_t *n, uint32_t *n_prime, uint32_t *res, uint32_t size) {
	montMulOpt_ARM(a, b, n, n_prime, res, size);
//    uint32_t t[3] = {0};
//    uint32_t C = 0;
//    uint32_t S = 0;
//    for (uint32_t i = 0; i < size; i++) {
//        for (uint32_t j = 0; j<i; j++) {
//            montgomery_multiply(t, a, b, i, j, &S, &C);
//            add(t, 1, C);
//
//            montgomery_multiply(&S, res, n, i, j, &S, &C);
//            t[0] = S;
//            add(t, 1, C);
//        }
//        montgomery_multiply(t, a, b, i, i, &S, &C);
//
//        xil_printf("Montgomery multiply S: %08x C: %08x\n", S, C);
//
//        add(t, 1, C);
//
//        res[i] = (uint32_t)(S*(*n_prime));
//        montgomery_multiply(&S, res, n, i, i, &S, &C);
//        xil_printf("Second multiply S: %08x C: %08x\n", S, C);
//        add(t, 1, C);
//        t[0] = t[1];
//        t[1] = t[2];
//        t[2] = 0;
//    }
//    for (uint32_t i = size; i<2*size; i++) {
//        for (uint32_t j = i-size+1; j<size; j++) {
//            montgomery_multiply(t, a, b, i, j, &S, &C);
//            xil_printf("Third multiply S: %08x C: %08x\n", S, C);
//            add(t, 1, C);
//
//            montgomery_multiply(&S, res, n, i, j, &S, &C);
//            xil_printf("Fourth multiply S: %08x C: %08x\n", S, C);
//
//            t[0] = S;
//            add(t, 1, C);
//        }
//        res[i-size] = t[0];
//        t[0] = t[1];
//        t[1] = t[2];
//        t[2] = 0;
//    }
//    res[size] = t[0];
//    sub_cond(res, n, size);
}
