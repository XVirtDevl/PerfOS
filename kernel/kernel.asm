%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM

extern main
section .text
global _start
_start:
	push ebx
	call main
	jmp $
