AS=../tools/riscv32-elf-as
LD=../tools/riscv32-elf-ld
OC=../tools/riscv32-elf-objcopy
CO=../tools/conv.py
ST=../tools/systable.py

OBJS=bl.o blake2s.o trap.o

all: bl.bin bl.vhd

bl.vhd: bl.bin
	$(CO) $< $@

bl.bin: bl.elf
	$(OC) $< --output-format binary $@

bl.elf: ../build/riscv32-neorv32-bl.ld $(OBJS)
	$(LD) -T $< $(OBJS) -o $@

bl.o: bl.s systable.bin
	$(AS) -c -o $@ $<

systable.bin: ../build/neorv32.toml
	$(ST) $< $@

.s.o:
	$(AS) -c -o $@ $<

clean:
	rm -rf $(OBJS) systable.bin bl.vhd bl.bin bl.elf
