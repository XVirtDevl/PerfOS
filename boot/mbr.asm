%include "elf64.inc"
%include "multiboot.inc"
%define mmap_addr 0x2004
%define BOOT_SECTORS 2
org 0x7C00
[BITS 16]
_start:
xor ax, ax
mov ds, ax
mov es, ax
mov ss, ax

mov sp, 0x9000

mov byte[ BOOTDRIVE ], dl

mov cx, word[ 0x7C00 + 500 ]
mov word[ DAP_PACKET.segment ], 0x1000
mov dword[ DAP_PACKET.start_lba ], 1

.try_again:
cmp cx, 64
ja .multiple_load
mov word[ DAP_PACKET.count ], cx
mov si, DAP_PACKET
mov ah, 0x42
mov dl, byte[ BOOTDRIVE ]
int 0x13
jc fatal_error

mov dword[ MultibootStrucAddr + multiboot.flags ], 64
mov dword[ MultibootStrucAddr + multiboot.mmap_addr ], mmap_addr

mov eax, 0xE820
mov edx, 0x534D4150 
xor ebx, ebx
mov ecx, 24
mov di, mmap_addr+4
clc
int 0x15
jc fatal_error

sub di, 4
mov dword[ di ], ecx
add di, 4

.again_mmap:

mov edx, 0xE820
xchg eax, edx
add di, cx
add di, 4
int 0x15
pushf
sub di, 4
mov dword[ di ], ecx
add di, 4
popf
jc .next

or ebx, ebx
jnz .again_mmap

.next:
	sub di, 4
	sub di, mmap_addr
	mov word[ MultibootStrucAddr + multiboot.mmap_length ], di

call 0x1000:0

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

.multiple_load:
	mov cx, 64
	sub word[ 0x7C00 + 500 ], cx
	
	mov word[ DAP_PACKET.count ], cx
	mov si, DAP_PACKET
	mov ah, 0x42
	mov dl, byte[ BOOTDRIVE ]
	int 0x13
	jc fatal_error

	add word[ DAP_PACKET.offset ], 0x8000
	jo .segment_up

.back:
	add dword[ DAP_PACKET.start_lba ], 64
	
	mov cx, word[ 0x7C00 + 500 ]
	jmp .try_again

.segment_up:
	add word[ DAP_PACKET.segment ], 0x1000	
	jmp .back

fatal_error:
	int 18h


%define FILEADDR 0x10000+(BOOT_SECTORS*512)
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


	mov eax, dword[ FILEADDR + elf64header.entry_point ]	
	push eax
	mov ebx, MultibootStrucAddr
	ret

	.no_elf:
		mov eax, 0xAF9
		
		jmp $



BOOTDRIVE db 0
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
[BITS 16]
_end:
	xor di, di
	call clear_screen
	mov ax, 0x4F00
	mov di, 0x7E00
	xor bx, bx
	mov dword[ di ], 'VBE2'
	int 0x10

	jc .failure

	cmp ax, 0x4F
	jnz .failure

	test byte[ 0x7E0A ], 8
	jz .no_accel

	mov di, word[ 0x7E24 ]
	mov bp, 0x7E24

	mov si, AcellVideo
	call print_string

	jmp .done_accel
	.no_accel:
		mov di, word[ 0x7E0E ]
		mov bp, 0x7E0E
		push 0x1000
		pop ds
		mov si, (StdVideo-_end)
		call print_string
		xor ax, ax
		mov ds, ax
	.done_accel:
		jmp .nvm

	.check_modes:
	xor ax, ax
	int 0x16

	cmp al, 0x1b
	jz .failure

	cmp al, 13
	jz .select_mode

	cmp al, 'w'
	jz .up_modes

	cmp al, 's'
	jnz .check_modes

	cmp di, word[ bp ]
	je .nvm


	sub di, 2

	.nvm:

		call show_mode

	jmp .check_modes

	.up_modes:
		cmp word[ di + 2 ], 0xFFFF
		jz .nvm

		add di, 2
		jmp .nvm

	.select_mode:
		mov bx, word[ di ]
		or bx, (1<<14)
		mov ax, 0x4F02
		int 0x10
		jc .failure

		cmp ax, 0x4F
		jne .failure

		mov dword[ MultibootStrucAddr + multiboot.vbe_mode_info ], 0x8000
		mov dword[ MultibootStrucAddr + multiboot.vbe_ctrl_info ], 0
		mov word[ MultibootStrucAddr + multiboot.vbe_mode ], 0x8A70

		test byte[ 0x7E0A ],8
		jz .failure

		mov ax, 0x4F0B
		xor bl, bl
		mov di, 0x9000
		int 0x10

		cmp ax, 0x4F
		jnz .failure

		mov word[ MultibootStrucAddr + multiboot.vbe_interface_len ], cx

		mov ax, 0x4F0B
		mov bl, 1
		mov di, 0x9000
		int 0x10

		cmp ax, 0x4F
		jnz .failure

		mov word[ MultibootStrucAddr + multiboot.vbe_interface_seg ], 0
		mov word[ MultibootStrucAddr + multiboot.vbe_interface_off ], 0x9000 
		mov word[ MultibootStrucAddr + multiboot.vbe_mode ], 0x8A71

	.failure:
		retf

	;edi points to the mode address
	show_mode:
		push di
		mov di, 160
		call clear_screen
		pop di

		mov cx, word[ di ]
		push di

		mov ax, 0x4F01
		mov di, 0x8000
		int 0x10
		pop di

		mov ax, 0x1000
		mov ds, ax

		mov word[ ScrOff-_end ], 160
		mov si, (ModeInfo-_end)
		call print_string

		mov ax, di
		sub ax, word[ es:bp ]
		shr ax, 1
		call print_int

		mov si, (ModeInfoExt-_end)
		call print_string

		mov ax, word[ es:0x8012 ]
		call print_int

		mov si, (ModeInfoExt2-_end)
		call print_string

		mov ax, word[ es:0x8014 ]
		call print_int

		mov si, (ModeInfoExt3-_end)
		call print_string

		movzx ax, byte[ es:0x8019 ]
		call print_int

		mov si, (ModeInfoExt4-_end)
		call print_string

		mov ax, word[ es:0x8010 ]
		call print_int

		xor ax, ax
		mov ds, ax
		ret



	; ax = number
	print_int:
		push dx
		push bx
		push ax
		push di

		sub sp, 25		; Buffer
		mov di, sp

		mov bx, 10
		xor cx, cx


		.Divide:
			xor dx, dx
			div bx

			add dl, 48
			mov di, sp
			add di, cx
			mov byte[ di ], dl
			add cx, 1

			or al, al
			jnz .Divide
			mov di, sp
			add di, cx
			mov byte[ di ], al

			mov si, sp
			sub di, 1
		.return_val:
			mov dl, byte[ si ]
			xchg dl, byte [ di ]
			mov byte[ si ], dl

			add si, 1
			sub di, 1
			cmp di, si
			jns .return_val

			mov si, sp
			call print_string

			add sp, 25
			pop di
			pop ax
			pop bx
			pop dx
			ret

	print_string:
		push ax
		push es
		mov ax, 0xb800
		push di
		mov es, ax
		mov di, word[ ScrOff-_end ]

		mov ah, 0x0F

		.prLoop:
			mov al, byte[ si ]
			or al, al
			jz .done

			mov word[ es:di ], ax
			add si, 1
			add di, 2
			jmp .prLoop
		.done:
			mov word[ ScrOff-_end ], di
			pop di
			pop es
			pop ax
			ret

	; di = start offset
	clear_screen:
		push ax
		push es
		mov ax, 0xb800
		push cx
		mov es, ax
		mov ax, 0x0F20

		mov cx, 4000
		sub cx, di
		shr cx, 1

		rep stosw

		pop cx
		pop es
		pop ax
		ret

ScrOff dw 0
AcellVideo db 'Accel video mode list v.1.0',0
StdVideo db 'Standard video mode list v2.0',0
ModeInfo db 'Mode Number: ',0
ModeInfoExt db ' X Resolution: ', 0
ModeInfoExt2 db ' Y Resolution: ', 0
ModeInfoExt3 db ' bit depth: ',0
ModeInfoExt4 db ' bytes ps: ', 0
BYTE_ACCEL db 0
times 1536-($-$$) hlt
