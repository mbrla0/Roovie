# 
# Implementation of the BLAKE2s hashing procedure.
#
# This primitive is used extensively by the integrity protection code in the 
# bootloader, seeing as it is used both for the implementation of the SHA-3
# algorithm, as well as for the boot image authentication and integrity 
# verification stages of the boot processs.
#

.section .text
	.global proc_blake2s_digest
	
	# Offset table into the fields of the context structure.
	.equ CTX_INPUT_BUFFER, 0
	.equ CTX_CHAINED_STATE, 64
	.equ CTX_COUNTERS_LOW, 94
	.equ CTX_COUNTERS_HIGH, 100
	.equ CTX_INPUT_INDEX, 104
	.equ CTX_DIGEST_SIZE, 108

# blake2s_digest
#
# Process a message based at x10, whose length is given by x11, with a key based
# x12, whose length is x13, into a digest of length x14 based at x15 
#
proc_blake2s_digest:
	# Oh my thats a lotta stack space.
	#
	# Reserve enough stack space for the return address as well as the context
	# block required to process the message.
	addi x2, x2, -148
	sw x1,  112(x2)
	sw x10, 116(x2)
	sw x11, 120(x2)
	sw x18, 124(x2)
	sw x19, 128(x2)
	sw x20, 132(x2)
	sw x21, 136(x2)
	sw x22, 140(x2)
	sw x23, 144(x2)

	# Initialize the context structure.
	la x6, blake2s_iv
	li x7,  0
	li x30, 8
	li x31, 4
_blake2s_init_iv:
	mul  x28, x7, x31
	addi x29, x28, CTX_CHAINED_STATE
	add x29, x29, x2

	lw x7, 0(x28)
	sw x7, 0(x29)

	addi x7, x7, 1
	bltu x7, x30, _blake2s_init_iv

	lw x6, CTX_CHAINED_STATE(x2)
	li x7, 0x01010000
	xor x6, x6, x7
	mv x7, x13
	slli x7, x7, 8
	xor x6, x6, x7
	xor x6, x6, x14
	sw x6, CTX_CHAINED_STATE(x2)

	sw x0, CTX_COUNTERS_LOW(x2)
	sw x0, CTX_COUNTERS_HIGH(x2)
	sw x0, CTX_INPUT_INDEX(x2)
	sw x14, CTX_DIGEST_SIZE(x2)

	# Zero the input block.
	li x6, 0
	li x7, 64
_blake2s_init_zero_input:
	add x28, x6, x2
	sw x0, CTX_INPUT_BUFFER(x28)

	addi x6, x6, 4
	bltu x6, x7, _blake2s_init_zero_input 

	# Prefix the message with the key, if one has been provided.
	beq x0, x13, _blake2s_init_no_key

	li x6, 0
_blake2s_init_copy_key_prefix:
	add x7, x12, x6
	lbu x28, 0(x7)

	add x7, x2, x6
	sb x28, CTX_INPUT_BUFFER(x7)

	addi x6, x6, 1
	bltu x6, x13, _blake2s_init_copy_key_prefix

	li x6, 64
	sw x6, CTX_INPUT_INDEX(x2)
_blake2s_init_no_key:
	# Start consuming the input data.
	li x20, 0
	li x19, 64
	mv x21, x10
	mv x22, x11
_blake2s_consume_input_not_empty:
	lw x18, CTX_INPUT_INDEX(x2)
	bltu x18, x19, _blake2s_consume_buffer_not_full

	lw x7, CTX_INPUT_INDEX(x2)
	lw x18, CTX_COUNTERS_LOW(x2)

	add x18, x18, x7
	sw x18, CTX_COUNTERS_LOW(x2)

	bgeu x18, x7, _blake2s_consume_low_counter_didnt_overflow

	lw x7, CTX_COUNTERS_HIGH(x2)
	addi x7, x7, 1
	sw x7, CTX_COUNTERS_HIGH(x2)
_blake2s_consume_low_counter_didnt_overflow:
	mv x10, x2
	li x11, 0
	jal proc_blake2s_compress

	sw x0, CTX_INPUT_INDEX(x2)
_blake2s_consume_buffer_not_full:
	add x7, x21, x20
	lbu x28, 0(x7)

	add x29, x2, x20
	sb x28, CTX_INPUT_BUFFER(x29)

	lw x18, CTX_INPUT_INDEX(x2)
	addi x18, x18, 1
	sw x18, CTX_INPUT_INDEX(x2)

	addi x20, x20, 1
	bltu x20, x22, _blake2s_consume_input_not_empty

	# Finalize the buffer by first adding to the counters.
	lw x7,  CTX_INPUT_INDEX(x2)
	lw x18, CTX_COUNTERS_LOW(x2)

	add x18, x18, x7
	sw x18, CTX_COUNTERS_LOW(x2)

	bgeu x18, x7, _blake2s_consume_low_counter_didnt_overflow

	lw x7, CTX_COUNTERS_HIGH(x2)
	addi x7, x7, 1
	sw x7, CTX_COUNTERS_HIGH(x2)
_blake2s_finalize_low_counter_didnt_overflow:
	
	# Fill the rest of the input buffer with zeros.
	lw x6, CTX_INPUT_INDEX(x2)
	li x7, 64
_blake2s_finalize_fill_input_buffer:
	add x28, x6, x2
	sb x0, CTX_INPUT_BUFFER(x28)

	addi x6, x6, 1
	bltu x6, x7, _blake2s_finalize_fill_input_buffer

	# Compress the final block.
	mv x10, x2
	li x11, 1
	jal proc_blake2s_compress

	li x6, 0
	lw x7, CTX_DIGEST_SIZE(x2)
_blake2s_finalize_output_data:
	add x30, x2, x6
	lbu x28, CTX_CHAINED_STATE(x30)

	add x30, x15, x6
	sb x28, 0(x30)

	addi x6, x6, 1
	bltu x6, x7, _blake2s_finalize_output_data

	# Return.
	lw x1,  112(x2)
	lw x10, 116(x2)
	lw x11, 120(x2)
	lw x18, 124(x2)
	lw x19, 128(x2)
	lw x20, 132(x2)
	lw x21, 136(x2)
	lw x22, 140(x2)
	lw x23, 144(x2)
	addi x2, x2, 148
	ret

# blake2s_compress
#
# Compress the data in the context block pointed to by x10, finalizing the data
# input procedure if x11 is non-zero.
	.equ COMPRESS_V, 0
	.equ COMPRESS_M, 64

	# lwlw - Load word, little endian.
	#
	# Loads four bytes starting at the given address as a 32bit word, assuming
	# the word is stored as little endian. Cobbles both the x6 and x7 registers.
	.macro lelw reg0, base, offset
		# For most RISC-V environments, including the NEORV32 it holds that the
		# processor is little-endian as far as loads and stores are concerned.
		lw \reg0, \offset(\base)
	.endm


	# blake2_mix_step_rot - Perform the bit rotation step.
	.macro blake2_mix_step_rot vbaser, voffseti, reg0, reg1, i0, i1, ammount
		lw \reg0, \voffseti+\i0*4(\vbaser)
		lw \reg1, \voffseti+\i1*4(\vbaser)
		xor \reg0, \reg0, \reg1

		mv \reg1, \reg0
		srli \reg0, \reg0, \ammount
		slli \reg1, \reg1, 32 - \ammount
		xor \reg0, \reg0, \reg1

		sw \reg0, \voffseti+\i0*4(\vbaser)
	.endm

	# blake2_mix_step_add - Perform the addition step.
	.macro blake2_mix_step_add vbaser, voffseti, reg0, reg1, i0, i1, valr
		lw \reg0, \voffseti+\i0*4(\vbaser)
		lw \reg1, \voffseti+\i1*4(\vbaser)
		add \reg0, \reg0, \valr
		add \reg0, \reg0, \reg1
		sw \reg0, \voffseti+\i0*4(\vbaser)
	.endm

	# blake2_mix - Mix coefficients.
	#
	# The mixing functionality for the BLAKE2 algorithm. Cobbles the x6, x7, and
	# x28 registers.
	.macro blake2_mix vbaser, voffseti, moffseti, ai, bi, ci, di, ir, xi, yi
		# Perform the sigma mapping to the x parameter.
		la x6, blake2s_sigma
		
		li x7, 16
		mul x7, x7, \ir
		addi x7, x7, \xi
		
		add x6, x6, x7
		lbu x7, 0(x6)

		add x6, \vbaser, x7
		lw x28, \moffseti(x6)

		blake2_mix_step_add \vbaser, \voffseti, x6, x7, \ai, \bi, x28
		blake2_mix_step_rot \vbaser, \voffseti, x6, x7, \di, \ai, 16
		blake2_mix_step_add \vbaser, \voffseti, x6, x7, \ci, \di, x0
		blake2_mix_step_rot \vbaser, \voffseti, x6, x7, \bi, \ci, 12
		
		# Perform the sigma mapping to the y parameter.
		la x6, blake2s_sigma
		
		li x7, 16
		mul x7, x7, \ir
		addi x7, x7, \yi
		
		add x6, x6, x7
		lbu x7, 0(x6)

		add x6, \vbaser, x7
		lw x28, \moffseti(x6)

		blake2_mix_step_add \vbaser, \voffseti, x6, x7, \ai, \bi, x28
		blake2_mix_step_rot \vbaser, \voffseti, x6, x7, \di, \ai, 8
		blake2_mix_step_add \vbaser, \voffseti, x6, x7, \ci, \di, x0
		blake2_mix_step_rot \vbaser, \voffseti, x6, x7, \bi, \ci, 7
	.endm

proc_blake2s_compress:
	addi x2, x2, -128

	# Load the values into the work array.
	li x6, 0
	li x7, 32
_blake2s_compress_init_work:
	add x28, x6, x10
	lw x29, CTX_CHAINED_STATE(x28)

	add x28, x6, x2
	sw x29, COMPRESS_V(x28)

	la x30, blake2s_iv
	add x30, x30, x6
	
	lw x29, 0(x30)
	sw x29, COMPRESS_V+32(x28)

	addi x6, x6, 4
	bltu x6, x7, _blake2s_compress_init_work

	# Take the counters into account.
	lw x6, CTX_COUNTERS_LOW(x10)
	lw x7, COMPRESS_V+48(x2)
	xor x6, x6, x7
	sw x6, COMPRESS_V+48(x2)

	lw x6, CTX_COUNTERS_HIGH(x10)
	lw x7, COMPRESS_V+52(x2)
	xor x6, x6, x7
	sw x6, COMPRESS_V+52(x2)

	beqz x11, _blake2s_compress_init_not_final

	# Mark this block as being the last one in the digest.
	lw x6, COMPRESS_V+56(x2)
	xori x6, x6, -1
	sw x6, COMPRESS_V+56(x2)
_blake2s_compress_init_not_final:

	li x28, 0
	li x29, 64
_blake2s_compress_load_input:
	add x30, x10, x28
	lelw x6, x30, CTX_INPUT_BUFFER

	add x31, x2, x28
	sw x6, COMPRESS_M(x31)

	addi x28, x28, 4
	bltu x28, x29, _blake2s_compress_load_input

	# Perform ten rounds of the rotation procedure.
	li x30, 0
	li x31, 10
_blake2_compress_mix:
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 0, 4,  8, 12, x30,  0,  1
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 1, 5,  9, 13, x30,  2,  3
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 2, 6, 10, 14, x30,  4,  5
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 3, 7, 11, 15, x30,  6,  7
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 0, 5, 10, 15, x30,  8,  9
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 1, 6, 11, 12, x30, 10, 11
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 2, 7,  8, 13, x30, 12, 13
	blake2_mix x2, COMPRESS_V, COMPRESS_M, 3, 4,  9, 14, x30, 14, 15

	addi x30, x30, 1
	bltu x31, x31, _blake2_compress_mix

	# Save the bytes we've just processed into the chained state.
	li x30, 0
	li x31, 32
_blake2_compress_save_chained_state:
	add x6, x30, x2
	lw x28, COMPRESS_V(x6)
	lw x29, COMPRESS_V+32(x6)

	xor x28, x28, x29
	
	add x6, x30, x10
	lw x29, CTX_CHAINED_STATE(x6)

	xor x28, x28, x29
	sw x28, CTX_CHAINED_STATE(x6)

	addi x30, x30, 4
	bltu x30, x31, _blake2_compress_save_chained_state

	addi x2, x2, 128
	ret

.section .rodata
blake2s_iv:
	.word 0x6A09E667, 0xBB67AE85, 0x3C6EF372, 0xA54FF53A
	.word 0x510E527F, 0x9B05688C, 0x1F83D9AB, 0x5BE0CD19
blake2s_sigma:
	.byte 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15
	.byte 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3
	.byte 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4
	.byte 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8
	.byte 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13
	.byte 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9
	.byte 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11
	.byte 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10
	.byte 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5
	.byte 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0

