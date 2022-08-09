# 
# Bootloader.
# 

.section .data
	.global _stack
	.global _load_addr

.section .reset_vector 
reset:
	j	setup

.section .trap_handler
	.global trap_handler_vector

.section .text
	.global proc_sha3_hash
	.global proc_puts
	.global proc_putud

	.equ UART_0_BAUD_RATE, 19200

	.equ NEORV32_UART_0_CTRL, 0xFFFFFFA0
	.equ NEORV32_UART_0_DATA, 0xFFFFFFA4

	.equ NEORV32_SYSINFO_CLOCK, 0xFFFFFFE0

	.equ MAIN_DIGEST_SIZE, 32

	.equ MAIN_MESSAGE_SIZE, 0
	.equ MAIN_EXPECTED_SUM, 4
	.equ MAIN_RECEIVED_SUM, 4 + MAIN_DIGEST_SIZE

	.macro dpin val
		addi x2, x2, -4
		sw x6, 0(x2)

		li x6, \val
		sw x6, 0xffffffc8(x0)

		lw x6, 0(x2)
		addi x2, x2, 4
	.endm
setup:
	# Set up the trap handler.
	la x6, trap_handler_vector
	srli x6, x6, 2
	csrw 0x305, x6 # mtvec

	# Make sure the stack pointer points to the right place.
	la x2, _stack

	dpin 2

start:
	addi x2, x2, -68

	li x10, UART_0_BAUD_RATE
	jal proc_uart0_init

	dpin 5

	la x10, msg_head
	jal	proc_puts
	la x10, msg_seq0
	jal	proc_puts

	dpin 8

	# Load the size of the message.
	li x10, 4
	mv x11, x2
	jal proc_load

	la x10, msg_seq1
	jal proc_puts
	
	dpin 9

	lw x28, MAIN_MESSAGE_SIZE(x2)
	mv x10, x28
	jal proc_putud

	la x10, msg_seq2
	jal proc_puts

	dpin 10

	# Load the expected value for the checksum.
	li x10, MAIN_DIGEST_SIZE
	addi x11, x2, MAIN_EXPECTED_SUM
	jal proc_load

	dpin 11

	la x10, msg_seq3
	jal proc_puts

	la x10, msg_seq3a
	jal proc_puts

	# Load the message.
	lw x10, MAIN_MESSAGE_SIZE(x2)
	la x11, _load_addr
	jal proc_load

	la x10, msg_seq3
	jal proc_puts

	lw x10, MAIN_MESSAGE_SIZE(x2)
	jal proc_putud

	la x10, msg_seq4
	jal proc_puts

	# Digest and check the message.
	la x10, _load_addr
	lw x11, MAIN_MESSAGE_SIZE(x2)
	li x12, 0
	li x13, 0
	li x14, MAIN_DIGEST_SIZE
	mv x15, x2
	addi x15, x15, MAIN_RECEIVED_SUM
	jal proc_blake2s_digest

	la x10, msg_seq5
	jal proc_puts

	# Verify integrity.
	li x6, 0
	li x7, MAIN_DIGEST_SIZE
integrity:
	add x30, x2, x6
	lw x28, MAIN_EXPECTED_SUM(x30)
	lw x29, MAIN_RECEIVED_SUM(x30)
	
	bne x28, x29, integrity_failed

	addi x6, x6, 4
	bltu x6, x7, integrity

	la x10, msg_seq6
	jal proc_puts

    la x10, system_table
	la x11, _load_addr
	jr x11

	j halt
integrity_failed:
	la x10, msg_err0
	jal proc_puts
halt:
	addi x2, x2, 36
halt_d:
	j halt_d


# uart0_init
# 
# Initializes the UART 0 interface bundled in the NEORV32 SoC to a baud rate
# whose value is given by x10.
proc_uart0_init:
	li x28, NEORV32_SYSINFO_CLOCK
	lw x29, 0(x28)

	li x28, UART_0_BAUD_RATE
	li x30, 2

	mul  x28, x28, x30
	divu x28, x29, x28
	
	li x29, 0xffff
	and x28, x28, x29

	mv x29, x0

	dpin 3

	li x30, 0x0fff
	li x31, 2
	li x6,  4
_start_baud_calc:
	bleu x28, x30, _start_baud_calc_done

	beq  x29, x31, _start_baud_calc_divisor_shift_two
	beq  x29, x6,  _start_baud_calc_divisor_shift_two
	
	srli x28, x28, 1
	j _start_baud_calc_divisor_shift_one
_start_baud_calc_divisor_shift_two:
	srli x28, x28, 3
_start_baud_calc_divisor_shift_one:
	addi x29, x29, 1
	j _start_baud_calc

_start_baud_calc_done:
	li x6, 1
	
	dpin 4

	slli x6,  x6,  28
	slli x29, x29, 24

	or x28, x28, x6
	or x28, x28, x29

	li x29, NEORV32_UART_0_CTRL
	sw x28, 0(x29)

	ret

# load
#
# Reds a number of bytes from the UART 0 interface and saves them to a region in
# memory starting at t given address.
#
# The number of bytes to be read is given by x10 and the base address of the
# memory region where the data is to be saved is given by x11
proc_load:
	li x28, 0
	li x29, NEORV32_UART_0_DATA

	beq x10, x0, _load_done
_load_not_done:
	lw x30, 0(x29)

	srli x31, x30, 31
	beq  x31, x0, _load_not_done

	add  x6, x11, x28
	sb   x30, 0(x6)
	addi x28, x28, 1

	bltu x28, x10, _load_not_done
_load_done:
	ret

# putud
#
# Outputs the value at register x10 as a decimal unsigned integer.
proc_putud:
	addi x2, x2, -40
	sw x10, 32(x2)
	sw x1,  36(x2)

	mv x28, x10
	li x29, 10
	li x31, 30
	sb x0,  31(x2)

	beq x28, x0, _putud_eq0
_putud_dec:
	beq x28, x0, _putud_print
	
	rem  x30, x28, x29
	divu x28, x28, x29

	addi x30, x30, 0x30

	add  x6, x2, x31
	sb   x30, 0(x6)
	addi x31, x31, -1

	j _putud_dec
_putud_eq0:
	la x10, msg_zero
	jal proc_puts
	j _putud_done
_putud_print:
	add  x10, x2, x31
	addi x10, x10, 1

	jal proc_puts
_putud_done:
	lw   x10, 32(x2)
	lw   x1,  36(x2)
	addi x2, x2, 40
	ret

# puts
#
# Outputs the string starting at the address given by x10 and continuing up to
# a terminating null byte, signaling the end of the string.
proc_puts:
	mv x6,  x0
	li x30, 0x40000
	
	dpin 6
_puts_loop:
	add  x7, x10, x6
	lbu  x28, 0(x7)
	beq  x28, x0, _puts_done
	addi x6,  x6, 1

_puts_putc_wait:
	li  x29, NEORV32_UART_0_CTRL
	lw  x31, 0(x29)
	and x31, x31, x30
	bne x31, x0, _puts_putc_wait

	dpin 7

	li x29, NEORV32_UART_0_DATA
	sw x28, 0(x29)

	j _puts_loop
_puts_done:
	ret


.section .rodata
msg_seq0:	.asciz "Waiting to load signed system image.\r\n"
msg_seq1:	.asciz "Message size is "
msg_seq2:	.asciz " bytes.\r\n"
msg_seq3:	.asciz "-> Loaded "
msg_seq3a:	.asciz "the checksum.\r\n"
msg_seq4:	.asciz "message bytes.\r\n"
msg_seq5:	.asciz "Verifying the integrity of the system image.\r\n\r\n"
msg_seq6:	.asciz "Booting!\r\n\r\n"
msg_err0:	.asciz "Integrity verification failed!\r\nHalting.\r\n"
msg_zero:	.asciz "0"
msg_head:	.asciz "\r\nFurry's Horrible Terrible Good For Nothing Bootloader TM\r\nIt better not bounce or you're a dead motherfucker (C) 2077 Furry do BCC\r\n\r\n"
system_table:
    .incbin "systable.bin"
