/* ------------------------------------------------------------------
   Optimized ARM Assembly for EC_add_HW
   ------------------------------------------------------------------ */

.bss
.balign 128
.global addr_table_i
addr_table_i: .zero 128

.balign 128
.global addr_table_o
addr_table_o: .zero 128

.text
.balign 4
.global EC_add_HW_ASM

/* ------------------------------------------------------------------
   Function: EC_add_HW_ASM
   ------------------------------------------------------------------ */
EC_add_HW_ASM:
    push {r4-r12, lr}

    /* -----------------------------------------------------------
       STEP 1: PREPARE OUTPUT TABLE (R)
       Current Args: r0=P, r1=Q, r2=R
       ----------------------------------------------------------- */
    /* We need to store R->Z, R->Y, R->X at addr_table_o[29, 30, 31]
       Offsets: 116, 120, 124.
       We map registers to data:
       r3 = R->Z (High Addr)
       r4 = R->Y
       r5 = R->X (Low Addr)
    */
    ldr     r10, =addr_table_o
    mov     r3, r2            /* R->X */
    add     r4, r2, #128    /* R->Y */
    add     r5, r2, #256    /* R->Z */

    /* TRICK: Store 3 words in one bus transaction to offset 116 */
    add     r12, r10, #116
    stm     r12, {r3-r5}

    /* -----------------------------------------------------------
       STEP 2: PREPARE INPUT TABLE (P and Q)
       We need to fill addr_table_i from index 26 to 31 (contiguous).
       Q->Z, Q->Y, Q->X, P->Z, P->Y, P->X
       ----------------------------------------------------------- */
    ldr     r11, =addr_table_i

    /* Calculate Q pointers (Indices 26, 27, 28) */
    add     r4, r1, #256       /* Q->Z (Reg r4 -> Low Addr) */
    add     r5, r1, #128       /* Q->Y */
    mov     r6, r1             /* Q->X */

    /* Calculate P pointers (Indices 29, 30, 31) */
    add     r7, r0, #256       /* P->Z */
    add     r8, r0, #128      /* P->Y */
    mov     r9, r0            /* P->X (Reg r11 -> High Addr) */

    /* TRICK: STM requires strictly increasing register numbers for 
       increasing addresses. We use r4, r5, r6, r7, r10, r11.
       Note: We skipped r8/r9 as they hold our bases. 
       We must use a subset or move bases. 
       Let's use r12 as base to free up a contiguous block if needed, 
       but STM can skip registers in the list.
       Writing to: base + 104 */
    
    add     r12, r11, #104
    stm     r12, {r4-r9} 

    /* -----------------------------------------------------------
       STEP 3: CONFIGURE HARDWARE
       HW Registers:
       0x04: Input Table Ptr
       0x08: Input Count
       0x0C: Output Table Ptr
       0x10: Output Count
       ----------------------------------------------------------- */
    ldr     r0, =0x40400000    /* HW Base Address */

    /* Prepare values for burst write */
    mov     r1, r11             /* Input Table Addr (r9) */
    mov     r2, #6              /* Input Count */
    mov     r3, r10             /* Output Table Addr (r8) */
    mov     r4, #3              /* Output Count */

    /* TRICK: Write config registers (0x04 - 0x10) in one go */
    add     r12, r0, #0x04
    stm     r12, {r1-r4}

    /* Start Command */
    mov     r1, #0x02
    str     r1, [r0]

    /* -----------------------------------------------------------
       STEP 4: OPTIMIZED WAIT LOOP
       ----------------------------------------------------------- */
wait_loop:
    ldr     r3, [r0]
    tst     r3, #1             /* TRICK: TST is faster/cleaner than AND+CMP */
    beq     wait_loop

    /* Clear Interrupt / IDLE */
    mov     r3, #0x00
    str     r3, [r0]

    pop     {r4-r12, lr}
    bx      lr