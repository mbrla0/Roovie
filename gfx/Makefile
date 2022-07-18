AS=../tools/riscv32-elf-as
LD=../tools/riscv32-elf-ld
OC=../tools/riscv32-elf-objcopy

OBJS=main.o

all: gfx.bin

gfx.bin: gfx.elf
	$(OC) $< --output-format binary $@

gfx.elf: ../build/riscv32-neorv32-gfx.ld $(OBJS)
	$(LD) -T $< $(OBJS) -o $@

.s.o:
	$(AS) -c -o $@ $<

clean:
	rm -rf *.o gfx.bin gfx.elf
