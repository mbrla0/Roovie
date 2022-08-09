MEMORY
{
	RAM(RX) : ORIGIN = 0xa0000000, LENGTH = 128M
}

SECTIONS 
{
	/* Location of the platform information structure in memory. */
	system_table = 0xa8000000;

	_frame_base = 0xa8000000;
	_frame_size = 0x00038400;

	.RAM : {
		*(.entry*);
		*(.text*);
		*(.rodata*);

		*(.data*);
		bss_start = .;
		*(.bss*);
		bss_end = .;
		kernel_end = .;
	} > RAM
}

