hex2raw: hex2raw.o
	ld -o hex2raw hex2raw.o
hex2raw.o: hex2raw.asm
	nasm -f elf -g -F stabs hex2raw.asm
