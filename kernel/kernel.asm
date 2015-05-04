%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM

%define GDT_BASE 0
gdt_limit dw 24
gdt_base dd GDT_BASE


extern main
section .text
global _start
_start:
	xor eax, eax		;Set up new gdt to ensure transparence as well as enable 64 bit segment descriptors
	mov dword[ GDT_BASE + 0 ], eax
	mov dword[ GDT_BASE + 4 ], eax

	mov eax, 0xFFFF
	mov dword[ GDT_BASE + 8 ], eax
	mov dword[ GDT_BASE + 16 ], eax

	mov eax, 0x00CF9A00
	mov dword[ GDT_BASE + 12 ], eax

	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 20 ], eax

	lgdt[ gdt_limit ]
	jmp 0x8:_OwnGDT	

align 8
	_OwnGDT:
		mov ax, 0x10
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax
	
		push ebx
		call main
		jmp $
