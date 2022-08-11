
.section .text
	.global sys_procedure_trap_handler_setup

sys_procedure_trap_handler_setup:
	# Save a pointer to the context block into the trap handler scratch
	# register, so that when the handler gets called, we know where we should
	# save the content of the registers.
	#
	# We also have to make sure the pointer is word-aligned. We do this by
	# simply adding to the pointer however many bytes are needed to align the
	# the base address of the symbol.
	#
	la x6, trap_context_block
	srli x6, x6, 2
	addi x6, x6, 1
	slli x6, x6, 2

	csrw mscratch, x6

	# Set up the pointer to the trap handler.
	la x6, trap_handler
	srli x6, x6, 2
	csrw mtvec, x6

	ret

# Handles the
trap_handler:
	# Save the x6 and x7 registers so that we may use them for .
	csrrw x6, mscratch, x6
	sw x7, 7*4(x6)
	csrrw x7, mscratch, x6
	sw x7, 6*4(x6)

.section .data
trap_context_block:
	# Set aside space for the data structure that will be used by the handler to
	# save the state of the processor across traps.
	.zero 120
