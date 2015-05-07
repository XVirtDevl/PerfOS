%define FLAGS 3
%define MAGIC 0x1BADB002
%define CHECKSUM -(MAGIC+FLAGS)
%include "video.inc"
%include "multiboot.inc"
%include "apic.inc"

section multiboot
align 4
my_magic dd MAGIC
dd FLAGS
dd CHECKSUM
extern kernel
%define GDT_BASE 0
[BITS 32]
section .text
global _start
_start:
	mov esp, 0x700000
	mov dword[ multibootstruc ], ebx
	mov eax, 0x80000001
	cpuid
	and edx, 0x20000000	;Check for the long mode support bit
	test edx, edx
	jz .fatal_error		;No long mode quit the OS
	mov eax, 1		;Check for the PAE-Bit ( Physical Address Extension)
	cpuid
	and edx, 0x40
	test edx, edx
	jz .fatal_error		;If not available quit OS

	xor eax, eax		;Set up new gdt to ensure transparence as well as enable 64 bit segment descriptors
	mov dword[ GDT_BASE + 0 ], eax
	mov dword[ GDT_BASE + 4 ], eax

	mov eax, 0xFFFF
	mov dword[ GDT_BASE + 8 ], eax
	mov dword[ GDT_BASE + 16 ], eax
	mov dword[ GDT_BASE + 24 ], eax
	mov dword[ GDT_BASE + 32 ], eax

	mov eax, 0x00CF9A00
	mov dword[ GDT_BASE + 12 ], eax		;Code Segment 32-bit offset: 0x8

	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 20 ], eax		;Data Segment 32-Bit offset: 0x10

	mov eax, 0x00AF9A00
	mov dword[ GDT_BASE + 28 ], eax		;Code Segment 64-bit offset: 0x18
	and eax, 0xFFFFF7FF
	mov dword[ GDT_BASE + 36 ], eax		;Data Segment 64-bit offset: 0x20

	lgdt[ gdt_limit ]
	jmp 0x8:_OwnGDT	

	.fatal_error:	
		mov eax, 0x0F200F20
		mov edi, 0xb8000
		mov ecx, 1000
		rep stosd 		;Clear screen with white foreground black background

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
			
		
align 8
	_OwnGDT:
		mov ax, 0x10
		mov ds, ax
		mov es, ax
		mov fs, ax
		mov gs, ax
		mov ss, ax
		
		mov eax, cr4
		or eax, 0x20
		mov cr4, eax	; Set PAE-Bit 

		call InitialisePaging
	
		mov ecx, 0xC0000080
		rdmsr
		or eax, 0x100	;Set Long Mode Bit
		wrmsr

		mov eax, cr0	
		or eax, 0x80000000	;Activate Paging
		mov cr0, eax

		jmp 0x18:LongMode

InitialisePaging:
		mov edi, 0x300000
		xor eax, eax
		mov ecx, 0x1000
		rep stosd
		mov edi, 0x300000


		mov eax, 0x30100F
		xor ebx, ebx
	
		mov dword[ edi ], eax
		mov dword[ edi + 4 ], ebx
		
		add edi, 0x1000
		add eax, 0x1000
		mov dword[ edi ], eax
		mov dword[ edi + 4 ], ebx

		add edi, 0x1000
		mov eax, 0x8B
		mov ecx, 512

		.Map:
			mov dword[ edi ], eax
			mov dword[ edi + 4 ], ebx
			add edi, 8
			add eax, 0x200000
			sub ecx, 1
			jnz .Map

		mov eax, 0x300000
		mov cr3, eax
		ret				;Identity Mapped First GB

align 8
[BITS 64]
LongMode:
	mov ax, 0x20
	mov ds, ax
	mov es, ax
	mov fs, ax
	mov ss, ax
	mov gs, ax

	call clearScreen
	
	mov esi, KernelLoadedMsg
	call printf

	mov esi, dword[ multibootstruc ]
	mov ecx, dword[ esi + multiboot.mmap_length ]
	mov edi, dword[ esi + multiboot.mmap_addr ]

	mov esi, headerMemMap
	call printf

	.Helper:
		mov eax, dword[ edi + 16 ]
		sub eax, 1
		shl eax, 2
		add eax, MemMapEntryList
		mov eax, dword[ eax ]
		push rax
		push qword[ edi + 8 ]
		push qword[ edi ]
		mov esi, MemMapEntry
		call printf
		add esp, 24

		add edi, 24
		sub ecx, 24
		jnz .Helper	

	mov edi, 0x400000
	call setIDTBase	
	
	call picRemapIRQ

	mov ecx, 32
	mov edi, timer_tick
	call setIDTGate

	call loadNewIDT

	call clearScreen
	sti
	jmp $

align 8
timer_tick:
	add dword[Ticks], 1
	call resetWritePtr

	mov esi, Exception
	push qword[ Ticks ]
	call printf
	add esp, 8

	mov al, 0x20
	out 0x20, al

	iretq

gdt_limit dw 40
gdt_base dd GDT_BASE
multibootstruc dq 0

Ticks dq 0
Exception db 'Timer ticks till now: %d',0
KernelLoadedMsg db 'The kernel was successfully loaded',0x13, 0
headerMemMap db 'Base address       | Length             | Type',0
MemMapEntry db 0x13,'%X | %X | %s',0

MemMapEntryUsable db 'Free Memory',0
MemMapEntryUsed db 'Reserved memory - unusable', 0
MemMapEntryACPI db 'ACPI Reclaimable memory',0
MemMapEntryNVS db 'ACPI NVS memory',0
MemMapEntryList dd MemMapEntryUsable, MemMapEntryUsed, MemMapEntryACPI, MemMapEntryNVS
NoLongModeMsg db 0x13,'Long mode %x isi %d not available the OS can not boot please restart the PC', 0
