%line 3+1 meta/debug.inc

%line 9+1 meta/debug.inc

%line 15+1 meta/debug.inc

%line 19+1 meta/debug.inc

%line 23+1 meta/debug.inc

%line 35+1 meta/debug.inc


%line 42+1 meta/debug.inc

%line 46+1 meta/debug.inc

%line 52+1 meta/debug.inc

%line 2+1 console.inc


%line 6+1 console.inc

%line 3+1 meta/metaprogramming.inc

%line 11+1 meta/metaprogramming.inc

%line 17+1 meta/metaprogramming.inc




%line 28+1 meta/metaprogramming.inc

%line 34+1 meta/metaprogramming.inc


%line 43+1 meta/metaprogramming.inc





%line 156+1 meta/metaprogramming.inc



%line 273+1 meta/metaprogramming.inc

%line 8+1 console.inc



[extern Console@64_PolymorphicList]
%line 15+1 console.inc

%line 28+1 console.inc

[extern SetAutoscroll]
%line 47+1 console.inc

[extern SetScreenDimensions]
%line 64+1 console.inc

[extern SetTextAttributes]
%line 78+1 console.inc

[extern SetBufferedOutputBuffer]
%line 93+1 console.inc


[extern SetBufferedOutputFlags]
%line 109+1 console.inc

%line 120+1 console.inc


[extern ConvertNumberToHexStr32]
%line 135+1 console.inc

[extern ConvertNumberToHexStr64]
%line 149+1 console.inc

%line 168+1 console.inc

[extern ClearScreen]
%line 181+1 console.inc





%line 202+1 console.inc



%line 208+1 console.inc

%line 211+1 console.inc




%line 1+1 multiboot.inc
[absolute 0]
%line 1+0 multiboot.inc
multiboot:
%line 2+1 multiboot.inc
 .flags resd 1
 .mem_lower resd 1
 .mem_upper resd 1
 .bootdevice resd 1
 .commandline resd 1
 .mod_count resd 1
 .mod_addr resd 1
 .sys resd 4
 .mmap_length resd 1
 .mmap_addr resd 1
 .drives_length resd 1
 .drives_addr resd 1
 .config_table resd 1
 .bootloader_name resd 1
 .apm_table resd 1
 .vbe_ctrl_info resd 1
 .vbe_mode_info resd 1
 .vbe_mode resw 1
 .vbe_interface_seg resw 1
 .vbe_interface_off resw 1
 .vbe_interface_len resw 1
multiboot_size equ ($-multiboot)
%line 23+0 multiboot.inc
[section .text]
%line 24+1 multiboot.inc


%line 3+1 graphic.inc

%line 3+1 StdDriverList.inc

%line 6+1 StdDriverList.inc
[extern RegisteredDrivers]


[absolute 0]
%line 9+0 StdDriverList.inc
RegisteredDriversStruct:
%line 10+1 StdDriverList.inc
 .graphic resq 1
RegisteredDriversStruct_size equ ($-RegisteredDriversStruct)
%line 11+0 StdDriverList.inc
[section .text]
%line 12+1 StdDriverList.inc


%line 5+1 graphic.inc

[absolute 0]
%line 6+0 graphic.inc
GraphicFunctionality:
%line 7+1 graphic.inc
 .getXResolutionInPixel resq 1
 .getYResolutionInPixel resq 1
 .getXResolutionInChars resq 1
 .getYResolutionInChars resq 1
GraphicFunctionality_size equ ($-GraphicFunctionality)
%line 11+0 graphic.inc
[section .text]
%line 12+1 graphic.inc

%line 17+1 graphic.inc


%line 21+1 graphic.inc
[extern InitialiseVBEDriver]
[extern SetVBEDriverAsGraphicDriver]
[extern DrawChar]


%line 28+1 graphic.inc
[extern InitialiseVGADriver]
[extern Font8X8BIOS]





%line 3+1 meta/stack.inc


%line 22+1 meta/stack.inc

%line 26+1 meta/stack.inc

%line 30+1 meta/stack.inc

%line 38+1 meta/stack.inc

%line 45+1 meta/stack.inc

%line 52+1 meta/stack.inc




%line 59+1 meta/stack.inc

%line 112+1 meta/stack.inc


%line 117+1 meta/stack.inc

%line 121+1 meta/stack.inc

%line 125+1 meta/stack.inc

%line 139+1 meta/stack.inc


%line 185+1 meta/stack.inc

%line 212+1 meta/stack.inc

%line 225+1 meta/stack.inc

%line 233+1 meta/stack.inc

%line 247+1 meta/stack.inc

%line 263+1 meta/stack.inc

%line 270+1 meta/stack.inc

%line 8+1 ./kernel/kernel.asm

[section multiboot]
[sectalign 4]
%line 10+0 ./kernel/kernel.asm
times (((4) - (($-$$) % (4))) % (4)) nop
%line 11+1 ./kernel/kernel.asm
my_magic dd 0x1BADB002
dd 3
dd -(0x1BADB002+3)
%line 18+1 ./kernel/kernel.asm
[extern kernel_start]
[extern kernel_end]



[BITS 32]
[section .text]
[global _start]
_start:
 mov esp, 0x400000

 cmp ebx, 0x500
 jz .RelocateDone

 mov esi, ebx
 mov edi, 0x500
 mov ecx, 22
 rep movsd

 .RelocateDone:
 mov esi, dword[ 0x500 + multiboot.mmap_addr ]

 mov dword[ 0x500 + multiboot.mmap_addr ], 0x600

 or esi, esi
 jz .RemoveMmapDone

 mov ecx, dword[ 0x500 + multiboot.mmap_length ]
 mov edi, 0x600
 rep movsb

 .RemoveMmapDone:

 mov eax, 0x80000001
 cpuid
 and edx, 0x20000000
 test edx, edx
 jz .fatal_error
 mov eax, 1
 cpuid
 and edx, 0x40
 test edx, edx
 jz .fatal_error

 xor eax, eax

 mov word[ 0x1500 ], 40
 mov dword[ 0x1502 ], 0x800
 mov dword[ 0x800 + 0 ], eax
 mov dword[ 0x800 + 4 ], eax

 mov eax, 0xFFFF
 mov dword[ 0x800 + 8 ], eax
 mov dword[ 0x800 + 16 ], eax
 mov dword[ 0x800 + 24 ], eax
 mov dword[ 0x800 + 32 ], eax

 mov eax, 0x00CF9A00
 mov dword[ 0x800 + 12 ], eax

 and eax, 0xFFFFF7FF
 mov dword[ 0x800 + 20 ], eax

 mov eax, 0x00AF9A00
 mov dword[ 0x800 + 28 ], eax
 and eax, 0xFFFFF7FF
 mov dword[ 0x800 + 36 ], eax

 lgdt[ 0x1500 ]
 jmp 0x8:_OwnGDT

 .fatal_error:
 mov eax, 0x0F200F20
 mov edi, 0xb8000
 mov ecx, 1000
 rep stosd

 mov ah, 0x04
 mov edi, 0xb8000
 mov esi, NoLongModeMsg

 .print:
 mov al, byte[ esi ]

 or al, al
 jz .done

 mov word[ edi ], ax
 add edi, 2
 add esi, 1
 jmp .print
 .done:
 jmp $


[sectalign 8]
%line 113+0 ./kernel/kernel.asm
times (((8) - (($-$$) % (8))) % (8)) nop
%line 114+1 ./kernel/kernel.asm
 _OwnGDT:
 mov ax, 0x10
 mov ds, ax
 mov es, ax
 mov fs, ax
 mov gs, ax
 mov ss, ax

 mov eax, cr4
 or eax, 0x20
 mov cr4, eax

 call InitialisePaging

 mov ecx, 0xC0000080
 rdmsr
 or eax, 0x100
 wrmsr

 mov eax, cr0
 or eax, 0x80000000
 mov cr0, eax

 jmp 0x18:LongMode


InitialisePaging:
 mov edi, 0x300000
 xor eax, eax
 mov ecx, 0x2000
 rep stosd

 mov edi, 0x300000


 mov eax, 0x300000 + 0x100F
 xor ebx, ebx

 mov dword[ edi ], eax
 mov dword[ edi + 4 ], ebx

 mov ecx, 32
 add edi, 0x1000
 push edi
 .MapAll:
 add eax, 0x1000
 mov dword[ edi ], eax
 mov dword[ edi + 4 ], ebx
 add edi, 8

 sub ecx, 1
 jnz .MapAll

 pop edi
 add edi, 0x1000
 mov eax, 0x8B
 mov ecx, 32*512


 .Map:
 mov dword[ edi ], eax
 mov dword[ edi + 4 ], ebx
 add edi, 8
 add eax, 0x200000
 adc ebx, 0
 sub ecx, 1
 jnz .Map

 mov eax, 0x300000
 mov cr3, eax
 ret

[absolute 0]
%line 186+0 ./kernel/kernel.asm
MyShit:
%line 187+1 ./kernel/kernel.asm
 .hello resq 1
 .string resq 1
 .length resq 1
MyShit_size equ ($-MyShit)
%line 190+0 ./kernel/kernel.asm
[section .text]
%line 191+1 ./kernel/kernel.asm

%line 198+1 ./kernel/kernel.asm


[sectalign 8]
%line 200+0 ./kernel/kernel.asm
times (((8) - (($-$$) % (8))) % (8)) nop
%line 201+1 ./kernel/kernel.asm
[BITS 64]
LongMode:
 mov ax, 0x20
 mov ds, ax
 mov es, ax
 mov fs, ax
 mov ss, ax
 mov gs, ax

 push rbp
%line 210+0 ./kernel/kernel.asm
 mov rbp, rsp

%line 211+1 ./kernel/kernel.asm




 sub rsp, (((0 + MyShit_size) + MyShit_size)-0)
%line 215+0 ./kernel/kernel.asm
























































































































 mov qword[rbp - ((0 + MyShit_size)) + (MyShit.length)], rax
%line 216+1 ./kernel/kernel.asm


 mov rsp, rbp
%line 218+0 ./kernel/kernel.asm
 pop rbp
%line 219+1 ./kernel/kernel.asm


 mov edi, 0x8000
 call InitialiseVBEDriver

 mov eax, 'C'
 call DrawChar

 jmp $

 mov ah, (0<<4|15)
%line 229+0 ./kernel/kernel.asm



 call SetTextAttributes
%line 230+1 ./kernel/kernel.asm


%line 231+0 ./kernel/kernel.asm


 call ClearScreen
%line 232+1 ./kernel/kernel.asm

 mov rdi, 0x700000
%line 233+0 ./kernel/kernel.asm
 mov rcx, 0x2000



 call SetBufferedOutputBuffer
%line 234+1 ./kernel/kernel.asm


%line 235+0 ./kernel/kernel.asm
 mov eax, (1<<0)|(1<<1)



 call SetBufferedOutputFlags
%line 236+1 ./kernel/kernel.asm

 .printLoop:
 mov ebx, 0x10000000

 .okay:
 sub ebx, 1
 jnz .okay

 mov rsi, TestSentence
%line 244+0 ./kernel/kernel.asm


 push qword[ Dr ]
 call qword[ Console@64_PolymorphicList + 16 ]
 add esp, (2-1)*8
%line 245+1 ./kernel/kernel.asm
 add dword[ Dr ], 1

 cmp dword[ Dr ], 51
 jz .done


%line 250+0 ./kernel/kernel.asm

 call qword[ Console@64_PolymorphicList + 8 ]

%line 251+1 ./kernel/kernel.asm
 jmp .printLoop

 .done:
 mov eax, -10
%line 254+0 ./kernel/kernel.asm



 call qword[ Console@64_PolymorphicList + 0 ]

%line 255+1 ./kernel/kernel.asm

%line 255+0 ./kernel/kernel.asm

 call qword[ Console@64_PolymorphicList + 8 ]

%line 256+1 ./kernel/kernel.asm
 jmp $

Dr dq 0
TestSentence db 'Hello World turn %d', 0x0A, 0
NoLongModeMsg db 'Long mode %x isi %d not available the OS can not boot please restart the PC', 0
%line 2+1 elf64.inc

[absolute 0]
%line 3+0 elf64.inc
elf64header:
%line 4+1 elf64.inc
 .imagic0 resb 1
 .imagicELF resb 3
 .iclass resb 1
 .idata resb 1
 .iversion resb 1
 .iosabi resb 1
 .iabiversion resb 1
 .padding resb 7

 .object_type resw 1
 .machine_type resw 1
 .version resd 1
 .entry_point resq 1
 .programmheader_offset resq 1
 .sectionheader_offset resq 1
 .processor_flags resd 1
 .programmheader_size resw 1
 .programmheader_num resw 1
 .sectionheader_size resw 1
 .sectionheader_num resw 1
 .sectionnamestringtableindex resw 1
elf64header_size equ ($-elf64header)
%line 25+0 elf64.inc
[section .text]
%line 26+1 elf64.inc

[absolute 0]
%line 27+0 elf64.inc
programmheader:
%line 28+1 elf64.inc
 .type resd 1
 .flags resd 1
 .offsetinfile resq 1
 .vaddr resq 1
 .paddr resq 1
 .sizeofsegmentinfile resq 1
 .sizeofsegmentinmem resq 1
 .alignment resq 1
programmheader_size equ ($-programmheader)
%line 36+0 elf64.inc
[section .text]
%line 37+1 elf64.inc

%line 1+1 multiboot.inc
[absolute 0]
%line 1+0 multiboot.inc
multiboot:
%line 2+1 multiboot.inc
 .flags resd 1
 .mem_lower resd 1
 .mem_upper resd 1
 .bootdevice resd 1
 .commandline resd 1
 .mod_count resd 1
 .mod_addr resd 1
 .sys resd 4
 .mmap_length resd 1
 .mmap_addr resd 1
 .drives_length resd 1
 .drives_addr resd 1
 .config_table resd 1
 .bootloader_name resd 1
 .apm_table resd 1
 .vbe_ctrl_info resd 1
 .vbe_mode_info resd 1
 .vbe_mode resw 1
 .vbe_interface_seg resw 1
 .vbe_interface_off resw 1
 .vbe_interface_len resw 1
multiboot_size equ ($-multiboot)
%line 23+0 multiboot.inc
[section .text]
%line 24+1 multiboot.inc


%line 5+1 ./boot/mbr.asm
[org 0x7C00]
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

mov dword[ 0x500 + multiboot.flags ], 64
mov dword[ 0x500 + multiboot.mmap_addr ], 0x2004

mov eax, 0xE820
mov edx, 0x534D4150
xor ebx, ebx
mov ecx, 24
mov di, 0x2004+4
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
 sub di, 0x2004
 mov word[ 0x500 + multiboot.mmap_length ], di

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



[BITS 32]
ProtectedMode:
 mov ax, 0x10
 mov ds, ax
 mov es, ax
 mov fs, ax
 mov gs, ax
 mov ss, ax
 mov esp, 0x300000

 mov ebx, 0x10000+(2*512)
 cmp dword[ ebx ], ('ELF'<<8)|0x7F
 jnz .no_elf

 mov dx, word[ ebx + elf64header.programmheader_num ]
 add ebx, dword[ ebx + elf64header.programmheader_offset ]


 .loadAll:
 mov esi, dword[ ebx + programmheader.offsetinfile ]
 mov ecx, dword[ ebx + programmheader.sizeofsegmentinfile ]
 add esi, 0x10000+(2*512)
 mov edi, dword[ ebx + programmheader.paddr ]

 push ecx
 shr ecx, 2

 rep movsd

 pop ecx
 and ecx, 0x3
 rep movsb

 add ebx, 56
 sub dx, 1
 jnz .loadAll


 mov eax, dword[ 0x10000+(2*512) + elf64header.entry_point ]
 push eax
 mov ebx, 0x500
 ret

 .no_elf:
 mov eax, 0xAF9

 jmp $



BOOTDRIVE db 0
[sectalign 8]
%line 167+0 ./boot/mbr.asm
times (((8) - (($-$$) % (8))) % (8)) nop
%line 168+1 ./boot/mbr.asm
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

 mov dword[ 0x500 + multiboot.vbe_mode_info ], 0x8000
 mov dword[ 0x500 + multiboot.vbe_ctrl_info ], 0
 mov word[ 0x500 + multiboot.vbe_mode ], 0x8A70

 test byte[ 0x7E0A ],8
 jz .failure

 mov ax, 0x4F0B
 xor bl, bl
 mov di, 0x9000
 int 0x10

 cmp ax, 0x4F
 jnz .failure

 mov word[ 0x500 + multiboot.vbe_interface_len ], cx

 mov ax, 0x4F0B
 mov bl, 1
 mov di, 0x9000
 int 0x10

 cmp ax, 0x4F
 jnz .failure

 mov word[ 0x500 + multiboot.vbe_interface_seg ], 0
 mov word[ 0x500 + multiboot.vbe_interface_off ], 0x9000
 mov word[ 0x500 + multiboot.vbe_mode ], 0x8A71

 .failure:
 retf


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




 print_int:
 push dx
 push bx
 push ax
 push di

 sub sp, 25
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
%line 3+1 meta/metaprogramming.inc

%line 11+1 meta/metaprogramming.inc

%line 17+1 meta/metaprogramming.inc




%line 28+1 meta/metaprogramming.inc

%line 34+1 meta/metaprogramming.inc


%line 43+1 meta/metaprogramming.inc





%line 156+1 meta/metaprogramming.inc



%line 273+1 meta/metaprogramming.inc

%line 2+1 ./kernel/console/console.asm

%line 3+1 meta/debug.inc

%line 9+1 meta/debug.inc

%line 15+1 meta/debug.inc

%line 19+1 meta/debug.inc

%line 23+1 meta/debug.inc

%line 35+1 meta/debug.inc


%line 42+1 meta/debug.inc

%line 46+1 meta/debug.inc

%line 52+1 meta/debug.inc

%line 2+1 console.inc


%line 184+1 console.inc


%line 202+1 console.inc



%line 208+1 console.inc

%line 211+1 console.inc




%line 3+1 ./kernel/console/console.asm


[global Console@64_PolymorphicList]
Console@64_PolymorphicList:
 .scroll_screen dq ScrollScreen
 .update_screen dq UpdateScreen
 .printf dq printf


[global ClearScreen]

ClearScreen:
 push rdi
 push rax
 push rcx


 mov rdi, qword[ ScreenDimension.base_address ]
 mov rcx, qword[ ScreenDimension.screen_size_shift8 ]
 mov rax, qword[ ScreenClearFixValue ]
 mov qword[ ScreenDimension.writeTo_address ], rdi


%line 25+0 ./kernel/console/console.asm
 rep stosq

%line 26+1 ./kernel/console/console.asm


 pop rcx
 pop rax
 pop rdi

 ret


ScrollScreen:
 cmp eax, dword[ ScreenDimension.y_resolution ]
 jns ClearScreen

 push rbx

 mov ebx, dword[ ScreenDimension.bytes_per_line ]


 push rcx
 push rsi
 push rdi

 mov rsi, qword[ ScreenDimension.base_address ]
 mov ecx, dword[ ScreenDimension.screen_size ]
 mov rdi, rsi

 mul ebx

 add rsi, rax
 sub rcx, rax


%line 57+0 ./kernel/console/console.asm

 test cx, 0x7
 jz ..@4.shf84

 push rcx
 mov ecx, dword[ rsi ]
 mov dword[ rdi ], ecx
 add rdi, 4
 add rsi, 4
 pop rcx

 ..@4.shf84:
 shr rcx, 3
 rep movsq

%line 58+1 ./kernel/console/console.asm

 mov qword[ ScreenDimension.writeTo_address ], rdi

 mov ecx, eax
 mov rax, qword[ ScreenClearFixValue ]


%line 64+0 ./kernel/console/console.asm
 test cx, 0x7
 jz ..@5.shf84

 mov dword[ rdi ], eax
 add rdi, 4

 ..@5.shf84:
 shr rcx, 3
 rep stosq

%line 65+1 ./kernel/console/console.asm

 pop rdi
 pop rsi
 pop rcx
 pop rbx

 ret


ScrollBufferBase:
 push rcx
 push rdi
 test eax, 0x80000000
 jnz .scrolling_up

 xor ecx, ecx

 .backup:
 cmp eax, dword[ BufferedOutputDesc.remembered_lines ]
 jns .clear_buffer

 push rbx

 mov ebx, dword[ ScreenDimension.bytes_per_line ]

 xor edx, edx
 mul ebx

 pop rbx

 or ecx, ecx
 jnz .scroll_up


 mov rdi, qword[ BufferedOutputDesc.base_address ]
 mov rcx, qword[ BufferedOutputDesc.readFrom_address ]
 add rdi, qword[ BufferedOutputDesc.length ]
 add rcx, rax

 cmp rcx, rdi
 js .endfunc

 sub rcx, rdi
 add rcx, qword[ BufferedOutputDesc.base_address ]
 jmp .endfunc

 .scroll_up:
 mov rcx, qword[ BufferedOutputDesc.readFrom_address ]
 sub rcx, rax

 cmp rcx, qword[ BufferedOutputDesc.base_address ]
 jns .endfunc

 .flip_over:
 add rcx, qword[ BufferedOutputDesc.length ]

 jmp .endfunc

 .clear_buffer:
 mov rdi, qword[ BufferedOutputDesc.base_address ]
 push rdi
%line 125+0 ./kernel/console/console.asm
 push rax
 push rcx
 mov rcx, qword[ ScreenDimension.screen_size_shift8 ]
 mov rax, qword[ ScreenClearFixValue ]

 rep stosq

 pop rcx
 pop rax
 pop rdi
%line 126+1 ./kernel/console/console.asm
 mov rcx, rdi
 mov qword[ BufferedOutputDesc.writeTo_address ], rdi

 .endfunc:
 mov qword[ BufferedOutputDesc.readFrom_address ], rcx
 pop rdi
 pop rcx
 ret

 .scrolling_up:
 not eax
 mov ecx, 1
 add eax, 1
 jmp .backup



[global ConvertNumberToDecStr64]
ConvertNumberToDecStr64:

 push rbx
 push rdx

 add rdi, 26
 mov ebx, 10

 mov byte[ rdi ], 0

 .prLoop:
 xor edx, edx
 div rbx
 sub rdi, 1
 add dl, 48
 mov byte[ rdi ], dl

 or eax, eax
 jnz .prLoop

 pop rdx
 pop rbx
 ret

[global ConvertNumberToHexStr32]

ConvertNumberToHexStr32:
 push rcx
 mov ecx, 32
 add rdi, 10
 jmp ConvertNumberToHexStr64.startConv

[global ConvertNumberToHexStr32]

ConvertNumberToHexStr64:
 push rcx
 mov ecx, 64
 add rdi, 18

 .startConv:
 mov byte[ rdi ], 0
 sub rdi, 1


 .prLoop:
 push rax
 and al, 0x0F

 cmp al, 0xA
 jns .hexTime

 add al, 48

 .push:
 mov byte[ rdi ], al
 sub rdi, 1
 pop rax
 shr rax, 4

 sub ecx, 4
 jnz .prLoop

 pop rcx

 sub rdi, 1
 mov word[ rdi ], '0x'
 ret

 .hexTime:
 add al, 55
 jmp .push



[global printf]

printf:
 mov rbp, rsp
 test byte[ BufferedOutputDesc.flags ], (1<<0)
 jnz .prepare_output_stage

 push rdi
 mov rdi, qword[ ScreenDimension.base_address ]
 push rcx
 mov rcx, qword[ ScreenDimension.screen_size ]
 push rdi
 push rax
 push rdx
 xor edx, edx

 add rcx, rdi

 push rbx


 mov rdi, qword[ ScreenDimension.writeTo_address ]

 mov ah, byte[ TextAttributes ]

 .printLoop:
 mov al, byte[ rsi ]
 add rsi, 1

 or al, al
 jz .done

 cmp al, 0x0A
 jz .newline

 cmp al, 0x17
 jz .selectNewColor

 cmp al, '%'
 jz .printFormatted

 mov word[ rdi ], ax
 add rdi, 2

 cmp rcx, rdi
 ja .printLoop
 jmp .overflow

 .printFormatted:
 mov al, byte[ rsi ]
 add rsi, 1
 add edx, 8

 cmp al, 'X'
 jz .ConvertNumberToHexStr

 cmp al, 's'
 jz .printSubStr

 cmp al, 'd'
 jz .printDecStr

 cmp al, 'D'
 jz .printDecStr

 jmp .printLoop

 .printDecStr:
 sub rsp, 30
 mov rax, qword[ rbp + rdx ]
 mov rbx, rdi
 mov rdi, rsp


 call ConvertNumberToDecStr64

 push rsi
 mov rsi, rdi

 mov ah, byte[ TextAttributes ]

 mov rdi, rbx

 call .prNumber

 pop rsi
 add rsp, 30
 jmp .printLoop

 .printSubStr:
 push rsi
 mov rsi, qword[ rbp + rdx ]

 call .prNumber

 pop rsi
 jmp .printLoop

 .ConvertNumberToHexStr:
 sub rsp, 24
 mov rax, rdi
 mov rdi, rsp


 push rsi
 push rax
 mov rax, qword[ rbp + rdx ]
 call ConvertNumberToHexStr64
 mov rsi, rdi
 pop rdi
 mov ah, byte[ TextAttributes ]

 call .prNumber
 pop rsi
 add rsp, 24
 jmp .printLoop

 .prNumber:
 mov al, byte[ rsi ]
 add rsi, 1

 or al, al
 jz .retToCallee

 mov word[ rdi ], ax
 add rdi, 2
 jmp .prNumber

 .retToCallee:
 ret

 .newline:
 mov rax, rdi
 sub rax, qword[ ebp - 24 ]
 mov ebx, dword[ ScreenDimension.bytes_per_line ]

 push rdx
 add rdi, rbx
 xor edx, edx
 div ebx

 sub rdi, rdx
 pop rdx

 mov ah, byte[ TextAttributes ]

 cmp rcx, rdi
 ja .printLoop
 jmp .overflow

 .selectNewColor:
 mov ah, byte[ rsi ]
 add rsi, 1

 or ah, ah
 jz .done


 call SetTextAttributes

 jmp .printLoop





 .overflow:
 test byte[ BufferedOutputDesc.flags ], (1<<0)
 jnz .handleBufferedOverflow


 push rsi
 push rcx

 mov ebx, dword[ ScreenDimension.bytes_per_line ]

 mov ecx, dword[ ScreenDimension.screen_size ]
 mov rsi, qword[ ScreenDimension.base_address ]
 sub ecx, ebx
 mov rdi, rsi
 shr ecx, 3
 add rsi, rbx


 rep movsq

 mov ecx, ebx
 push rdi
 push rax
 shr ecx, 3
 mov rax, qword[ ScreenClearFixValue ]
 rep stosq
 pop rax
 pop rdi

 pop rcx
 pop rsi
 jmp .printLoop

 .handleBufferedOverflow:
 mov rdi, qword[ BufferedOutputDesc.base_address ]
 push rdi
 push rcx
 push rax
 mov ecx, dword[ ScreenDimension.screen_size_shift8 ]
 mov rax, qword[ ScreenClearFixValue ]
 rep stosq
 pop rax
 pop rcx
 pop rdi
 jmp .printLoop

 .done:
 test byte[ BufferedOutputDesc.flags ], (1<<0)
 jnz .update_writeToBuf

 mov qword[ ScreenDimension.writeTo_address ], rdi

 jmp .restore_regs

 .update_writeToBuf:
 mov qword[ BufferedOutputDesc.writeTo_address ], rdi

 cmp dword[ AutoscrollBehave ], 0
 jnz .restore_regs

 mov rax, rdi
 mov ebx, dword[ ScreenDimension.bytes_per_line ]
 sub rax, qword[ BufferedOutputDesc.base_address ]

 add rdi, rbx

 xor edx, edx

 div ebx

 sub rdi, rdx

 cmp rdi, rcx
 jns .QuitClear

 push rdi

 mov rax, qword[ ScreenClearFixValue ]
 mov ecx, ebx
 shr ecx, 3

 rep stosq

 pop rdi

 .QuitClear:

 cmp rdi, qword[ BufferedOutputDesc.readFrom_address ]
 js .rare_flipovercase

 sub rdi, qword[ BufferedOutputDesc.readFrom_address ]

 sub rdi, qword[ ScreenDimension.screen_size ]
 js .restore_regs

 add qword[ BufferedOutputDesc.readFrom_address ], rdi
 jmp .restore_regs

 .rare_flipovercase:
 sub rdi, qword[ BufferedOutputDesc.base_address ]

 sub rdi, qword[ ScreenDimension.screen_size ]
 js .double_flip

 add rdi, qword[ BufferedOutputDesc.base_address ]

 mov qword[ BufferedOutputDesc.readFrom_address ], rdi
 jmp .restore_regs

 .double_flip:
 add rdi, qword[ BufferedOutputDesc.base_address ]
 add rdi, qword[ BufferedOutputDesc.length ]

 mov qword[ BufferedOutputDesc.readFrom_address ], rdi

 .restore_regs:
 pop rdx
 pop rbx
 pop rax
 pop rdi
 pop rcx
 pop rdi
 ret

 .prepare_output_stage:
 push rdi
 push rcx
 mov rdi, qword[ BufferedOutputDesc.base_address ]
 push rdi
 mov rcx, qword[ BufferedOutputDesc.length ]
 add rcx, rdi
 mov rdi, qword[ BufferedOutputDesc.writeTo_address ]
 mov ah, byte[ TextAttributes ]
 push rax
 push rbx
 push rdx
 jmp .printLoop

[global SetAutoscroll]

SetAutoscroll:
 mov dword[ AutoscrollBehave ], eax
 ret

[global SetBufferedOutputBuffer]


SetBufferedOutputBuffer:
 cmp dword[ BufferedOutputDesc.length ], 0
 jnz .possible_fault

 push qword 0


 .update_description:

 mov qword[ BufferedOutputDesc.base_address ], rdi
 mov qword[ BufferedOutputDesc.writeTo_address ], rdi
 mov qword[ BufferedOutputDesc.readFrom_address ], rdi
 mov dword[ BufferedOutputDesc.real_length ], ecx

 push rdx

 mov rdi, rbx

 xor rdx, rdx
 mov eax, ecx

 mov ebx, dword[ ScreenDimension.bytes_per_line ]

 div ebx


 mov dword[ BufferedOutputDesc.remembered_lines ], eax

 xor edx, edx
 mul ebx
 mov dword[ BufferedOutputDesc.length ], eax


 mov rbx, rdi
 pop rdx
 pop rax

 ret

 .possible_fault:
 push qword 1
 jmp .update_description

[global SetScreenDimensions]

SetScreenDimensions:
 mov qword[ ScreenDimension.base_address ], rax
 mov byte[ ScreenDimension.x_resolution ], bl
 mov byte[ ScreenDimension.y_resolution ], bh
 xor bh, bh
 shl bx, 1
 mov word[ ScreenDimension.bytes_per_line ], bx

 mov dword[ ScreenDimension.screen_size ], ecx
 shr ecx, 3
 mov dword[ ScreenDimension.screen_size_shift8 ], ecx

 push rdx
 mov eax, dword[ BufferedOutputDesc.real_length ]
 mov ebx, dword[ ScreenDimension.bytes_per_line ]
 xor edx, edx
 div ebx
 pop rdx

 mov dword[ BufferedOutputDesc.remembered_lines ], eax

 xor edx, edx
 mul ebx
 mov dword[ BufferedOutputDesc.length ], eax

 ret



UpdateScreen:
 ret


UpdateBufferedScreen:



 push rsi
 push rdi
 mov rsi, qword[ BufferedOutputDesc.readFrom_address ]
 mov rdi, qword[ BufferedOutputDesc.base_address ]
 add rsi, qword[ ScreenDimension.screen_size ]
 add rdi, qword[ BufferedOutputDesc.length ]

 cmp rdi, rsi
 js .several_memcpy

 pop rdi
 pop rsi
 push rdi
%line 625+0 ./kernel/console/console.asm
 push rsi
 push rcx
 mov rdi, qword[ ScreenDimension.base_address ]
 mov rcx, qword[ ScreenDimension.screen_size ]
 mov rsi, qword[ BufferedOutputDesc.readFrom_address ]

 test cx, 0x7
 jz ..@14.shf8


 and rcx, 0x7
 rep movsb

 pop rcx

 push rcx

 and ecx, 0xFFFFFFF8

 ..@14.shf8:
 shr rcx, 3
 rep movsq


 pop rcx
 pop rsi
 pop rdi
%line 626+1 ./kernel/console/console.asm

 ret

 .several_memcpy:

 sub rdi, qword[ BufferedOutputDesc.readFrom_address ]
 mov rax, qword[ ScreenDimension.base_address ]
 push rax
 push rbx
 push rcx

 mov rcx, rdi
 add rax, rdi


 push rcx
%line 641+0 ./kernel/console/console.asm
 mov rdi, qword[ ScreenDimension.base_address ]
 mov rsi, qword[ BufferedOutputDesc.readFrom_address ]

 test cx, 0x7
 jz ..@15.shf8


 and rcx, 0x7
 rep movsb

 pop rcx

 push rcx

 and ecx, 0xFFFFFFF8

 ..@15.shf8:
 shr rcx, 3
 rep movsq


 pop rcx
%line 642+1 ./kernel/console/console.asm

 mov ebx, dword[ ScreenDimension.screen_size ]
 sub ebx, ecx


 mov ecx, ebx

 mov rdi, rax
%line 649+0 ./kernel/console/console.asm
 mov rsi, qword[ BufferedOutputDesc.base_address ]

 test cx, 0x7
 jz ..@16.shf8

 push rcx

 and rcx, 0x7
 rep movsb

 pop rcx


 and ecx, 0xFFFFFFF8

 ..@16.shf8:
 shr rcx, 3
 rep movsq


%line 650+1 ./kernel/console/console.asm
 pop rcx
 pop rbx
 pop rax
 pop rdi
 pop rsi
 .done:
 ret

[global SetTextAttributes]

SetTextAttributes:
 push rcx
 mov byte[ TextAttributes ], ah
 mov al, 0x20

%line 669+1 ./kernel/console/console.asm

 mov cx, ax
%line 670+0 ./kernel/console/console.asm
 shl rcx, 16
 mov cx, ax
 shl rcx, 16
 mov cx, ax
 shl rcx, 16
%line 671+1 ./kernel/console/console.asm
 mov cx, ax
 mov qword[ ScreenClearFixValue ], rcx

 pop rcx
 ret

[global SetBufferedOutputFlags]

SetBufferedOutputFlags:
 test eax, (1<<0)
 jnz .handle_buffered_output

 mov qword[ Console@64_PolymorphicList.scroll_screen ], ScrollScreen
 mov qword[ Console@64_PolymorphicList.printf ], printf
 mov qword[ Console@64_PolymorphicList.update_screen ], UpdateScreen

 .done_prepare:
 mov dword[ BufferedOutputDesc.flags ], eax
 ret

 .handle_buffered_output:
 cmp qword[ BufferedOutputDesc.base_address ], 0
 jz .err_no_base

 test eax, (1<<1)
 jz .special_buffered_output

 mov qword[ Console@64_PolymorphicList.scroll_screen ], ScrollBufferBase
 mov qword[ Console@64_PolymorphicList.printf ], printf
 mov qword[ Console@64_PolymorphicList.update_screen ], UpdateBufferedScreen

 jmp .done_prepare


 .special_buffered_output:
 mov qword[ Console@64_PolymorphicList.scroll_screen ], ScrollScreen
 mov qword[ Console@64_PolymorphicList.printf ], ScrollScreen
 mov qword[ Console@64_PolymorphicList.update_screen ], ScrollScreen

 jmp .done_prepare

 .err_no_base:
 mov eax, 1
 ret



ScreenDimension:
 .x_resolution dd 80
 .y_resolution dd 25
 .screen_size dq 80*25*2
 .screen_size_shift8 dq (10)*25*2
 .base_address dq 0xb8000
 .writeTo_address dq 0xb8000
 .bytes_per_line dq 80*2

TextAttributes dd (0<<4|15)
AutoscrollBehave dd 0


ScreenClearFixValue dq ((0<<4|15)<<56)|(0x20<<48)|((0<<4|15)<<40)|(0x20<<32)|((0<<4|15)<<24)|(0x20<<16)|((0<<4|15)<<8)|0x20


BufferedOutputDesc:
 .flags dd 0
 .base_address dq 0
 .writeTo_address dq 0
 .readFrom_address dq 0
 .remembered_lines dd 0
 .length dq 0
 .real_length dq 0
