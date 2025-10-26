.text

.global arr_copy
.func arr_copy, arr_copy
.type arr_copy, %function

arr_copy:
cmp r2, #0
beq end_copy
copy_loop:
	ldr r3, [r0], #4
	str r3, [r1], #4
	subs r2, r2, #1
	bne  copy_loop
end_copy:
bx lr
.endfunc

.text

.data
.align 4
t: .word 0, 0, 0

.global montMulOpt_ARM
.func montMulOpt_ARM, montMulOpt_ARM
.type montMulOpt_ARM, %function
montMulOpt_ARM:
	push {r4-r12, lr}		//Preserve registers that will be used in the function
	// r0 = *a
	// r1 = *b
	// r2 = *n
	// r3 = *n_prime
	// r10 = *res
	// r11 = size
	ldr r10, [sp, #72] // load pointer to res
	ldr r11, [sp, #76] // load size

	push {r0-r3}	// Save a, b, n, n_prime
	mov r6, #0	// i = 0
	i_loop1:
		cmp r6, r11	// i >= size
		bge exit_i_loop1
		mov r7, #0	// j = 0
		j_loop1:
			cmp r7, r6
			bge exit_j_loop1

			// montgomery_multiply(t[0], a, b, i, j);
			ldr r1, [sp] // r1 = a
			ldr r2, [sp, #4] // r2 = b
			ldr r0, =t
			ldr r0, [r0] // r0 = t[0]
			mov r3, r6 // r3 = i
			mov r4, r7 // r4 = j
			bl calc_S_C
			mov r8, r0 // r8 = S
			mov r9, r1 // r9 = C
			
			// add(t, 1, C)
			ldr r0, =1 // r0 = i = 1, r1 already C
			bl add_S_C_ARM

			// montgomery_multiply(S, res, n, i, j);
			mov r0, r8 // r0 = S
			mov r1, r10 // r1 = res
			ldr r2, [sp, #8] // r2 = n
			mov r3, r6 // r3 = i
			mov r4, r7 // r4 = j
			bl calc_S_C
			mov r8, r0 // r8 = S
			mov r9, r1 // r9 = C
			
			// t[0] = S
			ldr r0, =t
			str r8, [r0] // t[0] = S

			// add(t, 1, C)
			mov r0, #1 // r0 = i = 1, r1 already C
			bl add_S_C_ARM

			add r7, r7, #1 // j++
			b j_loop1
		exit_j_loop1:

		// montgomery_multiply(t[0], a, b, i, i);
		ldr r0, =t
		ldr r0, [r0] // r0 = t[0]
		ldr r1, [sp] // r1 = a
		ldr r2, [sp, #4] // r2 = b
		mov r3, r6 // r3 = i
		mov r4, r6 // r4 = i
		bl calc_S_C
		mov r8, r0 // r8 = S
		mov r9, r1 // r9 = C

		// add(t, 1, C)
		mov r0, #1 // r0 = i = 1, r1 already C
		bl add_S_C_ARM

		// res[i] = S*(*n_prime)
		ldr r0, [sp, #12] // r0 = n_prime
		ldr r0, [r0] // r0 = *n_prime
		umull r1, r2, r8, r0 // {r2,r1} = S * (*n_prime)
		str r1, [r10, r6, lsl #2] // res[i] = lower 32 bits
		
		// montgomery_multiply(S, res, n, i, i);
		mov r0, r8 // r0 = S
		mov r1, r10 // r1 = res
		ldr r2, [sp, #8] // r2 = n
		mov r3, r6 // r3 = i
		mov r4, r6 // r4 = i
		bl calc_S_C
		mov r8, r0 // r8 = S
		mov r9, r1 // r9 = C

		// add(t, 1, C)
		mov r0, #1 // r0 = i = 1, r1 already C
		bl add_S_C_ARM

		// t[0] = t[1]
		ldr r0, =t	// r0 = address of t (symbol in .data)
		ldr r1, [r0, #4] // r1 = t[1]
		str r1, [r0] // t[0] = t[1]
		// t[1] = t[2]
		ldr r1, [r0, #8] // r1 = t[2]
		str r1, [r0, #4] // t[1] = t[2]
		// t[2] = 0
		mov r2, #0
		str r2, [r0, #8] // t[2] = 0

		add r6, r6, #1 // i++
		b i_loop1
	exit_i_loop1:
	
	i_loop2:
		cmp r6, r11, lsl #1 // i >= size * 2
		bge exit_i_loop2
		sub r7, r6, r11	// j = i - size
		add r7, r7, #1	// j = i - size + 1
		j_loop2:
			cmp r7, r11 // j >= size
			bge exit_j_loop2

			// montgomery_multiply(t[0], a, b, i, j);
			ldr r0, =t
			ldr r0, [r0] // r0 = t[0]
			ldr r1, [sp] // r1 = a
			ldr r2, [sp, #4] // r2 = b
			mov r3, r6 // r3 = i
			mov r4, r7 // r4 = j
			bl calc_S_C
			mov r8, r0 // r8 = S
			mov r9, r1 // r9 = C

			// add(t, 1, C)
			mov r0, #1 // r0 = i = 1, r1 already C
			bl add_S_C_ARM

			// montgomery_multiply(S, res, n, i, j);
			mov r0, r8 // r0 = S
			mov r1, r10 // r1 = res
			ldr r2, [sp, #8] // r2 = n
			mov r3, r6 // r3 = i
			mov r4, r7 // r4 = j
			bl calc_S_C
			mov r8, r0 // r8 = S
			mov r9, r1 // r9 = C

			// t[0] = S
			ldr r0, =t
			str r8, [r0] // t[0] = S

			// add(t, 1, C)
			mov r0, #1 // r0 = i = 1, r1 already C
			bl add_S_C_ARM

			add r7, r7, #1 // j++
			b j_loop2
		exit_j_loop2:

		// res[i - size] = t[0]
		ldr r0, =t
		ldr r1, [r0] // r1 = t[0]
		sub r2, r6, r11 // r2 = i - size
		str r1, [r10, r2, lsl #2] // res[i - size] = t[0]

		// t[0] = t[1]
		ldr r2, [r0, #4] // r2 = t[1]
		str r2, [r0] // t[0] = t[1]
		// t[1] = t[2]
		ldr r1, [r0, #8] // r1 = t[2]
		str r1, [r0, #4] // t[1] = t[2]
		// t[2] = 0
		mov r1, #0
		str r1, [r0, #8] // t[2] = 0

		add r6, r6, #1 // i++
		b i_loop2
	
	exit_i_loop2:
	// res[size] = t[0]
	add r6, r10, r11, lsl #2 // r6 = &res[size]
	str r2, [r6] // res[size] = t[0]

	// sub_cond(res, n, size)
	mov r0, r10 // r0 = res
	ldr r1, [sp, #8] // r1 = n
	mov r2, r11 // r2 = size
	bl sub_cond_ARM

	pop {r0-r3}	// Restore a, b, n, n_prime
	pop {r4-r12, lr}
	bx lr
.endfunc

.func add_S_C_ARM, add_S_C_ARM
add_S_C_ARM:
	// r0 = i
	// r1 = C
	ldr r2, =t

	add_loop_S_C:
		cmp r1, #0
		beq end_add_loop_S_C
		ldr r3, [r2, r0, lsl #2]	//r3 = t[i]
		adds r3, r3, r1		//t[i] = t[i] + C
		mov r1, #0
		adc r1, r1, #0		//Carry
		str r3, [r2, r0, lsl #2]	//Store updated t[i]
		add r0, r0, #1		//i++
		b add_loop_S_C
	end_add_loop_S_C:
	bx lr
.endfunc

.func sub_cond_ARM, sub_cond_ARM
sub_cond_ARM:
	// r0 = u
	// r1 = n
	// r2 = size
	push {r4-r8, lr}
	mov r4, r0 // r4 = u
	mov r5, r1 // r5 = n
	mov r6, r2 // r6 = size

	add r0, r2, #1	// r0 = size + 1
	bl malloc	// Allocate memory for temp array, pointer in r0
	cmp r0, #0
	beq end_sub_cond	// If malloc failed, skip subtraction
	mov r8, r0 // r8 = temp array pointer, t

	mov r1, #0
	add r2, r6, #1	// r2 = size + 1
	lsl r2, r2, #2	// r2 = (size + 1) * 4
	bl memset	// memset(temp array, 0, (size+1)*4)

	mov r7, #0	// i = 0
	sub_cond_loop:
		cmp r7, r6	// i > size
		bgt exit_sub_cond_loop
		ldr r0, [r4, r7, lsl #2]	// r0 =  u[i]
		ldr r1, [r5, r7, lsl #2]	// r1 =  n[i]
		
		// If i == 0 → start fresh with SUBS (sets carry)
		// Else continue with SBCS (uses previous carry)
		cmp r7, #0
		beq first_sub
		bne next_sub

		first_sub:
			subs r2, r0, r1             // r2 = u[i] - n[i]; sets carry
			b store_result

		next_sub:
			sbcs r2, r0, r1             // r2 = u[i] - n[i] - (1 - C); sets carry
		
		store_result:
			str r2, [r8, r7, lsl #2]    // store result in temp array
		
		add r7, r7, #1               // i++
		b sub_cond_loop
	
	exit_sub_cond_loop:
		// If no borrow (C == 1) → copy temp array to u
		// Else do nothing (u already has correct value)
		bcc copy_temp_to_u
		b free_temp
	
	copy_temp_to_u:
		mov r0, r4               // r0 = u pointer
		mov r1, r8               // r1 = temp array pointer
		sub r2, r6, #1			 // r2 = (size - 1)*sizeof(uint32_t)
		lsl r2, r2, #2			 // r2 = (size - 1)*sizeof(uint32_t)
		bl memcpy              // copy temp array to u
	
	free_temp:
		// Free temp array
		mov r0, r8
		bl free
	end_sub_cond:
		pop {r4-r8, lr}
		bx lr
.endfunc

.func calc_S_C, calc_S_C
calc_S_C:
	// r0 = t[0] or S
	// r1 = a or res
	// r2 = b or n
	// r3 = i
	// r4 = j

	push {r4-r6, lr}

	ldr r5, [r1, r4, lsl #2] 	//Load a[j] or res[j] in r5
	sub r4, r3, r4		//Calculate i-j or i-i in r4
	ldr r6, [r2, r4, lsl #2]	//Load b[i-j] or n[i-j] in r6
	umull r5, r6, r5, r6	//{r6,r5} = a[j] * b[i-j] or res[j] * n[i-j]
	adds r0, r0, r5	//S = t[0] + a[j]*b[i-j] or t[0] = S + res[j]*n[i-j]
	adc r1, r6, #0		//Add carry to higher part

	pop {r4-r6, lr}
	bx lr
.endfunc




.text

@USEFUL FUNCTIONS

@ add Rx, Ry, Rz	//Rx = Ry + Rz  second operand can be constant
@ sub Rx, Ry, Rz	//Rx = Ry - Rz second operand can be constant
@ addc Rx, Ry, Rz	//Rx = Ry + Rz + CARRY   one operand can be constant
@ cmp Rx, Ry		//compares Rx and Ry and if they are equal sets Z flag, otherwise resets Z flag (works by subtracting two values and checks if result is zero)
@ b{cond} <label>		//Jumps to given label in the code if given condition is satisfied
@ umull Rn, Rm, Rx, Ry 	//{Rm, Rn} = Rx * Ry Multiplies unsigned 32bit values in Rx and Ry. Stores the higher 32 bits in Rm, and lower in Rn
@ ldr Rx, [Ry]		//Loads from memory pointed by Ry to register Rx, see addressing modes for post increment, pre decrement
@ str Rx, [Ry]		//Stores to memory pointed by Ry value in register Rx, see addressing modes for post increment, pre decrement
@ pop {}			//Pops values from stack to specified registers in order they are specified
@ push {}			//Push registers to stack in orded they are specified
@ ldmia rx, {set of registers} //Loads to specified set of registers memory values, starting from rx. Increasing addresses
@ stmia rx, {set of registers} //Stores specified set of registers in memory, starting from address pointed by rx. Increasing addresses
