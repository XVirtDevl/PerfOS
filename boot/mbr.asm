%include "elf64.inc"
org 0x7C00
[BITS 16]
_start:
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax

mov sp, 0x9000

mov ah, 0x42
mov si, DAP_PACKET
mov word[ DAP_PACKET.count ], 127
mov word[ DAP_PACKET.segment ], 0x1000
mov dword[ DAP_PACKET.start_lba ], 1
int 0x13
jc fatal_error


cli
lgdt[gdt_limit]

in al, 0x92
cmp al, 0xFF
jz fatal_error

or al, 2
and al, ~1
out 0x92, al

mov eax, cr0
or eax, 1
mov cr0, eax
jmp 0x8:ProtectedMode


fatal_error:
	int 18h
%define FILEADDR 0x10000
[BITS 32]
ProtectedMode:
	mov ax, 0x10
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov gs, ax
	mov ss, ax
	mov esp, 0x300000

	mov ebx, FILEADDR	;ELF Header Address
	cmp dword[ ebx ], ELFMAGIC
	jnz .no_elf

	mov dx, word[ ebx + elf64header.programmheader_num ]	
	add ebx, dword[ ebx + elf64header.programmheader_offset ]		
	

	.loadAll:
		mov esi, dword[ ebx + programmheader.offsetinfile ]
		mov ecx, dword[ ebx + programmheader.sizeofsegmentinfile ]
		add esi, FILEADDR
		mov edi, dword[ ebx + programmheader.paddr ]

		push ecx
		shr ecx, 2

		rep movsd

		pop ecx
		and ecx, 0x3
		rep movsb

		add ebx, HeaderSize
		sub dx, 1
		jnz .loadAll


	mov ebx, dword[ FILEADDR + elf64header.entry_point ]	
	push ebx
	ret

	.no_elf:
		mov eax, 0xAF9
		
		jmp $



align 8
DAP_PACKET:
	.signature db 0x10
	.reserved db 0
	.count dw 0
	.offset dw 0
	.segment dw 0
	.start_lba dd 0
	.end_lba dd 0

gdt_limit dw 24
gdt_end dd gdt
gdt:
	dd 0
	dd 0
	
	dd 0xFFFF
	dd 0x00CF9A00
	
	dd 0xFFFF
	dd 0x00CF9200
times 0x1be-($-$$) hlt	
db 0x80
db 0
dw 0
db 0x7D
db 2
dw 3
dd 3
dd 0
times 510-($-$$) hlt
db 0x55
db 0xAA
_end:
