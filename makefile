hex2raw: hex2raw.o h2rlib.o
	ld -o hex2raw hex2raw.o h2rlib.o
h2rlib.o: h2rlib.asm
	nasm -f elf -g -F stabs h2rlib.asm
hex2raw.o: hex2raw.asm
	nasm -f elf -g -F stabs hex2raw.asm
