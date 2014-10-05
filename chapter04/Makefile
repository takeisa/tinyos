image_file=tinyos.img

image_file: ipl.bin tinyos.sys
	mformat -f 1440 -B ipl.bin -C -i ${image_file} ::
	mcopy tinyos.sys -i ${image_file} ::

ipl.bin: ipl.s ipl_lnk.ls
	gcc -nostdlib -o $@ -Tipl_lnk.ls ipl.s
	gcc -Tipl_lnk.ls -c -g -Wa,-a,-ad ipl.s > ipl.lst

tinyos.sys: boot.bin func.o tinyos.c
	gcc -m32 -S -c -nostdlib -Wl,--oformat=binary *.c
	gcc -m32 -c -g -Wa,-a,-ad tinyos.s > tinyos.lst
	gcc -m32 -c -nostdlib -Wl,--oformat=binary *.c -o tinyos.o
	ld -m elf_i386 -o tinyos.bin -e Main --oformat=binary tinyos.o func.o
	cat boot.bin tinyos.bin > $@

boot.bin: boot.s boot_lnk.ls
	gcc boot.s -nostdlib -Tboot_lnk.ls -o boot.bin
	gcc -Tboot_lnk.ls -c -g -Wa,-a,-ad boot.s > boot.lst

func.o: func.s
	as --32 -a -ad func.s > func.lst
	as --32 func.s -o func.o

img:
	make image_file

run:
	qemu-system-i386 -m 32 -localtime -vga std -fda ${image_file}

debug:
	qemu-system-i386 -m 32 -localtime -vga std -fda ${image_file} \
		-gdb tcp::10000 \
		-S

clean:
	rm tinyos.sys boot.bin
	rm *.o
