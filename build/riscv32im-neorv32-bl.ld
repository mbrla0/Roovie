MEMORY
{
	ROM(RX) : ORIGIN = 0x00000000, LENGTH = 16k
}

SECTIONS 
{
	_load_addr = 0xa0000000;
	_stack = 0xa807fffc;
	
	.ROM : {
		. = 0x000000;
		*(.reset_vector);
		*(.trap_handler);
		*(.text*);
		*(.rodata);
	} > ROM
}

