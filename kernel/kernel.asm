%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM
db 'Hallo Welt wie gehts?',0


section .text
global _start
_start:
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
Hellau db 'Just before this?',0
