.section .entry
start:
	j main

.section .text
	.global _frame_base
	.global _frame_size

main:
	li x6, 0
	la x7, _frame_size
	la x28, _frame_base
clear:
	li x29, 0xff

	add x30, x28, x6
	sb x29, 0(x30)

	addi x6, x6, 1
	bltu x6, x7, clear

halt:
	j halt
