Programada2: Programada2.o
	ld -m elf_i386 -o Programada2 Programada2.o

Programada2.o: Programada2.asm
	nasm -f elf -g -F stabs Programada2.asm -l Programada2.lst
