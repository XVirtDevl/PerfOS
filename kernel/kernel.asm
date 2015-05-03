%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)
%include "io.inc"

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM


section .text
global _start
_start:
	cmp eax, 0x2BADB002
	jnz .FatalError
	mov dword[MultibootAddr], ebx

	call _clrScreen

	mov esi, Hellau
	call _printString

	mov esi, Hellau
	call _printString
	
	jmp $
	.FatalError:
		mov esi, NoMultiboot
		call _printString
		jmp $

NoMultiboot db 'Fatal error the kernel wasnt loaded by a multiboot bootloader!',0
MultibootAddr dd 0
Hellau db 'Just before this?',0x13,0
