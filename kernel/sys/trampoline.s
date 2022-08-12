# trampoline.s - Execution trampolining facilities.
#
# In order to perform some of its functions, the kernel may require jumps that
# overwrite the current call stack by arbitrarily changing the stack pointer
# during the jump. In addition, it may also require extra operations in order to
# set up and perform a context switch to a user-level application.
#
# Unsurprisingly, these facilities aren't supported, or available, in a high-
# level language such as Rust and, thus, we must implement them manually.
#

.section .text
	.global sys_procedure_stack_jump
sys_procedure_stack_jump:
	# Save the arguments to this function call.
	mv x2, x10
	mv x6, x11

	# Move any potential variadic argument to the function call into its
	# respective target argument register.
	mv x10, x12
	mv x11, x13
	mv x12, x14
	mv x13, x15
	mv x14, x16
	mv x15, x17

	jalr x0, 0(x6)