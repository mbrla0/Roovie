RUSTUP=rustup
TOOLCHAIN=nightly
AS=../tools/riscv32-elf-as
LD=../tools/riscv32-elf-ld
OC=../tools/riscv32-elf-objcopy

OBJS=sys/start.o sys/trap.o
TARGET=../build/riscv32-neorv32-kernel.json

ifeq ($(RELEASE),1)
_TARGET_SUBDIR=release
_RELEASE_MODE_STRING=
else
_TARGET_SUBDIR=debug
_RELEASE_MODE_STRING=--release
endif

all: kernel.bin

kernel.bin: kernel.elf
	$(OC) $< --output-format binary $@

kernel.elf: ../build/riscv32-neorv32-kernel.ld kernel $(OBJS)
	$(LD) -T $< $(OBJS) target/riscv32-neorv32-kernel/$(_TARGET_SUBDIR)/libkernel.a -o $@

kernel: $(TARGET)
	$(RUSTUP) run $(TOOLCHAIN) cargo build $(_RELEASE_MODE_STRING) --target=$(TARGET) \
		-Zbuild-std=core,compiler_builtins \
		-Zbuild-std-features=compiler-builtins-mem

.s.o:
	$(AS) -c -o $@ $<

clean:
	rm -rf kernel.bin $(OBJS)
	$(RUSTUP) run $(TOOLCHAIN) cargo clean

.PHONY: clean kernel