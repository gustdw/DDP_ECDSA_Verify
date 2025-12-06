/* ------------------------------------------------------------------
   Clean ARM Assembly for montMul_HW
   ------------------------------------------------------------------ */

.bss
.balign 128
.global mont_addr_i
mont_addr_i:
    .zero 128

.balign 128
.global mont_addr_o
mont_addr_o:
    .zero 128

.text
.balign 4
.global montMul_HW_ASM

/* ------------------------------------------------------------------
   Function: montMul_HW_ASM
   ------------------------------------------------------------------ */
montMul_HW_ASM:
    push {r4-r12, lr}

    /* Inputs:
       r0: uint32_t *a
       r1: uint32_t *b
       r2: uint32_t *m
       r3: uint32_t *res
    */

    /* Prepare input address table */
    ldr r8, =mont_addr_i
    
    str r0, [r8, #124]      /* mont_addr_i[31] = &a */
    str r1, [r8, #120]      /* mont_addr_i[30] = &b */
    str r2, [r8, #116]      /* mont_addr_i[29] = &m */

    /* Prepare output address table */
    ldr r9, =mont_addr_o
    str r3, [r9, #124]      /* mont_addr_o[31] = &R->X (result) */

    /* Set up CoDesign hardware */
    ldr r4, =0x40400000
    
    str r8, [r4, #0x04]     /* Write input address table address */
    
    mov r5, #3              /* Number of input addresses */
    str r5, [r4, #0x08]
    
    str r9, [r4, #0x0C]     /* Write output address table address */
    
    mov r6, #1              /* Number of output addresses */
    str r6, [r4, #0x10]
    
    mov r7, #0x01           /* Command: START */
    str r7, [r4, #0x00]

    /* Wait for operation to complete */
wait_loop:
    ldr r3, [r4, #0x00]
    and r5, r3, #0x1        /* Check STATUS bit 0 */
    cmp r5, #0
    beq wait_loop

    mov r3, #0x00           /* IDLE command / Clear Interrupt */
    str r3, [r4, #0x00]
    
    pop {r4-r12, lr}
    bx lr