all: binsh shellcode

binsh: binsh32 binsh64

binsh32: binsh32.asm
	nasm -f macho -o binsh32.o binsh32.asm
	ld -arch i386 -o binsh32 binsh32.o

binsh64: binsh64.asm
	nasm -f macho64 -o binsh64.o binsh64.asm
	ld -arch x86_64 -o binsh64 binsh64.o

shellcode: shellcode32 shellcode64

shellcode32: shellcode.c
	gcc -m32 -o shellcode32 shellcode.c

shellcode64: shellcode.c
	gcc -o shellcode64 shellcode.c

clean:
	rm -f binsh{32,64}.o binsh{32,64}
	rm -f shellcode{32,64}
