
.section .entry
	j start

.section .text
	.global kernel_main

	.global bss_start
	.global bss_end

	.global kernel_image_ro_offset
	.global kernel_image_ro_size
	.global kernel_image_rw_offset
	.global kernel_image_rw_size

	.global system_table
start:
	# Set up the stack pointer.
	#
	# This reads the preliminary stack pointer location from the system table
	# at byte offset zero. A better located and more well-protected stack will
	# be set up later on by the kernel.
	#
	la x6, system_table
	lw x6, 0(x6)
	lw x2, 1(x6)

	# Clear the BSS.
	la x6, bss_start
	la x7, bss_end
clear_bss:
	sw x0, 0(x6)

	addi x6, x6, 4
	bltu x6, x7, clear_bss

	# Transfer control to the Rust side of the kernel.
	#
	# The value of x10 it set by the bootloader and points to the beginning of
	# the system table. It can be thought of as being passed directly by the
	# bootloader as the first argument to kernel_main.
	la x11, kernel_image_ro_offset
    la x12, kernel_image_ro_size
    la x13, kernel_image_rw_offset
    la x14, kernel_image_rw_size
	jal kernel_main

	# If the kernel has brought itself up successfully, execution should never
	# return to this path. However, if, for any reason, it does, we better make
	# sure we catch it so as to prevent the CPU from going rogue.
halt:
	j halt
