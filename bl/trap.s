#
# Implementation of the boot time trap handler.
#

.section .text
	.global proc_puts
	.global proc_putud

.section .trap_handler
	.global trap_handler_vector
trap_handler_vector:
	la x10, msg0
	jal proc_puts

	la x10, msg1
	jal proc_puts

	csrr x7, 0x341 # mepc
	csrr x8, 0x342 # mcause

	li x28, 7
	and x8, x8, x28

	mv x10, x8
	jal proc_putud

	la x10, msg2
	jal proc_puts

	mv x10, x7
	jal proc_putud

	la x10, msg3
	jal proc_puts

halt:
	j halt

.section .rodata
msg0: .asciz "!!! The bootloader raised a CPU trap"
msg1: .asciz "\r\nReason "
msg2: .asciz "\r\nPC = "
msg3: .asciz "\r\nHalting\r\n"
