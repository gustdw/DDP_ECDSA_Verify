/* ------------------------------------------------------------------
   Clean ARM Assembly for EC_add_HW
   ------------------------------------------------------------------ */

.bss
.balign 128
.global addr_table_i
addr_table_i:
    .zero 128

.balign 128
.global addr_table_o
addr_table_o:
    .zero 128

.text
.balign 4
.global EC_add_HW_ASM

/* ------------------------------------------------------------------
   Function: EC_add_HW_ASM
   ------------------------------------------------------------------ */
EC_add_HW_ASM:
    push {r4-r12, lr}
    
    /* Inputs:
       r0: EC_point_t *P
       r1: EC_point_t *Q
       r2: EC_point_t *R
       r3: uint32_t modulus[32]
    */

    /* Prepare input address table */
    ldr r8, =addr_table_i

    str r0, [r8, #124]      /* addr_table_i[31] = &P->X */
    add r0, r0, #128
    str r0, [r8, #120]      /* addr_table_i[30] = &P->Y */
    add r0, r0, #128
    str r0, [r8, #116]      /* addr_table_i[29] = &P->Z */

    str r1, [r8, #112]      /* addr_table_i[28] = &Q->X */
    add r1, r1, #128
    str r1, [r8, #108]      /* addr_table_i[27] = &Q->Y */
    add r1, r1, #128
    str r1, [r8, #104]      /* addr_table_i[26] = &Q->Z */

    /* Prepare output address table */
    ldr r9, =addr_table_o
    
    /* R (r2) -> Table */
    str r2, [r9, #116]      /* addr_table_o[29] = &R->X */
    add r2, r2, #128
    str r2, [r9, #120]      /* addr_table_o[30] = &R->Y */
    add r2, r2, #128
    str r2, [r9, #124]      /* addr_table_o[31] = &R->Z */

    /* Set up CoDesign hardware */
    ldr r4, =0x40400000
    
    str r8, [r4, #0x04]     /* Write input address table address */
    
    mov r5, #6              /* Number of input addresses */
    str r5, [r4, #0x08]
    
    str r9, [r4, #0x0C]     /* Write output address table address */
    
    mov r6, #3              /* Number of output addresses */
    str r6, [r4, #0x10]
    
    mov r7, #0x02           /* EC_ADD_START command */
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