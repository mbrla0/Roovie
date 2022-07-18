MEMORY
{
	RAM(RX) : ORIGIN = 0xa0000000, LENGTH = 128M
}

SECTIONS 
{
	_sdram_base = 0xa0000000;
	_sdram_size = 0x08000000;
	_ssram_base = 0xa8000000;
	_ssram_size = 0x00080000;
	_frame_base = 0xa8000000;
	_frame_size = 0x00038400;

	.RAM : {
		*(.entry*);
		*(.text*);
		*(.rodata*);
		*(.data*);
		*(.bss*);
	} > RAM
}

