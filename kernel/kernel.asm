%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)

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


	mov edi, 0xb8000	
	mov eax, 0x0f200f20
	mov ecx, 1024
	rep stosd

	mov edi, 0xb8000
	mov esi, Hellau
	
	.forever:
		mov al, byte[ esi ]
		or al, al
		jz .done
		mov byte [edi], al
		add esi, 1
		add edi, 2
		jmp .forever
			
	.done:
		jmp $

	jmp $

	.FatalError:
		mov edi, 0xb8000
		mov esi, NoMultiboot
	  	jmp .forever

NoMultiboot db 'Fatal error the kernel wasnt loaded by a multiboot bootloader!',0
MultibootAddr dd 0
Hellau db 'Just before this?',0
