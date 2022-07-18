AS=../tools/riscv32-elf-as
LD=../tools/riscv32-elf-ld
OC=../tools/riscv32-elf-objcopy
CO=../tools/conv.py

OBJS=bl.o blake2s.o trap.o

all: bl.bin bl.vhd

bl.vhd: bl.bin
	$(CO) $< $@

bl.bin: bl.elf
	$(OC) $< --output-format binary $@

bl.elf: ../build/riscv32-neorv32-bl.ld $(OBJS)
	$(LD) -T $< $(OBJS) -o $@

.s.o:
	$(AS) -c -o $@ $<

clean:
	rm -rf *.o bl.vhd bl.bin bl.elf
