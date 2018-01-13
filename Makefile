source_files := $(wildcard src/*.asm) $(wildcard src/base/*.asm)
object_files := $(patsubst src/%.asm, build/%.o, $(source_files))
linker_scrpt := linker.ld
kernel       := build/kernel.bin
iso_image    := aos.iso

$(kernel): build $(object_files) $(linker_scrpt)
	ld --gc-sections -n -T $(linker_scrpt) -o $@ $(object_files)

.PHONY: clean
clean: 
	@rm -vf $(object_files) $(iso_image)

.PHONY: build
build: 
	@mkdir -p build/base

build/%.o: src/%.asm
	fasm -s $@.symbols $< $@

.PHONY: iso
iso: $(iso_image)

$(iso_image): $(kernel) grub.cfg
	@rm -f aos.iso
	@mkdir -p build/isofiles/boot/grub
	cp $(kernel) build/isofiles/boot/kernel.bin
	cp grub.cfg build/isofiles/boot/grub
	grub-mkrescue -o $@ build/isofiles 2> /dev/null
	@rm -r build/isofiles

run: aos.iso
	@qemu-system-x86_64 -m 512 -cdrom aos.iso -rtc base=localtime,clock=host -cpu host --enable-kvm -smp cpus=2,cores=1,threads=1 \
		-no-reboot -s -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios
debug: aos.iso
	@qemu-system-x86_64 -cdrom aos.iso -d int -no-reboot -s -S -chardev stdio,id=seabios -device isa-debugcon,iobase=0x402,chardev=seabios

bochs: clean iso
	bochs

gdb: 
	gdb "$(kernel)" -ex "target remote :1234" -ex "set step-mode on"

