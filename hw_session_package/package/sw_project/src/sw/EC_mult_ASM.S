.global EC_mult_ASM
.func EC_mult_ASM, EC_mult_ASM
.type EC_mult_ASM, %function
EC_mult_ASM:
    push {r4-r12, lr}
    // Inputs:
    // r0: EC_point_t *P
    // r1: uint32_t s[32]
    // r2: EC_point_t *R
    // r3: uint32_t modulus[32]

    mov r4, r0 // P
    mov r5, r1 // s
    mov r6, r2 // R
    mov r7, r3 // modulus
    
    // Initialize R to point at infinity
    bl EC_point_set_infinity_ASM

    // Determine bit length of scalar s
    mov r8, #28 // i = 28
find_first_set_bit:
    ldr r9, [r5, r8, LSL #2] // Load s[r8]



EC_point_set_infinity_ASM:
    push {r4-r12, lr}
    // r0: EC_point_t *R
    // Set R->x and R->z to 0, R->y to 1
    mov r8, r0 // Save R pointer in r8
    mov r0, #0
    mov r1, #0
    mov r2, #0
    mov r3, #0
    mov r4, #0
    mov r5, #0
    mov r6, #0
    mov r7, #0

    // Zero out x coordinate
    stmia r8!, {r0-r7} // Rx = [0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Rx = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Rx = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Rx = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Zero out y coordinate
    stmia r8!, {r0-r7} // Ry = [0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Ry = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Ry = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Ry = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Zero out z coordinate
    stmia r8!, {r0-r7} // Rz = [0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Rz = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Rz = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, any]
    stmia r8!, {r0-r7} // Rz = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0]

    // Set R->infinity = 1
    mov r1, #1
    lsl r1, r1, #3 // Shift to bit 3 for infinity bit
    str r1, [r8, #208]

    pop {r4-r12, lr}
    bx lr

